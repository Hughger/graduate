import chisel3._
import chisel3.util._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec
import scala.util.Random
import FLOOD_Accelerator.core.CIMCore
import scala.math._
import firrtl.options.TargetDirAnnotation

class CIMCoreSpec extends AnyFlatSpec with ChiselScalatestTester {
  
  behavior of "CIMCore"

  // 辅助函数：更新权重到指定的buffer组
  def updateWeights(
    dut: CIMCore,
    weights: Seq[Seq[Int]], // rowSize x colSize的权重矩阵
    isPing: Boolean // true表示写入ping buffer，false表示写入pong buffer
  ): Unit = {
    // 初始化信号
    dut.io.writeWeightEnable.poke(false.B)
    dut.io.pingpong.poke(isPing.B)
    dut.clock.step(1)
    
    // 写入权重
    dut.io.writeWeightEnable.poke(true.B)
    var address = 0
    for (row <- 0 until dut.rowSize) {
      val rowData = weights(row)
      var dataIndex = 0
      while (dataIndex < rowData.length * dut.dataWidth) {
        val dataToWrite = rowData.slice(
          dataIndex / dut.dataWidth,
          (dataIndex + dut.weightBandWidth) / dut.dataWidth
        ).foldLeft(0) { (acc, value) =>
          (acc << dut.dataWidth) | (value & ((1 << dut.dataWidth) - 1))
        }
        dut.io.writeWeightAddress.poke(address.U)
        dut.io.writeWeightData.poke(dataToWrite.U)
        dut.clock.step(1)
        dataIndex += dut.weightBandWidth
        address += 1
      }
    }
    dut.io.writeWeightEnable.poke(false.B)
    
    // 等待权重写入完成
    dut.clock.step(5)
  }

  // 辅助函数：发送输入向量并验证输出
  def processVector(
    dut: CIMCore,
    inputs: Seq[Int],       // rowSize大小的输入向量
    expectedOutputs: Seq[Int], // colSize大小的期望输出向量
    useWeightsFromPing: Boolean // true表示使用ping buffer的权重，false表示使用pong buffer的权重
  ): Unit = {
    // 直接设置pingpong信号，而不是取反
    dut.io.pingpong.poke(useWeightsFromPing.B)
    dut.clock.step(5)

    // 发送输入向量
    dut.io.vectorIn.valid.poke(true.B)
    for (i <- 0 until dut.rowSize) {
      dut.io.vectorIn.bits(i).poke(inputs(i).S)
    }

    // 等待ready信号
    while (!dut.io.vectorIn.ready.peek().litToBoolean) {
      dut.clock.step(1)
    }
    
    dut.clock.step(1)
    dut.io.vectorIn.valid.poke(false.B)
    
    // 等待结果有效
    dut.io.vectorOut.ready.poke(true.B)
    while (!dut.io.vectorOut.valid.peek().litToBoolean) {
      dut.clock.step(1)
    }
    
    // 验证每个输出
    for (i <- 0 until dut.colSize) {
      dut.io.vectorOut.bits(i).expect(expectedOutputs(i).S)
    }
    
    dut.clock.step(1)
    dut.io.vectorOut.ready.poke(false.B)
  }

  // 基本功能测试
  it should "correctly compute matrix-vector multiplication" in {
    test(new CIMCore(
      rowSize = 2,
      colSize = 2,
      dataWidth = 8,
      outputWidth = 16,
      weightBandWidth = 8,
      pipeline = 1,
      tLatency = 2
    )).withAnnotations(Seq(WriteVcdAnnotation, 
      TargetDirAnnotation("test_run_dir/CIMCore/CIMCore_should_correctly_compute_matrix_vector_multiplication"))) { dut =>
      
      val rng = new Random(42)
      val maxVal = 4
      val minVal = -4

      // 生成测试数据
      val weights = Seq.fill(dut.rowSize)(Seq.fill(dut.colSize)(minVal + rng.nextInt(maxVal - minVal + 1)))
      val inputs = Seq.fill(dut.rowSize)(minVal + rng.nextInt(maxVal - minVal + 1))

      // 计算期望输出
      val expectedOutputs = (0 until dut.colSize).map { col =>
        // 计算该列的乘累加结果
        val result = (0 until dut.rowSize).map { row =>
          weights(row)(col) * inputs(row)
        }.sum
        // 使用与MACTree相同的截断方式
        result >> ((2 * dut.dataWidth + log2Floor(dut.rowSize)) - dut.outputWidth)
      }

      // 1. 先写入权重到ping buffer
      updateWeights(dut, weights, isPing = true)
      
      // 2. 切换pingpong信号以读取ping buffer
      dut.io.pingpong.poke(false.B)  // 切换到读取ping buffer
      dut.clock.step(5)  // 等待切换完成

      // 3. 发送输入向量
      dut.io.vectorIn.valid.poke(true.B)
      for (i <- 0 until dut.rowSize) {
        dut.io.vectorIn.bits(i).poke(inputs(i).S)
      }

      // 4. 等待ready信号
      while (!dut.io.vectorIn.ready.peek().litToBoolean) {
        dut.clock.step(1)
      }
      
      dut.clock.step(1)
      dut.io.vectorIn.valid.poke(false.B)
      
      // 5. 等待结果有效
      dut.io.vectorOut.ready.poke(true.B)
      while (!dut.io.vectorOut.valid.peek().litToBoolean) {
        dut.clock.step(1)
      }
      
      // 6. 验证输出
      for (i <- 0 until dut.colSize) {
        dut.io.vectorOut.bits(i).expect(expectedOutputs(i).S)
      }
      
      dut.clock.step(1)
      dut.io.vectorOut.ready.poke(false.B)
    }
  }

