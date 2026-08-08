package FLOOD_Accelerator.utils

import java.io.{File, FileNotFoundException, PrintWriter}
import java.nio.file.{Paths, Files}
import scala.io.Source
import scala.collection.mutable.ArrayBuffer
import FLOOD_Accelerator.core.Config

/**
 * DataConverter - 数据格式转换工具
 * 
 * 主要功能：
 * 1. 权重数据转换: CSV -> SRAM格式
 * 2. 特征图数据转换: CSV -> SRAM格式
 * 3. 结果数据输出: SRAM格式 -> CSV
 * 4. 数据合并和拼接
 * 
 * 重要更新：
 * featureMapBus现在更新tile的一个列（featureMapBlock的一组通道）
 * - 原来：每次写入rowSize个通道的数据（4个通道）
 * - 现在：每次写入colSize个通道的数据（4个通道）
 * - 数据组织方式从按行组织改为按列组织
 * 
 * 提供两种转换函数：
 * - convertFeatures(): 保持原有逻辑，按行组织
 * - convertFeaturesByColumn(): 新逻辑，按列组织，适应新的featureMapBus
 */
object DataConverter {
  // 权重数据转换: CSV -> SRAM格式(cinIdxTotal->Cout->H->W->Cin)
  def convertWeights(
    filePath: String, 
    cout: Int,             // 输出通道数
    cinIdxTotal: Int,         // 输入通道数
    kernelHeight: Int, 
    kernelWidth: Int,
    groupSize: Int = 1        // 组内Tile数，默认为1
  ): Array[Array[Int]] = {
    // 检查文件路径
    val path = Paths.get(filePath)
    if (!Files.exists(path)) {
      throw new FileNotFoundException(s"权重文件不存在: $filePath")
    }
    if (!Files.isReadable(path)) {
      throw new SecurityException(s"无读取权限: $filePath")
    }

    val source = Source.fromFile(filePath)
    val lines = source.getLines().toArray
    source.close()
    
    // 计算总输入通道数（考虑groupSize）
    val cin = cinIdxTotal * Config.rowSize * groupSize
    
    // 解析四维权重数据 [cout][cin][kernelHeight][kernelWidth]
    val weights4D = ArrayBuffer[ArrayBuffer[ArrayBuffer[ArrayBuffer[Int]]]]()
    var currentCout = ArrayBuffer[ArrayBuffer[ArrayBuffer[Int]]]() // 当前输出通道
    var currentCin = ArrayBuffer[ArrayBuffer[Int]]()                // 当前输入通道
    var currentRow = ArrayBuffer[Int]()                            // 当前行

    var prevLineWasEmpty = false  // 新增：跟踪前一行是否为空

    for (line <- lines) {
      val trimmed = line.trim
      if (trimmed.isEmpty) {
        // 优先处理输出通道（需要2个空行）
        if (currentCout.nonEmpty && prevLineWasEmpty) {
          weights4D += currentCout
          currentCout = ArrayBuffer[ArrayBuffer[ArrayBuffer[Int]]]()
        } 
        // 其次处理输入通道（需要1个空行）
        else if (currentCin.nonEmpty && !prevLineWasEmpty) {
          currentCout += currentCin
          currentCin = ArrayBuffer[ArrayBuffer[Int]]()
        }
        
        prevLineWasEmpty = true  // 标记当前是空行
      } else {
        // 处理非空行
        val values = trimmed.split(",").map(_.trim.toInt)
        currentRow ++= values
        prevLineWasEmpty = false  // 重置空行标记
        currentCin += currentRow
        currentRow = ArrayBuffer[Int]()
      }
    }
    
    // 处理最后一个块
    if (currentRow.nonEmpty) currentCin += currentRow
    if (currentCin.nonEmpty) currentCout += currentCin
    if (currentCout.nonEmpty) weights4D += currentCout

    // 打印权重数据
    // println(weights4D)

    // 重组数据为weightSram格式 [cout * cinIdxTotal * kernelHeight * kernelWidth][rowSize * groupSize]
    val reorganized = Array.ofDim[Int](cout * cinIdxTotal * kernelHeight * kernelWidth * groupSize, Config.rowSize)
    
    var addr = 0
    for (idx <- 0 until cinIdxTotal) {             // 遍历输入通道组
      for (c <- 0 until cout) {                     // 遍历输出通道
        for (y <- 0 until kernelHeight) {           // 遍历卷积核高度
          for (x <- 0 until kernelWidth) {          // 遍历卷积核宽度
            for (g <- 0 until groupSize) {          // 遍历组内Tile
              for (i <- 0 until Config.rowSize) {   // 遍历组内所有输入通道
                // 获取(c, i, y, x)位置的值
                reorganized(addr)(i) = weights4D(c)(idx*Config.rowSize*groupSize+g*Config.rowSize+i)(y)(x) // 获取(c, cinIdx, i, y, x)位置的值
              }
              addr += 1
            }
          }
        }
      }
    }
    
    // 修改打印逻辑：使用mkString格式化数组
    println("权重SRAM数据:")
    reorganized.foreach(row => println(row.mkString(", ")))
    
    reorganized  // 直接返回二维数组
  }
  
