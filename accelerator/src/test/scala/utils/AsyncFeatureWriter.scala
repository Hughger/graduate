package FLOOD_Accelerator.utils

import chisel3._
import chiseltest._
import FLOOD_Accelerator.core.Config
import FLOOD_Accelerator.machine.MacMachine

import scala.math._

object AsyncFeatureWriter {
  // 全局总线写入锁，避免多个并发线程在同一时刻对同一IO进行poke导致冲突
  private object FeatureBusLock

  // 私有：顺序写入某个 tile 的全部特征图
  private def writeTileSequential(
    dut: MacMachine,
    tileId: Int,
    fullFeatureMapMatrix: Array[Array[Int]]
  ): Unit = {
    val rowSize = Config.rowSize
    val colSize = Config.colSize
    val featureMapBandWidth = Config.featureMapBandWidth
    val dataWidth = Config.dataWidth

    val writesPerRow = ceil(colSize * dataWidth.toDouble / featureMapBandWidth.toDouble).toInt
    val elementPerWrite = featureMapBandWidth / dataWidth
    val startRow = tileId * rowSize

    var r = 0
    while (r < rowSize) {
      var c = 0
      while (c < writesPerRow) {
        val startCol = c * elementPerWrite
        val endCol = Math.min((c + 1) * elementPerWrite, colSize)

        val featureMapValues = (startCol until endCol).map { col =>
          fullFeatureMapMatrix(startRow + r)(col)
        }

        val addr = r * writesPerRow + c

        var packedData = BigInt(0)
        var i = 0
        while (i < featureMapValues.length) {
          val featureMapValue = featureMapValues(i)
          val shiftedValue = (BigInt(featureMapValue) & ((BigInt(1) << dataWidth) - 1)) << (i * dataWidth)
          packedData |= shiftedValue
          i += 1
        }

        FeatureBusLock.synchronized {
          dut.io.featureMapBus.tileId.poke(tileId.U)
          dut.io.featureMapBus.addr.poke(addr.U)
          dut.io.featureMapBus.data.poke(packedData.U(featureMapBandWidth.W))
          dut.clock.step(1)
        }

        c += 1
      }
      r += 1
    }
  }

  // 异步写入单个特征图字
  def writeFeatureMapWordAsync(
    dut: MacMachine,
    tileId: Int,
    addr: Int,
    data: BigInt
  ) = {
    fork {
      FeatureBusLock.synchronized {
        dut.io.featureMapBus.tileId.poke(tileId.U)
        dut.io.featureMapBus.addr.poke(addr.U)
        dut.io.featureMapBus.data.poke(data.U(Config.featureMapBandWidth.W))
        dut.clock.step(1)
      }
    }
  }

  // 异步批量写入：将指定 tile 的特征图矩阵写入 SRAM
  def writeFeatureMapMatrixAsync(
    dut: MacMachine,
    tileId: Int,
    fullFeatureMapMatrix: Array[Array[Int]]
  ) = {
    fork {
      writeTileSequential(dut, tileId, fullFeatureMapMatrix)
    }
  }

  // 异步批量写入：写入所有 tile 的特征图
  def writeAllTilesAsync(
    dut: MacMachine,
    fullFeatureMapMatrix: Array[Array[Int]]
  ) = {
    val worker = fork {
      var t = 0
      while (t < Config.tileSize) {
        writeTileSequential(dut, t, fullFeatureMapMatrix)
        t += 1
      }
    }
    Seq(worker)
  }
}