  // 流水线测试
  it should "process streaming data correctly" in {
    test(new CIMCore(
      rowSize = 4,
      colSize = 4,
      dataWidth = 8,
      outputWidth = 16,
      weightBandWidth = 8,
      pipeline = 2,
      tLatency = 2
    )).withAnnotations(Seq(WriteVcdAnnotation, 
                          TargetDirAnnotation("test_run_dir/CIMCore/CIMCore_should_process_streaming_data_correctly"))) { dut =>
      
      val rng = new Random(42)
      val maxVal = 4
      val minVal = -4

      // 1. 生成权重矩阵并写入到ping buffer
      val weights = Seq.fill(dut.rowSize)(Seq.fill(dut.colSize)(minVal + rng.nextInt(maxVal - minVal + 1)))
      updateWeights(dut, weights, isPing = true)

      // 2. 切换pingpong信号以读取ping buffer
      dut.io.pingpong.poke(false.B)
      dut.clock.step(5)

      // 准备多组测试数据
      val numTestCases = 10
      val testInputs = Seq.fill(numTestCases)(
        Seq.fill(dut.rowSize)(minVal + rng.nextInt(maxVal - minVal + 1))
      )

      // 计算期望输出
      val expectedOutputs = testInputs.map { inputs =>
        (0 until dut.colSize).map { col =>
          val result = (0 until dut.rowSize).map { row =>
            weights(row)(col) * inputs(row)
          }.sum
          result >> ((2 * dut.dataWidth + log2Floor(dut.rowSize)) - dut.outputWidth)
        }
      }

      // 输入线程
      val inputThread = fork {
        for ((inputs, idx) <- testInputs.zipWithIndex) {
          // 等待ready信号
          while (!dut.io.vectorIn.ready.peek().litToBoolean) {
            dut.clock.step(1)
          }

          // 发送输入
          dut.io.vectorIn.valid.poke(true.B)
          for (i <- 0 until dut.rowSize) {
            dut.io.vectorIn.bits(i).poke(inputs(i).S)
          }
          dut.clock.step(1)
          dut.io.vectorIn.valid.poke(false.B)

          // 随机延迟
          val randomDelay = rng.nextInt(3)
          if (randomDelay > 0) dut.clock.step(randomDelay)
        }
        dut.clock.step(10)
      }

      // 输出线程
      val outputThread = fork {
        for (i <- 0 until numTestCases) {
          // 等待valid信号
          while (!dut.io.vectorOut.valid.peek().litToBoolean) {
            dut.clock.step(1)
          }

          // 验证结果
          for (j <- 0 until dut.colSize) {
            dut.io.vectorOut.bits(j).expect(expectedOutputs(i)(j).S)
          }

          // 接收数据
          dut.io.vectorOut.ready.poke(true.B)
          dut.clock.step(1)
          dut.io.vectorOut.ready.poke(false.B)
        }
      }

      // 等待两个线程完成
      inputThread.join()
      outputThread.join()
    }
  }