  // 特征图数据转换: CSV -> SRAM格式(CinIdxTotal->colSize->H->W)
  def convertFeatures( // 修改为：每次更新tile的一个列（featureMapBlock的一组通道）
    filePath: String, 
    cinIdxTotal: Int,         // 输入通道数 (cin)
    height: Int, 
    width: Int,
    groupSize: Int = 1        // 组内Tile数，默认为1
  ): Array[Array[Int]] = {
    // 检查文件路径
    val path = Paths.get(filePath)
    if (!Files.exists(path)) {
      throw new FileNotFoundException(s"特征图文件不存在: $filePath")
    }
    if (!Files.isReadable(path)) {
      throw new SecurityException(s"无读取权限: $filePath")
    }

    val source = Source.fromFile(filePath)
    val lines = source.getLines().toArray
    source.close()
    
    // 解析三维特征图数据 [cin][height][width]
    val features3D = ArrayBuffer[ArrayBuffer[ArrayBuffer[Int]]]()
    var currentCin = ArrayBuffer[ArrayBuffer[Int]]()  // 当前输入通道
    var currentRow = ArrayBuffer[Int]()               // 当前行
    var prevLineWasEmpty = false  // 新增：跟踪前一行是否为空
    
    val cin = cinIdxTotal * Config.rowSize * groupSize
    
    for (line <- lines) {
      val trimmed = line.trim
      if (trimmed.isEmpty) {
        if (currentCin.nonEmpty && !prevLineWasEmpty) {
          // 当前输入通道的矩阵结束
          features3D += currentCin
          currentCin = ArrayBuffer[ArrayBuffer[Int]]()
        }
      } else {
        // 非空行：解析一行数据
        val values = trimmed.split(",").map(_.trim.toInt)
        currentRow ++= values
        prevLineWasEmpty = false
        currentCin += currentRow
        currentRow = ArrayBuffer[Int]()
      }
    }
    
    // 处理最后一个块
    if (currentRow.nonEmpty) currentCin += currentRow
    if (currentCin.nonEmpty) features3D += currentCin

    // 打印特征图数据
    println(features3D)

    // 重组数据：每个位置(x,y)对应一个向量 [height * cin][width]
    // 修改：现在每次写入一个rowSize的数据（一组通道），而不是colSize个行像素
    val reorganized = Array.ofDim[Int](height * cin, width)
    
    var addr = 0
    for (idx <- 0 until cinIdxTotal) {       // 遍历输入通道组
      for (g <- 0 until groupSize) {         // 遍历组内Tile
        for (c <- 0 until Config.rowSize) {  // 遍历每个Tile内的输入通道
          for (y <- 0 until height) {        // 遍历特征图高度
            for (x <- 0 until width) {       // 遍历特征图Block的宽度
              val globalCinIdx = idx * Config.rowSize * groupSize + g * Config.rowSize + c
              // 获取(globalCinIdx, y, x)位置的值
              if (globalCinIdx < features3D.length) {
                val chan = features3D(globalCinIdx)
                if (y < chan.length) {
                  val row = chan(y)
                  if (x < row.length) {
                    reorganized(addr)(x) = row(x)
                  } else {
                    reorganized(addr)(x) = 0
                    println(s"列越界: x=${x}, row.length=${row.length}, cin=${globalCinIdx}, y=${y}")
                  }
                } else {
                  reorganized(addr)(x) = 0
                  println(s"行越界: y=${y}, chan.length=${chan.length}, cin=${globalCinIdx}")
                }
              } else {
                reorganized(addr)(x) = 0  // 超出范围时填充0
                println(s"通道越界: globalCinIdx = ${globalCinIdx}, features3D.length = ${features3D.length}")
              }
            }
            addr += 1
          }
        }
      }
    }
    
    // 修改打印逻辑：使用mkString格式化数组
    println("特征图SRAM数据:")
    reorganized.foreach(row => println(row.mkString(", "))) 
    
    reorganized  // 直接返回二维数组
  }
  
