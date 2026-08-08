# MACTreeFlood 单级流水修复 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 使 `MACTreeFlood(pipeline = 1)` 完成合法的时分复用乘加并输出量化结果，不再在 elaboration 阶段访问不存在的第二级流水状态。

**Architecture:** 在 `MACTreeFlood` 内以 Scala elaboration-time 的 `if (pipeline == 1)` 分出单级状态机；该分支只使用第 0 级状态、输入 B 寄存器、累加寄存器和既有输出 FIFO。现有 `pipeline >= 2` 多级路径保持逻辑不变，端口与默认 `Config` 不变。

**Tech Stack:** Scala 2.12.13、Chisel 3.5.3、chiseltest、SBT 2.0.6、Temurin JDK 17。

## Global Constraints

- `MACTreeFlood` 的公开参数契约仍为 `pipeline >= 1`。
- 默认 `Config.pipeline = 2`、`Config.tLatency = 4` 与 AXKU15 设计参数不得修改。
- `pipeline == 1` 的 elaborated 硬件不得引用 `stageStates(1)`、`stageCounters(1)` 或 `stageRegistersOut(1)`。
- `pipeline >= 2` 的既有多级流水 RTL 不得改变。
- 不修改 `MACTreeRefine`、MacMachineWrapper 或 SBT/JVM 全局配置；wrapper OOM 与 SBT JAR 替换问题不属于本任务。
- 测试命令使用前台 SBT：`sbt --server --no-colors`；若先于测试出现 Windows JAR `AccessDeniedException`，记录为环境阻塞，不能标记 RTL 验证为通过。

---

## File Structure

- `accelerator/src/main/scala/core/CIMcore.scala`：`MACTreeFlood` 的参数化状态机；新增单级专用 elaboration 分支并保留多级代码。
- `accelerator/src/test/scala/core/CIMCoreTest.scala`：已有 `CIMCoreSpec` 的 `pipeline = 1` 矩阵向量 golden 回归；仅在必要时将其测试名称明确为单级回归，不改变 golden 数据语义。

### Task 1: Repair and Verify the Single-Stage MACTreeFlood Path

**Files:**
- Modify: `accelerator/src/main/scala/core/CIMcore.scala:301-502`
- Modify only if needed for an explicit regression name: `accelerator/src/test/scala/core/CIMCoreTest.scala:86-151`

**Interfaces:**
- Consumes: `MACTreeFlood(paral, dataWidth, outputWidth, pipeline, tLatency)` and its existing `io.inA`, `io.inB`, `io.out` ports.
- Produces: the same `Decoupled[SInt]` result for `pipeline = 1`; `CIMCore` continues to collect one result from each column MAC into `io.vectorOut`.

- [ ] **Step 1: Establish the RED regression using the existing real golden test**

The existing first `CIMCoreSpec` case constructs:

```scala
test(new CIMCore(
  rowSize = 2,
  colSize = 2,
  dataWidth = 8,
  outputWidth = 16,
  weightBandWidth = 8,
  pipeline = 1,
  tLatency = 2
))
```

It writes a deterministic `2 x 2` weight matrix, supplies a deterministic two-element vector, and checks both matrix-vector outputs. Do not weaken it or change its golden calculations.

- [ ] **Step 2: Run the RED regression and verify the expected failure**

Run from `accelerator/` after shutting down any old SBT server:

```powershell
& 'C:\Program Files (x86)\sbt\bin\sbt.bat' shutdown
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.20.8-hotspot'
$env:JAVA_OPTS = '-Xms1G -Xmx8G -Xss4M -XX:ReservedCodeCacheSize=128m'
& 'C:\Program Files (x86)\sbt\bin\sbt.bat' --server --no-colors 'testOnly CIMCoreSpec'
```

Expected before the RTL change: `java.lang.IndexOutOfBoundsException: 1` at the `MACTreeFlood` first-stage handoff, because `pipeline = 1` creates only index 0.

- [ ] **Step 3: Add the minimal single-stage elaboration branch**