  // 乒乓切换测试
  it should "handle pingpong buffer switching correctly" in {
    test(new CIMCore(
      rowSize = 4,
      colSize = 4,
      dataWidth = 8,
      outputWidth = 16,
      weightBandWidth = 8,
      pipeline = 2,
      tLatency = 2
    )).withAnnotations(Seq(WriteVcdAnnotation, 
                          TargetDirAnnotation("test_run_dir/CIMCore/CIMCore_should_handle_pingpong_buffer_switching_correctly"))) { dut =>
      
      val rng = new Random(42)
      val maxVal = 4
      val minVal = -4

      // 生成两组不同的权重矩阵
      val weights1 = Seq.fill(dut.rowSize)(Seq.fill(dut.colSize)(minVal + rng.nextInt(maxVal - minVal + 1)))
      val weights2 = Seq.fill(dut.rowSize)(Seq.fill(dut.colSize)(minVal + rng.nextInt(maxVal - minVal + 1)))
      val inputs = Seq.fill(dut.rowSize)(minVal + rng.nextInt(maxVal - minVal + 1))

      // 计算两组期望输出
      val expectedOutputs1 = (0 until dut.colSize).map { col =>
        val result = (0 until dut.rowSize).map { row =>
          weights1(row)(col) * inputs(row)
        }.sum
        result >> ((2 * dut.dataWidth + log2Floor(dut.rowSize)) - dut.outputWidth)
      }

      val expectedOutputs2 = (0 until dut.colSize).map { col =>
        val result = (0 until dut.rowSize).map { row =>
          weights2(row)(col) * inputs(row)
        }.sum
        result >> ((2 * dut.dataWidth + log2Floor(dut.rowSize)) - dut.outputWidth)
      }

      // 1. 写入第一组权重到ping buffer
      updateWeights(dut, weights1, isPing = true)
      
      // 2. 切换pingpong信号以读取ping buffer
      dut.io.pingpong.poke(false.B)
      dut.clock.step(5)
      
      // 3. 使用第一组权重进行计算
      dut.io.vectorIn.valid.poke(true.B)
      for (i <- 0 until dut.rowSize) {
        dut.io.vectorIn.bits(i).poke(inputs(i).S)
      }
      while (!dut.io.vectorIn.ready.peek().litToBoolean) {
        dut.clock.step(1)
      }
      dut.clock.step(1)
      dut.io.vectorIn.valid.poke(false.B)

      // 等待并验证第一组结果
      while (!dut.io.vectorOut.valid.peek().litToBoolean) {
        dut.clock.step(1)
      }
      for (i <- 0 until dut.colSize) {
        dut.io.vectorOut.bits(i).expect(expectedOutputs1(i).S)
      }
      dut.io.vectorOut.ready.poke(true.B)
      dut.clock.step(1)
      dut.io.vectorOut.ready.poke(false.B)

      // 4. 写入第二组权重到pong buffer
      updateWeights(dut, weights2, isPing = false)
      
      // 5. 切换pingpong信号以读取pong buffer
      dut.io.pingpong.poke(true.B)
      dut.clock.step(5)
      
      // 6. 使用第二组权重进行计算
      dut.io.vectorIn.valid.poke(true.B)
      for (i <- 0 until dut.rowSize) {
        dut.io.vectorIn.bits(i).poke(inputs(i).S)
      }
      while (!dut.io.vectorIn.ready.peek().litToBoolean) {
        dut.clock.step(1)
      }
      dut.clock.step(1)
      dut.io.vectorIn.valid.poke(false.B)

      // 等待并验证第二组结果
      while (!dut.io.vectorOut.valid.peek().litToBoolean) {
        dut.clock.step(1)
      }
      for (i <- 0 until dut.colSize) {
        dut.io.vectorOut.bits(i).expect(expectedOutputs2(i).S)
      }
      dut.io.vectorOut.ready.poke(true.B)
      dut.clock.step(1)
      dut.io.vectorOut.ready.poke(false.B)

      // 7. 切换回ping buffer并验证第一组权重还在
      dut.io.pingpong.poke(false.B)
      dut.clock.step(5)
      
      dut.io.vectorIn.valid.poke(true.B)
      for (i <- 0 until dut.rowSize) {
        dut.io.vectorIn.bits(i).poke(inputs(i).S)
      }
      while (!dut.io.vectorIn.ready.peek().litToBoolean) {
        dut.clock.step(1)
      }
      dut.clock.step(1)
      dut.io.vectorIn.valid.poke(false.B)

      // 等待并验证结果
      while (!dut.io.vectorOut.valid.peek().litToBoolean) {
        dut.clock.step(1)
      }
      for (i <- 0 until dut.colSize) {
        dut.io.vectorOut.bits(i).expect(expectedOutputs1(i).S)
      }
      dut.io.vectorOut.ready.poke(true.B)
      dut.clock.step(1)
      dut.io.vectorOut.ready.poke(false.B)
    }
  }
}
