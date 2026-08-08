package FLOOD_Accelerator.machine

import chisel3._
import chisel3.util._
import scala.math._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers
import FLOOD_Accelerator.core.Config
import firrtl.options.TargetDirAnnotation
import chiseltest.VerilatorBackendAnnotation
import chiseltest.simulator.{VerilatorCFlags, VerilatorFlags}
import scala.util.Random
import FLOOD_Accelerator.utils.DataConverter
import java.io.File
import scala.collection.mutable.Queue

class MacMachineWrapperTest extends AnyFlatSpec with ChiselScalatestTester with Matchers {
  behavior of "MacMachineWrapper"

  private val traceEnabled = sys.props.get("flood.wrapper.trace").contains("true")
  private def trace(message: => String): Unit = if (traceEnabled) println(message)

  // 写配置
  def writeConfig(dut: MacMachineWrapper, data: BigInt, addr: Int): Unit = {
    dut.io.configBus.data.poke(data.U)
    dut.io.configBus.addr.poke(addr.U)
    dut.io.configBus.en.poke(true.B)
    dut.clock.step(1)
    dut.io.configBus.en.poke(false.B)
  }

  // 触发一次运行：通过写 runProcessId 非0
  def triggerRun(dut: MacMachineWrapper): Unit = {
    writeConfig(dut, 1, Config.runProcessId)
    trace(s"triggerRun")
  }

  // 写特征图（按 MacMachineTest 的总线打包方式）
  def updateFeatureMapBus(
    dut: MacMachineWrapper,
    tileId: Int,
    addr: Int,
    data: BigInt
  ): Unit = {
    val idWidth = Config.idWidth
    val rowAddrWidth = log2Ceil(Config.rowSize)
    val composedAddr = ((tileId & ((1<<idWidth)-1)) << rowAddrWidth) | (addr & ((1<<rowAddrWidth)-1))
    dut.io.featureMapBus.addr.poke(composedAddr.U)
    dut.io.featureMapBus.data.poke(data.U(Config.featureMapBandWidth.W))
    dut.io.featureMapBus.en.poke(true.B)
    dut.clock.step(1)
    dut.io.featureMapBus.en.poke(false.B)
  }

  // 批量写特征图
  def updateFeatureMapMatrix(
    dut: MacMachineWrapper,
    tileId: Int,
    fullFeatureMapMatrix: Array[Array[Int]],
    cinIdx: Int,
    rowIdxTotal: Int,
    colIdx: Int,
    rowIdx: Int,
    groupNum: Int,
    groupSize: Int,
  ): Unit = {
    val rowSize = Config.rowSize
    val colSize = Config.colSize
    val featureMapBandWidth = Config.featureMapBandWidth
    val dataWidth = Config.dataWidth
    val writesPerRow = ceil(colSize * dataWidth / featureMapBandWidth).toInt
    val elementPerWrite = featureMapBandWidth / dataWidth
    val startRowCin = (cinIdx * (rowSize*groupSize) + ((groupSize-1-tileId%groupSize)*rowSize)) * (groupNum*rowIdxTotal) // 倒序关系设置id,可以提高组内数据传递效率，降低计算延迟
    val startRowHeight = rowIdx*groupNum + tileId/groupSize
    val startRow = startRowCin + startRowHeight

    for (r <- 0 until rowSize) {
      for (c <- 0 until writesPerRow) {
        val startCol = c * elementPerWrite + colIdx * colSize
        val endCol = Math.min((c+1)*elementPerWrite, colSize) + colIdx * colSize
        val featureMapValues = (startCol until endCol).map { col =>
          fullFeatureMapMatrix (startRow + r*groupNum*rowIdxTotal)(col)
        }
        val addr = r * writesPerRow + c
        var packedData = BigInt(0)
        for (i <- featureMapValues.indices) {
          val featureMapValue = featureMapValues(i)
          val shiftedValue = (BigInt(featureMapValue) & ((BigInt(1) << dataWidth) - 1)) << (i * dataWidth)
          packedData |= shiftedValue
        }
        updateFeatureMapBus(dut, tileId, addr, packedData)
        trace(s"tileId=${tileId}, row = ${r}, addrIn = ${((tileId & ((1<<Config.idWidth)-1)) << log2Ceil(Config.rowSize)) | (addr & ((1<<log2Ceil(Config.rowSize))-1))}, startCol=${startCol}, endCol=${endCol-1}, featureMapValues=[${featureMapValues.mkString(", ")}], packed=0x${packedData.toString(16)}")
      }
    }
  }