  // 结果数据转换: SRAM格式 -> CSV（每个地址即为一整行，不再两个地址拼接）
  def printOutputSramResults(
    results: Array[Array[Int]], // outputSram数据 [地址][colSize]
    filePath: String,
    cout: Int,             // 输出通道数
    k: Int,                // 卷积核尺寸
    groupNum: Int,         // 分组数
    colSize: Int,          // 列数（半行长度）
    resolutionColIdx: Int = 0, // 新增：分辨率列索引，用于输出文件名后缀
    resolutionRowIdx: Int = 0  // 新增：分辨率行索引，用于输出文件名后缀
  ): Unit = {
    // 基于传入的filePath，生成追加 _r<rowIdx>_c<colIdx> 的新文件名
    val inFile = new File(filePath)
    val parentDir = Option(inFile.getParent).getOrElse("")
    val name = inFile.getName
    val dot = name.lastIndexOf('.')
    val (base, ext) = if (dot > 0) (name.substring(0, dot), name.substring(dot)) else (name, "")
    val outName = s"${base}_r${resolutionRowIdx}_c${resolutionColIdx}${ext}"
    val outFile = if (parentDir.nonEmpty) new File(parentDir, outName) else new File(outName)
    val writer = new PrintWriter(outFile)
    
    // 每个输出通道的数据行数（只打印前groupNum行）
    val rowsPerChannel = groupNum
    // 每个输出通道的地址数（每地址一整行）
    val addressesPerChannel = rowsPerChannel

    // 验证数据总量
    // require(results.size == cout * addressesPerChannel, 
    //   s"结果数据总量应为${cout * addressesPerChannel}，实际为${results.size}")

    for (c <- 0 until cout) {  // 遍历输出通道
      // 当前通道的起始地址
      val startAddr = c * addressesPerChannel

      // 直接写出每个地址的一行（期望每行长度为 2*colSize）
      for (row <- 0 until rowsPerChannel) {
        val addr = startAddr + row
        val lineVec = results(addr)
        val line = lineVec.mkString(",")
        writer.println(line)
      }

      // 通道间用空行分隔（最后一个通道后不加空行）
      if (c < cout - 1) {
        writer.println()
      }
    }

    writer.close()
  }