In `MACTreeFlood`, replace the unconditional first-stage/middle-stage/final-stage block with an elaboration-time branch:

```scala
if (pipeline == 1) {
  switch(stageStates(0)) {
    is(idle) {
      stageCounters(0) := 0.U
      when(io.inB.fire) {
        inputBReg := io.inB.bits
        accReg := 0.S
        stageStates(0) := computing
      }
    }
    is(computing) {
      val processInThisCycle = paral / tLatency
      when(stageCounters(0) < tLatency.U) {
        val baseIdx = (processInThisCycle.U * stageCounters(0))(log2Ceil(paral) - 1, 0)
        val partialSum = VecInit((0 until processInThisCycle).map { offset =>
          io.inA(baseIdx + offset.U) * inputBReg(baseIdx + offset.U)
        }).reduce(_ +& _)
        when(stageCounters(0) === 0.U) {
          accReg := partialSum.asSInt
        }.otherwise {
          accReg := (accReg + partialSum).asSInt
        }
        stageCounters(0) := stageCounters(0) + 1.U
      }.otherwise {
        outputFifo.io.enq.bits := accReg(tmpDataWidth - 1, tmpDataWidth - outputWidth).asSInt
        outputFifo.io.enq.valid := true.B
        stageStates(0) := outputting
      }
    }
    is(outputting) {
      when(outputFifo.io.enq.ready) {
        stageStates(0) := idle
      }
    }
  }
} else {
  // Preserve the pre-existing first/middle/final multi-stage state-machine code verbatim.
}
```

Keep the existing output FIFO wiring and `io.inB.ready := stageStates(0) === idle` after the branch. Do not add a second-stage access anywhere in the `pipeline == 1` branch.

- [ ] **Step 4: Run the focused GREEN regression**

Run the Step 2 command again.

Expected: the `correctly compute matrix-vector multiplication` case completes without `IndexOutOfBoundsException`, and both `vectorOut` expectations match the existing golden outputs.

- [ ] **Step 5: Run the remaining CIMCore regressions**

Run:

```powershell
& 'C:\Program Files (x86)\sbt\bin\sbt.bat' shutdown
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.20.8-hotspot'
$env:JAVA_OPTS = '-Xms1G -Xmx8G -Xss4M -XX:ReservedCodeCacheSize=128m'
& 'C:\Program Files (x86)\sbt\bin\sbt.bat' --server --no-colors 'testOnly CIMCoreSpec'
```

Expected: all three `CIMCoreSpec` cases pass: matrix-vector, streaming, and ping-pong switching. The multi-stage cases use `pipeline = 2`, so this confirms the preserved path has not regressed.

- [ ] **Step 6: Inspect the scoped diff and commit**

Run:

```powershell
git diff --check
git diff -- accelerator/src/main/scala/core/CIMcore.scala accelerator/src/test/scala/core/CIMCoreTest.scala
git status --short
```

Expected: only the single-stage branch and, if used, an explicit test-name clarification are changed; no generated Verilog, `target/`, `test_run_dir/`, or `project/` output is staged.

Commit:

```bash
git add accelerator/src/main/scala/core/CIMcore.scala accelerator/src/test/scala/core/CIMCoreTest.scala
git commit -m "fix: support MACTreeFlood pipeline-1 execution"
```

## Plan Self-Review

- Spec coverage: Task 1 preserves the `pipeline >= 1` contract, prevents second-stage indexing in the single-stage branch, leaves the default two-stage configuration unchanged, and specifies real golden plus multi-stage regression coverage.
- Scope: wrapper heap usage and SBT JAR replacement are explicitly excluded; no unrelated accelerator refactor is planned.
- Type consistency: the plan uses existing Chisel `Vec`, `SInt`, `Queue`, `Decoupled`, `stageStates`, `stageCounters`, `accReg`, and `outputFifo` names from `MACTreeFlood`.
- Placeholder scan: no incomplete implementation steps or undecided APIs remain.