  // 测试用例
  it should "run MacMachineWrapper with pingpong SRAMs and done handshake" in {
    val annos = Seq(
      VerilatorBackendAnnotation,
      VerilatorFlags(Seq("--output-split", "0")),
      VerilatorCFlags(Seq("-O0")),
      TargetDirAnnotation("test_run_dir/MacMachine/MacMachineWrapper_basic")
    )
    test(new MacMachineWrapper).withAnnotations(annos) { dut =>
      var featurePingpongFlag = false
      var weightPingpongFlag = true
      var outputPingpongFlag = true
      var pingpongEnFlag = false  // 乒乓使能标志，有效时weight/output 才会乒乓起来，否则保持ping

      val k = 2; val cout = 2; val groupSize = 4; val groupNum = Config.tileSize/groupSize;  val stride = 1;
      val cinIdxTotal = 1; val resolutionColIdxTotal = 1; val resolutionRowIdxTotal = 1
      var planeWorkMode = 0
      // 全局动作开关：用于统一打开/关闭 BN/ACT/POOL（按需修改）
      val actionEn = true; val PoolEn = false; val BnEn = true; val ActEn = false
      val dataFlowMode = 0
      // 截位位数
      val truncateBits = 5
      val truncateEn = 0 // 1: 使能动态截位; 0: 关闭动态截位
      
      // NVDLA配置参数
      // kx: 当前像素位置kx (0 到 k-1)
      // ky: 当前像素位置ky (0 到 k-1)  
      // featBlkWid: 特征图块宽度 (0 到 maxPixelParallel-1)
      // pixelPara: 像素并行参数 (0 到 maxPixelPara-1)
      val nvdlaKx = 3
      val nvdlaKy = 3
      val nvdlaFeatBlkWid = 3
      val nvdlaPixelPara = 2  
      
      val rowSize = Config.rowSize
      val colSize = Config.colSize
      val tileSize = Config.tileSize
      val dataWidth = Config.dataWidth
      val outputBufferDataWidth = Config.outputBufferDataWidth

      // 特征/权重
      val featureMapMatrix = DataConverter.convertFeatures(
        new File("src/python/features.csv").getAbsolutePath,
        cinIdxTotal = cinIdxTotal,
        height = (groupNum * resolutionRowIdxTotal),
        width = colSize * resolutionColIdxTotal,
        groupSize = groupSize
      )
      val weightSramPingMem = DataConverter.convertWeights(
        new File("src/python/weights.csv").getAbsolutePath,
        cout = cout,
        cinIdxTotal = cinIdxTotal,
        kernelHeight = k,
        kernelWidth = k,
        groupSize = groupSize
      )
      val weightSramPongMem = DataConverter.convertWeights(
        new File("src/python/weights.csv").getAbsolutePath,
        cout = cout,
        cinIdxTotal = cinIdxTotal,
        kernelHeight = k,
        kernelWidth = k,
        groupSize = groupSize
      )
      
      val outputSramPingMem = Array.ofDim[Int](Config.outputSramLength, colSize)
      val outputSramPongMem = Array.ofDim[Int](Config.outputSramLength, colSize)
      val outputJointSramMem = Array.ofDim[Int](Config.outputSramLength, colSize)
      val jointSramMem = Array.ofDim[Int](Config.jointSramLength, colSize)

      // 乒乓切换逻辑
      def updateWeightPingpongFlag(): Unit = {
        if (pingpongEnFlag) weightPingpongFlag = !weightPingpongFlag
      }
      def updateOutputPingpongFlag(): Unit = {
        if (pingpongEnFlag) outputPingpongFlag = !outputPingpongFlag
      }

      def activeWeightSramMem: Array[Array[Int]] = if (weightPingpongFlag) weightSramPongMem else weightSramPingMem
      def activeOutputSramMem: Array[Array[Int]] = if (outputPingpongFlag) outputSramPongMem else outputSramPingMem

      case class SramReadRequest(sramType: String, addr: Int, data: Array[Int])
      val weightSramReadQueue1 = Queue[SramReadRequest]()
      val weightSramReadQueue2 = Queue[SramReadRequest]()

      // 配置 Tiles：根据 tileId%groupSize 赋值 writeId；featureMapLine=tileId/groupSize
      val workMode = 0; val kernelSize = k-1; val remain = 0
      val workModeWidth = log2Ceil(Config.maxWorkMode)
      val kernelSizeWidth = log2Ceil(Config.maxKernelSize)
      val tileIdWidth = Config.idWidth
      val featureMapLineWidth = tileIdWidth
      val remainWidth = Config.configDataWidth - kernelSizeWidth - workModeWidth - 2*tileIdWidth
      for (tileId <- 0 until tileSize) {
        val featureMapLine = tileId/groupSize
        val writeId = (groupSize-1)-(tileId % groupSize)   // 倒序关系设置id,可以提高组内数据传递效率，降低计算延迟
        val configData = ((remain & ((1 << remainWidth) - 1)) << (tileIdWidth + workModeWidth + kernelSizeWidth + tileIdWidth)) |
                ((featureMapLine & ((1 << tileIdWidth) - 1)) << (workModeWidth + kernelSizeWidth + tileIdWidth)) |
                ((workMode & ((1 << workModeWidth) - 1)) << (kernelSizeWidth + tileIdWidth)) |
                ((writeId & ((1 << tileIdWidth) - 1)) << kernelSizeWidth) |
                (kernelSize & ((1 << kernelSizeWidth) - 1))
        writeConfig(dut, configData, Config.tileConfIdStart + tileId)
      }

      // 配置 InterNoC 路由：
      // 若上下相邻 Tile 跨 group（(nocId/groupSize)!=(nocId+1)/groupSize），systolic=1；否则 add=1（systolic=0）
      for (nocId <- 0 until tileSize - 1) {
        val upperGroup = nocId / groupSize
        val lowerGroup = (nocId + 1) / groupSize
        val systolic = if (upperGroup != lowerGroup) 1 else 0
        val add = if (upperGroup == lowerGroup) 1 else 0
        val deliver = 1
        // 假设 routerConfig bit 映射：bit3=deliver, bit2=systolic, bit1=add
        val routerConfig = (deliver << 3) | (systolic << 2) | (add << 1)
        writeConfig(dut, routerConfig, Config.nocConfIdStart + nocId)
      }

      // 配置 BN 参数：上半 16 位为 mulParam（设为1），下半 16 位为 addParam（0..colSize-1 递增）
      for (i <- 0 until colSize) {
        val mulParam = 1 & 0xFFFF
        val addParam = i & 0xFFFF
        val bnPacked = (mulParam << 16) | addParam
        writeConfig(dut, bnPacked, Config.bnConfIdStart + i)
        trace(s"BN param write: idx=${i}, mul=${mulParam}, add=${addParam}, data=0x${bnPacked.toHexString}")
      }

      // FSM/OutRouter 配置
      val kernelBlockKWidth = log2Ceil(Config.maxKernelBlockK)
      val groupSizeWidth = log2Ceil(Config.maxGroupSize)
      val groupNumWidth = log2Ceil(Config.maxGroupNum)
      val cinIdxWidth = log2Ceil(Config.maxKernelBlockCin/Config.rowSize + 1)
      val kernelBlockCoutWidth = log2Ceil(Config.maxKernelBlockCout)
      val resolutionColIdxWidth = log2Ceil(Config.maxResolutionCol/Config.colSize + 1)
      val truncateBitsWidth = log2Ceil(Config.outputBufferTmpWidth)
      val strideWidth = kernelBlockKWidth // 与 FSM 保持一致，stride 位宽与 k 位宽一致
      val featBlkWidWidth = log2Ceil(Config.maxFeatureBlockWidth)
      val pixelParaWidth = log2Ceil(Config.maxPixelParallel)

      // 封装一次运行（拷贝自 MacMachineTest 结构，适配 Wrapper 串口 + runProcess）
      def runProcess(
        k: Int,
        cout: Int,
        cinIdx: Int,
        groupNum: Int,
        groupSize: Int,
        stride: Int,
        planeWorkMode: Int,
        resolutionColIdx: Int,
        resolutionRowIdx: Int,
        kxIdx: Int,
        kyIdx: Int
      ): Unit = {
        // 在 runProcess 内部根据 cinIdx / cinIdxTotal 生成 actionMode
        val isFinalCinIdx = if (dataFlowMode == 0) { cinIdx == (cinIdxTotal - 1) } else { kxIdx == (nvdlaKx - 1) && kyIdx == (nvdlaKy - 1) }
        // val dataFlowMode = dataFlowMode
        val bnEn = if (actionEn) if (BnEn) 1 else 0 else 0
        val actEn = if (actionEn) if (ActEn) 1 else 0 else 0  
        val poolEn = if (actionEn) if (PoolEn) 1 else 0 else 0
        val actionMode = (dataFlowMode << 0) | ((if(isFinalCinIdx) 1 else 0) << 1) | (bnEn << 2) | (actEn << 3) | (poolEn << 4)
        // pre 打印所有参数
        trace(s"This run process: k = ${k}, cout = ${cout}, groupNum = ${groupNum}, groupSize = ${groupSize}, stride = ${stride}, planeWorkMode = ${planeWorkMode}, isFinalCinIdx = ${isFinalCinIdx}, bnEn = ${bnEn}, actEn = ${actEn}, poolEn = ${poolEn}")
        trace(s"cinIdx = ${cinIdx}, resolutionRowIdx = ${resolutionRowIdx}, resolutionColIdx = ${resolutionColIdx}")
        val kernelBlockKWidth = log2Ceil(Config.maxKernelBlockK)
        val groupSizeWidth = log2Ceil(Config.maxGroupSize)
        val groupNumWidth = log2Ceil(Config.maxGroupNum)
        val kernelBlockCoutWidth = log2Ceil(Config.maxKernelBlockCout)
        // 配置寄存器数据准备
        val normalConfig = (BigInt(stride-1) << (kernelBlockKWidth + groupSizeWidth + groupNumWidth + kernelBlockCoutWidth)) |
                           (BigInt(cout-1) << (kernelBlockKWidth + groupSizeWidth + groupNumWidth)) |
                           (BigInt(groupNum-1) << (kernelBlockKWidth + groupSizeWidth)) |
                           (BigInt(groupSize-1) << kernelBlockKWidth) |
                           BigInt(k-1)

        // ========== 二段队列：为每个读端口建立 2 级队列 ==========
        case class SramReadRequest(addr: Int, data: Array[Int])
        // weight ping/pong
        val wPingQ1 = Queue[SramReadRequest]()
        val wPingQ2 = Queue[SramReadRequest]()
        val wPongQ1 = Queue[SramReadRequest]()
        val wPongQ2 = Queue[SramReadRequest]()
        // output read ping/pong
        val oPingQ1 = Queue[SramReadRequest]()
        val oPingQ2 = Queue[SramReadRequest]()
        val oPongQ1 = Queue[SramReadRequest]()
        val oPongQ2 = Queue[SramReadRequest]()
        // outputJoint read
        val oJointQ1 = Queue[SramReadRequest]()
        val oJointQ2 = Queue[SramReadRequest]()
        // joint read
        val jointQ1 = Queue[SramReadRequest]()
        val jointQ2 = Queue[SramReadRequest]()
        
        trace(s"Normal配置: k=${k-1}, groupSize=${groupSize-1}, groupNum=${groupNum-1}, cout=${cout-1}, stride=${stride}")
        trace(s"normalConfig = 0x${normalConfig.toString(16)} (${normalConfig})")
        writeConfig(dut, normalConfig, Config.FSMRouterConfIdStart)
        
        // Special寄存器布局（更新后）：{remain, truncateEn[+1], truncateBits[+truncateBitsWidth], workMode, colIdx, cinIdx}
        val specialConfig = (BigInt(truncateEn & 0x1) << (cinIdxWidth + resolutionColIdxWidth + workModeWidth + truncateBitsWidth)) |
                            (BigInt(truncateBits) << (cinIdxWidth + resolutionColIdxWidth + workModeWidth)) |
                            (BigInt(planeWorkMode) << (cinIdxWidth + resolutionColIdxWidth)) |
                            (BigInt(resolutionColIdx) << cinIdxWidth) |
                            BigInt(cinIdx)
        
        trace(s"Special配置: cinIdx=${cinIdx}, resolutionColIdx=${resolutionColIdx}, workMode=${planeWorkMode}, truncateEn=${truncateEn}, truncateBits=${truncateBits}")
        trace(s"specialConfig = 0x${specialConfig.toString(16)} (${specialConfig})")
        writeConfig(dut, specialConfig, Config.FSMRouterConfIdEnd)
        
        // NVDLA REG配置
        val featBlkWidWidth = log2Ceil(Config.maxFeatureBlockWidth)
        val pixelParaWidth = log2Ceil(Config.maxPixelParallel)
        val nvdlaRegConfig = (BigInt(nvdlaPixelPara-1) << (kernelBlockKWidth + kernelBlockKWidth + featBlkWidWidth)) |
                            (BigInt(nvdlaFeatBlkWid-1) << (kernelBlockKWidth + kernelBlockKWidth)) |
                            (BigInt(kyIdx) << kernelBlockKWidth) |
                            BigInt(kxIdx)
        
        trace(s"NVDLA配置: kx=${nvdlaKx}, ky=${nvdlaKy}, featBlkWid=${nvdlaFeatBlkWid}, pixelPara=${nvdlaPixelPara}")
        trace(s"nvdlaRegConfig = 0x${nvdlaRegConfig.toString(16)} (${nvdlaRegConfig})")
        writeConfig(dut, nvdlaRegConfig, Config.nvdlaRegId)
        
        for (tileId <- 0 until tileSize) {
          updateFeatureMapMatrix(dut, tileId, featureMapMatrix, cinIdx = cinIdx, rowIdxTotal = resolutionRowIdxTotal, colIdx = resolutionColIdx, rowIdx = resolutionRowIdx, groupNum = groupNum, groupSize = groupSize)
        }
        
        featurePingpongFlag = !featurePingpongFlag
        
        // 根据pingpongEnFlag决定实际的weight/output乒乓标志
        updateWeightPingpongFlag()
        updateOutputPingpongFlag()
        
        val globalConfInfo = (BigInt(if (featurePingpongFlag) 1 else 0) << (Config.configDataWidth - 1)) | 
                            (BigInt(if (weightPingpongFlag) 1 else 0) << (Config.configDataWidth - 2)) |
                            (BigInt(if (outputPingpongFlag) 1 else 0) << (Config.configDataWidth - 3)) |
                            BigInt(actionMode)
        
        trace(s"Global配置: featurePingpong=${featurePingpongFlag}, weightPingpong=${weightPingpongFlag}, outputPingpong=${outputPingpongFlag}, actionMode=${actionMode}")
        trace(s"globalConfInfo = 0x${globalConfInfo.toString(16)} (${globalConfInfo})")
        writeConfig(dut, globalConfInfo, Config.globalConfId)
        dut.clock.setTimeout(0)
        dut.clock.step(2)

        triggerRun(dut)

        val maxRunCycles = sys.props.get("flood.wrapper.maxCycles").map(_.toInt).getOrElse(512)
        var elapsedCycles = 0
        var localDone = false
        var errorObserved = false
        while (!localDone && !errorObserved && elapsedCycles < maxRunCycles) {
          // ---------- 权重SRAM读：按正确顺序处理（2级延迟） ----------
          // 1. Q2 输出到 DUT (先输出)
          if (wPingQ2.nonEmpty) {
            val req = wPingQ2.dequeue()
            var packed = BigInt(0)
            for (i <- 0 until rowSize) {
              val v = BigInt(req.data(i)) & ((BigInt(1) << dataWidth) - 1)
              packed |= (v << (i * dataWidth))
            }
            dut.io.weightSramReadPing.readData.poke(packed.U)
            trace(s"weightSramReadPing response: addr=${req.addr}, data=0x${req.data.mkString(", ")}")
          }
          if (wPongQ2.nonEmpty) {
            val req = wPongQ2.dequeue()
            var packed = BigInt(0)
            for (i <- 0 until rowSize) {
              val v = BigInt(req.data(i)) & ((BigInt(1) << dataWidth) - 1)
              packed |= (v << (i * dataWidth))
            }
            dut.io.weightSramReadPong.readData.poke(packed.U)
            trace(s"weightSramReadPong response: addr=${req.addr}, data=0x${req.data.mkString(", ")}")
          }
          
          // 2. 推进队列：Q1->Q2 (然后推进)
          if (wPingQ1.nonEmpty) wPingQ2.enqueue(wPingQ1.dequeue())
          if (wPongQ1.nonEmpty) wPongQ2.enqueue(wPongQ1.dequeue())
          
          // 3. dut.io->Q1 (最后接收新请求)
          if (dut.io.weightSramReadPing.readEnable.peek().litToBoolean) {
            val addr = dut.io.weightSramReadPing.readAddress.peek().litValue.toInt
            val vec = if (addr < weightSramPingMem.length) weightSramPingMem(addr) else Array.fill(rowSize)(0)
            wPingQ1.enqueue(SramReadRequest(addr, vec))
          }
          if (dut.io.weightSramReadPong.readEnable.peek().litToBoolean) {
            val addr = dut.io.weightSramReadPong.readAddress.peek().litValue.toInt
            val vec = if (addr < weightSramPongMem.length) weightSramPongMem(addr) else Array.fill(rowSize)(0)
            wPongQ1.enqueue(SramReadRequest(addr, vec))
          }

          def unpackWrite(bus: BigInt): Array[Int] = {
            val arr = Array.ofDim[Int](colSize)
            for (i <- 0 until colSize) {
              val element = (bus >> (i * Config.outputBufferTmpWidth)) & ((BigInt(1) << Config.outputBufferTmpWidth) - 1)
              val signBit = (element >> (Config.outputBufferTmpWidth - 1)) & 1
              val signedElement = if (signBit == 1) element | (-1L << Config.outputBufferTmpWidth) else element
              arr(i) = signedElement.toInt
            }
            arr
          }
          if (dut.io.outputSramPing.writeEnable.peek().litToBoolean) {
            val addr = dut.io.outputSramPing.writeAddress.peek().litValue.toInt
            val dataBusVal = dut.io.outputSramPing.writeData.peek().litValue
            if (addr < outputSramPingMem.length) outputSramPingMem(addr) = unpackWrite(dataBusVal)
            trace(s"outputSramPing write: addr=$addr, data=${outputSramPingMem(addr).mkString(", ")}")
          }
          if (dut.io.outputSramPong.writeEnable.peek().litToBoolean) {
            val addr = dut.io.outputSramPong.writeAddress.peek().litValue.toInt
            val dataBusVal = dut.io.outputSramPong.writeData.peek().litValue
            if (addr < outputSramPongMem.length) outputSramPongMem(addr) = unpackWrite(dataBusVal)
            trace(s"outputSramPong write: addr=$addr, data=${outputSramPongMem(addr).mkString(", ")}")
          }
          if (dut.io.outputJointSram.writeEnable.peek().litToBoolean) {
            val addr = dut.io.outputJointSram.writeAddress.peek().litValue.toInt
            val dataBusVal = dut.io.outputJointSram.writeData.peek().litValue
            // outputJointSram 应该写入到 jointSramMem，而不是 activeOutputSramMem
            if (addr < outputJointSramMem.length){
              outputJointSramMem(addr) = unpackWrite(dataBusVal)
              trace(s"outputJointSram write: addr=$addr, data=${outputJointSramMem(addr).mkString(", ")}")
            }
            else {
              trace(s"outputJointSram write: addr=$addr, data=out of range")
            }
          }
          if (dut.io.jointSram.writeEnable.peek().litToBoolean) {
            val addr = dut.io.jointSram.writeAddress.peek().litValue.toInt
            val dataBusVal = dut.io.jointSram.writeData.peek().litValue
            if (addr < jointSramMem.length) jointSramMem(addr) = unpackWrite(dataBusVal)
            trace(s"jointSram write: addr=$addr, data=${jointSramMem(addr).mkString(", ")}")
          }

          def packRead(vec: Array[Int], elemW: Int): BigInt = {
            var packed = BigInt(0)
            for (i <- 0 until colSize) {
              val v = BigInt(vec(i)) & ((BigInt(1) << elemW) - 1)
              packed |= (v << (i * elemW))
            }
            packed
          }
          // ---------- output/joint  ----------
          // 1. Q2 输出到 DUT (先输出)
          if (oPingQ2.nonEmpty) {
            val req = oPingQ2.dequeue()
            dut.io.outputSramPing.readData.poke(packRead(req.data, Config.outputBufferTmpWidth).U)
            trace(s"outputSramPing read: addr=${req.addr}, data=${req.data.mkString(", ")}")
          }
          if (oPongQ2.nonEmpty) {
            val req = oPongQ2.dequeue()
            dut.io.outputSramPong.readData.poke(packRead(req.data, Config.outputBufferTmpWidth).U)
            trace(s"outputSramPong read: addr=${req.addr}, data=${req.data.mkString(", ")}")
          }
          if (oJointQ2.nonEmpty) {
            val req = oJointQ2.dequeue()
            dut.io.outputJointSram.readData.poke(packRead(req.data, Config.outputBufferTmpWidth).U)
            trace(s"outputJointSram read: addr=${req.addr}, data=${req.data.mkString(", ")}")
          }
          if (jointQ2.nonEmpty) {
            val req = jointQ2.dequeue()
            dut.io.jointSram.readData.poke(packRead(req.data, Config.outputBufferTmpWidth).U)
            trace(s"jointSram read: addr=${req.addr}, data=${req.data.mkString(", ")}")
          }
          
          // 2. 推进队列：Q1->Q2 (然后推进)
          if (oPingQ1.nonEmpty) oPingQ2.enqueue(oPingQ1.dequeue())
          if (oPongQ1.nonEmpty) oPongQ2.enqueue(oPongQ1.dequeue())
          if (oJointQ1.nonEmpty) oJointQ2.enqueue(oJointQ1.dequeue())
          if (jointQ1.nonEmpty) jointQ2.enqueue(jointQ1.dequeue())
          
          // 3. dut.io->Q1 (最后接收新请求)
          if (dut.io.outputJointSram.readEnable.peek().litToBoolean) {
            val addr = dut.io.outputJointSram.readAddress.peek().litValue.toInt
            val vec = if (addr < outputJointSramMem.length) outputJointSramMem(addr) else Array.fill(colSize)(0)
            oJointQ1.enqueue(SramReadRequest(addr, vec))
          }
          if (dut.io.jointSram.readEnable.peek().litToBoolean) {
            val addr = dut.io.jointSram.readAddress.peek().litValue.toInt
            val vec = if (addr < jointSramMem.length) jointSramMem(addr) else Array.fill(colSize)(0)
            jointQ1.enqueue(SramReadRequest(addr, vec))
          }
          
          if (dut.io.outputSramPing.readEnable.peek().litToBoolean) {
            val addr = dut.io.outputSramPing.readAddress.peek().litValue.toInt
            val vec = if (addr < outputSramPingMem.length) outputSramPingMem(addr) else Array.fill(colSize)(0)
            oPingQ1.enqueue(SramReadRequest(addr, vec))
          }
          if (dut.io.outputSramPong.readEnable.peek().litToBoolean) {
            val addr = dut.io.outputSramPong.readAddress.peek().litValue.toInt
            val vec = if (addr < outputSramPongMem.length) outputSramPongMem(addr) else Array.fill(colSize)(0)
            oPongQ1.enqueue(SramReadRequest(addr, vec))
          }

          dut.clock.step(1)
          elapsedCycles += 1
          errorObserved ||= dut.io.interrupts.errorInterrupt.peek().litToBoolean
          if (dut.io.interrupts.doneInterrupt.peek().litToBoolean) {
            localDone = true
            trace(s"MacMachineWrapper done interrupt triggered after ${elapsedCycles} cycles")
          }
          trace("--------------------------------")
        }

        assert(!errorObserved,
          s"MacMachineWrapper raised errorInterrupt after ${elapsedCycles} cycles")
        assert(localDone,
          s"MacMachineWrapper timed out after ${maxRunCycles} cycles; " +
            s"doneInterrupt=${dut.io.interrupts.doneInterrupt.peek().litToBoolean}")

        // 清中断
        writeConfig(dut, 1, Config.interruptFreshId)
        dut.clock.step(1)
      }

      // 3D 覆盖：rowIdx -> colIdx -> cinIdx，与 MacMachineTest 相同
      if(dataFlowMode == 0) {
        for (resolutionRowIdx <- 0 until resolutionRowIdxTotal) {
          for (resolutionColIdx <- 0 until resolutionColIdxTotal) {
            planeWorkMode = 0
            if (resolutionRowIdx == 0) {
              if (resolutionColIdx == 0) {
                planeWorkMode = 0
              } else {
                planeWorkMode = 4
              }
            } else {
              if (resolutionColIdx == 0) {
                planeWorkMode = 1
              } else {
                planeWorkMode = 2
              }
            }
            runProcess(k, cout, 0, groupNum, groupSize, stride, planeWorkMode, resolutionColIdx, resolutionRowIdx, 0, 0)
            planeWorkMode = 3
            for (cinIdx <- 1 until cinIdxTotal) {
              runProcess(k, cout, cinIdx, groupNum, groupSize, stride, planeWorkMode, resolutionColIdx, resolutionRowIdx, 0, 0)
            }

            // 结束时不应有 error 中断
            assert(!dut.io.interrupts.errorInterrupt.peek().litToBoolean, "MacMachineWrapper error信号不应为高")

            // 导出与合并结果（与 MacMachineTest 对齐）
            // 选择当前激活的 outputsram 导出
            // 打印当前乒乓sram的选择情况
            if (!outputPingpongFlag) {
              trace("当前使用的是乒outputSram")
            } else {
              trace("当前使用的是乓outputSram")
            }
                      
            DataConverter.printOutputSramResults(
              activeOutputSramMem,
              new File("test_run_dir/MacMachine/MacMachineWrapper_basic/actual_output_results.csv").getAbsolutePath,
              cout = cout,
              k = k,
              groupNum = groupNum,
              colSize = colSize,
              resolutionColIdx = resolutionColIdx,
              resolutionRowIdx = resolutionRowIdx
            )
            DataConverter.printJointSramData(
              jointSramMem,
              new File("test_run_dir/MacMachine/MacMachineWrapper_basic/actual_joint_results.csv").getAbsolutePath,
              cout = cout,
              k = k,
              colSize = colSize
            )

          }
        }
      }
      else{
        for (kyIdx <- 0 until nvdlaKx) {
          for (kxIdx <- 0 until nvdlaKy) {
            runProcess(k, cout, 0, groupNum, groupSize, stride, 3, 0, 0, kxIdx, kyIdx)// 默认Router为补齐模式
          }
        }
      }
    }
  }
}