  // 打印jointSram数据函数（每个地址即为一整行）
  def printJointSramData(
    jointSram: Array[Array[Int]], // jointSram数据 [地址][colSize]
    filePath: String,              // 输出CSV文件路径
    cout: Int,                     // 输出通道数
    k: Int,                        // 卷积核尺寸
    colSize: Int                   // 列数（半行长度）
  ): Unit = {
    val writer = new PrintWriter(new File(filePath))
    
    // jointSram的结果图行数为k-1
    val jointSramRowsPerChannel = k - 1
    // 每地址即为一整行
    val jointSramAddressesPerChannel = jointSramRowsPerChannel
    
    for (c <- 0 until cout) {  // 遍历输出通道
      // 当前通道的起始地址
      val startAddr = c * jointSramAddressesPerChannel
      
      // 直接将每个地址的一整行写入CSV
      for (row <- 0 until jointSramRowsPerChannel) {
        val addr = startAddr + row
        if (addr < jointSram.length) {
          val line = jointSram(addr).mkString(",")
          writer.println(line)
        }
      }
      
      // 通道间用空行分隔（最后一个通道后不加空行）
      if (c < cout - 1) {
        writer.println()
      }
    }
    
    writer.close()
    
    // 同时在控制台打印信息
    // println(s"Joint SRAM 数据已写入文件: $filePath")
  }

  // 合并结果数据函数：将output_results和joint_results拼接成完整的results
  def mergeResults(
    outputResultsBasePath: String,  // output_results.csv文件的基础路径（不包含后缀）
    jointResultsPath: String,       // joint_results.csv文件路径
    mergedResultsPath: String,      // 合并后的results.csv文件路径
    cout: Int,                      // 输出通道数
    k: Int,                         // 卷积核尺寸
    groupNum: Int,                  // 分组数
    colSize: Int,                   // 列数（半行长度）
    resolutionColIdxTotal: Int      // 新增：分辨率列索引总数，用于确定需要合并的output文件数量
  ): Unit = {
    // 读取joint_results.csv
    val jointSource = Source.fromFile(jointResultsPath)
    val jointLines = jointSource.getLines().toArray
    jointSource.close()
    
    val writer = new PrintWriter(new File(mergedResultsPath))
    
    // 每个输出通道的完整行数
    val totalRowsPerChannel = k + groupNum - 1
    // output_results的行数
    val outputRowsPerChannel = groupNum
    // joint_results的行数
    val jointRowsPerChannel = k - 1
    
    var jointLineIndex = 0
    
    for (c <- 0 until cout) {  // 遍历输出通道
      // 存储当前通道所有resolution列的数据，用于横向拼接
      val channelData = Array.ofDim[Int](outputRowsPerChannel, resolutionColIdxTotal * 2 * colSize)
      
      // 读取所有resolution列的output文件数据
      for (resolutionColIdx <- 0 until resolutionColIdxTotal) {
        // 构建带后缀的文件名
        val inFile = new File(outputResultsBasePath)
        val parentDir = Option(inFile.getParent).getOrElse("")
        val name = inFile.getName
        val dot = name.lastIndexOf('.')
        val (base, ext) = if (dot > 0) (name.substring(0, dot), name.substring(dot)) else (name, "")
        val outputFileName = s"${base}_${resolutionColIdx}${ext}"
        val outputFilePath = if (parentDir.nonEmpty) new File(parentDir, outputFileName) else new File(outputFileName)
        
        // 检查文件是否存在
        if (outputFilePath.exists()) {
          val outputSource = Source.fromFile(outputFilePath)
          val outputLines = outputSource.getLines().toArray
          outputSource.close()
          
          // 解析当前resolution列的数据
          var lineIndex = 0
          for (row <- 0 until outputRowsPerChannel) {
            if (lineIndex < outputLines.length) {
              val line = outputLines(lineIndex).trim
              if (line.nonEmpty) {
                val values = line.split(",").map(_.trim.toInt)
                // 将数据复制到对应位置（横向拼接）
                for (col <- 0 until values.length) {
                  channelData(row)(resolutionColIdx * 2 * colSize + col) = values(col)
                }
              }
              lineIndex += 1
            }
          }
          
          // 跳过空行分隔符
          while (lineIndex < outputLines.length && outputLines(lineIndex).trim.isEmpty) {
            lineIndex += 1
          }
        } else {
          println(s"警告：文件不存在: $outputFilePath")
        }
      }
      
      // 写入当前通道的横向拼接数据（前groupNum行）
      for (row <- 0 until outputRowsPerChannel) {
        val line = channelData(row).mkString(",")
        writer.println(line)
      }
      
      // 再写入joint_results的数据（后k-1行）
      for (row <- 0 until jointRowsPerChannel) {
        if (jointLineIndex < jointLines.length) {
          val line = jointLines(jointLineIndex).trim
          if (line.nonEmpty) {
            writer.println(line)
          }
          jointLineIndex += 1
        }
      }
      
      // 通道间用空行分隔（最后一个通道后不加空行）
      if (c < cout - 1) {
        writer.println()
      }
      
      // 跳过空行分隔符
      while (jointLineIndex < jointLines.length && jointLines(jointLineIndex).trim.isEmpty) {
        jointLineIndex += 1
      }
    }
    
    writer.close()
    println(s"结果数据已合并到文件: $mergedResultsPath")
  }

