import chisel3._
import chisel3.util._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec
import scala.util.Random
import FLOOD_Accelerator.core.MACTreeRefine
import scala.math._
import firrtl.options.TargetDirAnnotation
import FLOOD_Accelerator.core.Config

class MACTreeRefineSpecNew extends AnyFlatSpec with ChiselScalatestTester {
  
  behavior of "MACTreeRefine"
  
  // 测试函数：用于验证MAC结果
  def verifyMACResult(dut: MACTreeRefine, inputsA: Seq[Int], inputsB: Seq[Int]): Unit = {
    val dataWidth = Config.dataWidth
    val outputWidth = Config.outputWidth
    val paral = Config.rowSize

    // 预期结果计算: 所有对应元素的乘积之和
    val expectedResult = inputsA.zip(inputsB).map { case (a, b) => a * b }.sum
    
    // 调整为输出位宽
    val expectedTruncated = expectedResult >> (dut.tmpDataWidth - dut.outputWidth)
    
    // 发送输入
    dut.io.inB.valid.poke(true.B)
    for (i <- 0 until dut.paral) {
      dut.io.inA(i).poke(inputsA(i).S)
      dut.io.inB.bits(i).poke(inputsB(i).S)
    }
    
    // 等待ready信号
    while (!dut.io.inB.ready.peek().litToBoolean) {
      dut.clock.step(1)
    }
    
    // 传输数据
    dut.clock.step(1)
    dut.io.inB.valid.poke(false.B)
    
    // 等待结果有效
    while (!dut.io.out.valid.peek().litToBoolean) {
      dut.clock.step(1)
    }
    
    // 验证结果
    dut.io.out.bits.expect(expectedTruncated.S)
    
    // 读取结果
    dut.io.out.ready.poke(true.B)
    dut.clock.step(1)
    dut.io.out.ready.poke(false.B)
  }
  
  
  it should "correctly compute MAC with pipeline=1" in {
    test(new MACTreeRefine()).withAnnotations(Seq(WriteVcdAnnotation, 
                          TargetDirAnnotation("test_run_dir/MACTreeRefine/MACTreeRefine_should_correctly_compute_MAC_with_pipeline_1"))) { dut =>
      // 随机生成测试数据
      val rng = new Random(42)
      val maxVal = +4
      val minVal = -4
      
      for (_ <- 0 until dut.paral) {  // 进行10次测试
        val inputsA = Seq.fill(dut.paral)(minVal + rng.nextInt(maxVal - minVal + 1))
        val inputsB = Seq.fill(dut.paral)(minVal + rng.nextInt(maxVal - minVal + 1))
        
        // 验证MAC结果
        verifyMACResult(dut, inputsA, inputsB)
      }
    }
  }
  
  it should "correctly compute MAC with pipeline=2" in {
    test(new MACTreeRefine()).withAnnotations(Seq(WriteVcdAnnotation, 
                          TargetDirAnnotation("test_run_dir/MACTreeRefine/MACTreeRefine_should_correctly_compute_MAC_with_pipeline_2"))) { dut =>
      // 随机生成测试数据
      val rng = new Random(42)
      val maxVal = (1 << (dut.dataWidth - 1)) - 1
      val minVal = -(1 << (dut.dataWidth - 1))
      
      for (_ <- 0 until dut.paral) {  // 进行10次测试
        val inputsA = Seq.fill(dut.paral)(minVal + rng.nextInt(maxVal - minVal + 1))
        val inputsB = Seq.fill(dut.paral)(minVal + rng.nextInt(maxVal - minVal + 1))
        
        // 验证MAC结果
        verifyMACResult(dut, inputsA, inputsB)
      }
    }
  }
  
  it should "correctly compute MAC with pipeline=3" in {
    test(new MACTreeRefine()).withAnnotations(Seq(WriteVcdAnnotation, 
                          TargetDirAnnotation("test_run_dir/MACTreeRefine/MACTreeRefine_should_correctly_compute_MAC_with_pipeline_3"))) { dut =>
      // 随机生成测试数据
      val rng = new Random(42)
      val maxVal = (1 << (dut.dataWidth - 1)) - 1
      val minVal = -(1 << (dut.dataWidth - 1))
      
      for (_ <- 0 until 5) {  // 进行5次测试
        val inputsA = Seq.fill(dut.paral)(minVal + rng.nextInt(maxVal - minVal + 1))
        val inputsB = Seq.fill(dut.paral)(minVal + rng.nextInt(maxVal - minVal + 1))
        
        // 验证MAC结果
        verifyMACResult(dut, inputsA, inputsB)
      }
    }
  }
  