  // 完善的多行多列结果合并函数
  def mergedOutput(
    outputResultsBasePath: String,  // output_results.csv文件的基础路径（不包含后缀）
    jointResultsPath: String,       // joint_results.csv文件路径
    mergedResultsPath: String,      // 合并后的results.csv文件路径
    cout: Int,                      // 输出通道数
    k: Int,                         // 卷积核尺寸
    groupNum: Int,                  // 分组数
    colSize: Int,                   // 列数（半行长度）
    resolutionColIdxTotal: Int,     // 分辨率列索引总数
    resolutionRowIdxTotal: Int      // 分辨率行索引总数
  ): Unit = {
    // 读取joint_results.csv
    val jointSource = Source.fromFile(jointResultsPath)
    val jointLines = jointSource.getLines().toArray
    jointSource.close()
    
    val writer = new PrintWriter(new File(mergedResultsPath))
    
    // 每个输出通道的完整行数
    val totalRowsPerChannel = k + groupNum - 1
    // output_results的行数
    val outputRowsPerChannel = groupNum
    // joint_results的行数
    val jointRowsPerChannel = k - 1
    
    var jointLineIndex = 0
    
    for (c <- 0 until cout) {  // 遍历输出通道
      // 存储当前通道所有resolution行列的数据，用于多维度拼接
      val channelData = Array.ofDim[Int](resolutionRowIdxTotal * outputRowsPerChannel, resolutionColIdxTotal * 2 * colSize)
      
      // 读取所有resolution行列的output文件数据
      for (resolutionRowIdx <- 0 until resolutionRowIdxTotal) {
        for (resolutionColIdx <- 0 until resolutionColIdxTotal) {
          // 构建带行列后缀的文件名
          val inFile = new File(outputResultsBasePath)
          val parentDir = Option(inFile.getParent).getOrElse("")
          val name = inFile.getName
          val dot = name.lastIndexOf('.')
          val (base, ext) = if (dot > 0) (name.substring(0, dot), name.substring(dot)) else (name, "")
          val outputFileName = s"${base}_r${resolutionRowIdx}_c${resolutionColIdx}${ext}"
          val outputFilePath = if (parentDir.nonEmpty) new File(parentDir, outputFileName) else new File(outputFileName)
          
          // 检查文件是否存在
          if (outputFilePath.exists()) {
            val outputSource = Source.fromFile(outputFilePath)
            val outputLines = outputSource.getLines().toArray
            outputSource.close()
            
            // 解析当前resolution行列的数据
            var lineIndex = 0
            for (row <- 0 until outputRowsPerChannel) {
              if (lineIndex < outputLines.length) {
                val line = outputLines(lineIndex).trim
                if (line.nonEmpty) {
                  val values = line.split(",").map(_.trim.toInt)
                  // 将数据复制到对应位置（考虑行重叠）
                  val targetRow = resolutionRowIdx * outputRowsPerChannel + row
                  for (col <- 0 until values.length) {
                    channelData(targetRow)(resolutionColIdx * 2 * colSize + col) = values(col)
                  }
                }
                lineIndex += 1
              }
            }
            
            // 跳过空行分隔符
            while (lineIndex < outputLines.length && outputLines(lineIndex).trim.isEmpty) {
              lineIndex += 1
            }
          } else {
            println(s"警告：文件不存在: $outputFilePath")
          }
        }
      }
      
      // 处理行重叠：相邻行之间根据groupNum参数进行重叠
      val finalChannelData = Array.ofDim[Int](resolutionRowIdxTotal * outputRowsPerChannel, resolutionColIdxTotal * 2 * colSize)
      
      // 复制第一行的数据
      for (row <- 0 until outputRowsPerChannel) {
        for (col <- 0 until resolutionColIdxTotal * 2 * colSize) {
          finalChannelData(row)(col) = channelData(row)(col)
        }
      }
      
      // 处理后续行的重叠
      for (resolutionRowIdx <- 1 until resolutionRowIdxTotal) {
        val startRow = resolutionRowIdx * outputRowsPerChannel
        val prevEndRow = (resolutionRowIdx - 1) * outputRowsPerChannel + outputRowsPerChannel - 1
        
        // 重叠区域：前一行末尾的groupNum行与当前行开头的groupNum行重叠
        val overlapRows = Math.min(groupNum, outputRowsPerChannel)
        
        for (overlapRow <- 0 until overlapRows) {
          val currentRow = startRow + overlapRow
          val prevRow = prevEndRow - overlapRows + 1 + overlapRow
          
          if (currentRow < resolutionRowIdxTotal * outputRowsPerChannel && 
              prevRow >= 0 && prevRow < resolutionRowIdxTotal * outputRowsPerChannel) {
            for (col <- 0 until resolutionColIdxTotal * 2 * colSize) {
              // 重叠区域：取平均值或累加（这里选择累加）
              finalChannelData(currentRow)(col) = channelData(prevRow)(col) + channelData(currentRow)(col)
            }
          }
        }
        
        // 非重叠区域：直接复制
        for (row <- overlapRows until outputRowsPerChannel) {
          val currentRow = startRow + row
          if (currentRow < resolutionRowIdxTotal * outputRowsPerChannel) {
            for (col <- 0 until resolutionColIdxTotal * 2 * colSize) {
              finalChannelData(currentRow)(col) = channelData(currentRow)(col)
            }
          }
        }
      }
      
      // 写入当前通道的横向拼接数据（所有行）
      for (row <- 0 until resolutionRowIdxTotal * outputRowsPerChannel) {
        val line = finalChannelData(row).mkString(",")
        writer.println(line)
      }
      
      // 再写入joint_results的数据（后k-1行）
      for (row <- 0 until jointRowsPerChannel) {
        if (jointLineIndex < jointLines.length) {
          val line = jointLines(jointLineIndex).trim
          if (line.nonEmpty) {
            writer.println(line)
          }
          jointLineIndex += 1
        }
      }
      
      // 通道间用空行分隔（最后一个通道后不加空行）
      if (c < cout - 1) {
        writer.println()
      }
      
      // 跳过空行分隔符
      while (jointLineIndex < jointLines.length && jointLines(jointLineIndex).trim.isEmpty) {
        jointLineIndex += 1
      }
    }
    
    writer.close()
    println(s"多行多列结果数据已合并到文件: $mergedResultsPath")
    println(s"合并了 ${resolutionRowIdxTotal} 行 x ${resolutionColIdxTotal} 列的结果")
  }
}