  it should "process streaming data correctly" in {
    test(new MACTreeRefine()).withAnnotations(Seq(WriteVcdAnnotation, 
                          TargetDirAnnotation("test_run_dir/MACTreeRefine/MACTreeRefine_should_process_streaming_data_correctly"))) { dut =>
      // 使用固定种子的随机数生成器
      val rng = new Random(42)
      val maxVal = (1 << (dut.dataWidth - 1)) - 1
      val minVal = -(1 << (dut.dataWidth - 1))
      
      // 准备多组测试数据
      val numTestCases = 10
      val testCases = Seq.fill(numTestCases) {
        (Seq.fill(dut.paral)(minVal + rng.nextInt(maxVal - minVal + 1)), 
         Seq.fill(dut.paral)(minVal + rng.nextInt(maxVal - minVal + 1)))
      }
      
      // 计算预期的结果
      val expectedResults = testCases.map { case (inputsA, inputsB) =>
        // 预期结果计算，并去除无关bit
        (inputsA.zip(inputsB).map { case (a, b) => a * b }.sum) >> (dut.tmpDataWidth - dut.outputWidth)
      }
      
      // 并行输入/输出处理
      val inputThread = fork {
        for (((inputsA, inputsB), idx) <- testCases.zipWithIndex) {       
          // 等待ready信号并传输数据
          while (!dut.io.inB.ready.peek().litToBoolean) {
            dut.clock.step(1)
          }
          // 发送输入
          dut.io.inB.valid.poke(true.B)
          for (i <- 0 until dut.paral) {
            dut.io.inA(i).poke(inputsA(i).S)
            dut.io.inB.bits(i).poke(inputsB(i).S)
          }
          dut.clock.step(1)
          dut.io.inB.valid.poke(false.B)
          
          // 在连续测试用例之间添加一些随机延迟
          val randomDelay = rng.nextInt(3)
          if (randomDelay > 0) dut.clock.step(randomDelay)
        }
        // 移除 tLatency 相关等待
        // 只需等待足够时间让流水线排空
        for (_ <- 0 until (dut.pipeline + 1) * 2) {
          dut.clock.step(1)
        }
      }
      
      val outputThread = fork {
        for (i <- 0 until numTestCases) {
          // 默认不准备接收数据
          dut.io.out.ready.poke(false.B)
          
          // 等待valid信号
          while (!dut.io.out.valid.peek().litToBoolean) {
            dut.clock.step(1)
          }
          
          // 验证结果
          val result = dut.io.out.bits.peek().litValue().toInt
          dut.io.out.bits.expect(expectedResults(i).S)
          
          // 接收数据
          dut.io.out.ready.poke(true.B)
          dut.clock.step(1)
          dut.io.out.ready.poke(false.B)
          
          // 随机延迟
          val randomDelay = rng.nextInt(3)
          if (randomDelay > 0) dut.clock.step(randomDelay)
        }
      }
      
      // 等待两个线程完成
      inputThread.join()
      outputThread.join()
    }
  }
  
  it should "handle random ready/valid delays" in {
    test(new MACTreeRefine()).withAnnotations(Seq(WriteVcdAnnotation, 
                          TargetDirAnnotation("test_run_dir/MACTreeRefine/MACTreeRefine_should_handle_random_ready_valid_delays"))) { dut =>
      val rng = new Random(44)
      val maxVal = 5
      val minVal = -5
      
      // 准备测试数据
      val numTestCases = 8
      val testCases = Seq.fill(numTestCases) {
        (Seq.fill(dut.paral)(minVal + rng.nextInt(maxVal - minVal + 1)), 
         Seq.fill(dut.paral)(minVal + rng.nextInt(maxVal - minVal + 1)))
      }
      
      // 计算期望结果
      val expectedResults = testCases.map { case (inputsA, inputsB) =>
        // 预期结果计算，并去除无关bit
        (inputsA.zip(inputsB).map { case (a, b) => a * b }.sum) >> (dut.tmpDataWidth - dut.outputWidth)
      }
      
      // 用于跟踪已发送和已接收的数据
      var sentCount = 0
      var receivedCount = 0
      
      // 输入线程：随机发送数据
      val inputThread = fork {
        while (sentCount < numTestCases) {
          // 随机决定是否发送
          if (rng.nextBoolean()) {
            val (inputsA, inputsB) = testCases(sentCount)
            
            // 等待ready信号并传输数据
            while (!dut.io.inB.ready.peek().litToBoolean) {
              dut.clock.step(1)
            }
            // 发送输入
            dut.io.inB.valid.poke(true.B)
            for (i <- 0 until dut.paral) {
              dut.io.inA(i).poke(inputsA(i).S)
              dut.io.inB.bits(i).poke(inputsB(i).S)
            }
            dut.clock.step(1)
            dut.io.inB.valid.poke(false.B)
            sentCount += 1
          } else {
            // 随机延迟，不发送数据
            val randomDelay = rng.nextInt(3)
            if (randomDelay > 0) dut.clock.step(randomDelay)
          }
        }
        // 移除 tLatency 相关等待
        // 只需等待足够时间让流水线排空
        for (_ <- 0 until (dut.pipeline + 1) * 2) {
          dut.clock.step(1)
        }
      }
      
      // 输出线程：随机接收数据
      val outputThread = fork {
        while (receivedCount < numTestCases) {
          // 随机决定是否准备接收
          val willReceive = rng.nextBoolean()
          dut.io.out.ready.poke(willReceive.B)
          
          // 如果数据有效且我们准备好接收
          if (dut.io.out.valid.peek().litToBoolean && willReceive) {
            // 验证结果
            dut.io.out.bits.expect(expectedResults(receivedCount).S)
            receivedCount += 1
          }
          
          dut.clock.step(1)
        }
        
        // 确保最后一个cycle的ready信号为false
        dut.io.out.ready.poke(false.B)
      }
      
      // 等待两个线程完成
      inputThread.join()
      outputThread.join()
    }
  }
} 