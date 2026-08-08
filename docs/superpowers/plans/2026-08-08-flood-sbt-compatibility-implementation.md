# FLOOD SBT Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 固定 FLOOD 使用 SBT 1.12.15，并以 JDK 17 运行 `MACTreeFloodSpec` 动态 FIFO 回归。

**Architecture:** 在项目本地增加一个版本锁定文件，使已安装的 SBT runner 选择 SBT 1.12.15 而不是首次运行自动选择的 2.0.6。该文件位于 `accelerator/project/`；由于构建缓存目录已被忽略，必须显式强制暂存该唯一配置文件。验证仅运行已存在的 MACTreeFlood 测试，不改 RTL。

**Tech Stack:** SBT 1.12.15、Temurin JDK 17.0.20、Scala 2.12.13、Chisel 3.5.3、chiseltest 0.5.3、Windows PowerShell。

## Global Constraints

- 不修改 `accelerator/src/main/scala/`、`accelerator/src/test/scala/`、默认 Config 或 Diffusion 代码。
- 不卸载或修改系统 SBT 2.0.6；runner 依据项目 `build.properties` 选择 1.12.15。
- 新增文件必须是 UTF-8 文本且内容仅为 `sbt.version=1.12.15` 加换行。
- `accelerator/project/` 被忽略；提交时必须使用 `git add -f accelerator/project/build.properties`，不得暂存 `accelerator/project/target/`。
- 动态测试以 `--server --no-colors` 运行，并在本次命令中设置 `JAVA_HOME` 与 8 GB `JAVA_OPTS`。

---

## File Structure

- `accelerator/project/build.properties`：FLOOD 的唯一 SBT 版本锁定文件；供 SBT runner 在加载 `accelerator/build.sbt` 前选择 SBT 1.12.15。
- `accelerator/src/test/scala/core/MACTreeFloodTest.scala`：仅作为已有动态验证输入，不修改。

### Task 1: Pin SBT 1.12.15 and Run the Focused Regression

**Files:**
- Create: `accelerator/project/build.properties`
- Test: `accelerator/src/test/scala/core/MACTreeFloodTest.scala`

**Interfaces:**
- Consumes: SBT runner `C:\Program Files (x86)\sbt\bin\sbt.bat`、`accelerator/build.sbt` 和 `project/build.properties` 的 `sbt.version` key。
- Produces: project-local SBT 1.12.15 selection and an observable `MACTreeFloodSpec` test result.

- [ ] **Step 1: Establish the RED environment behavior**

Run from `accelerator/` without creating or modifying `project/build.properties`:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.20.8-hotspot'
$env:JAVA_OPTS = '-Xms1G -Xmx8G -Xss4M -XX:ReservedCodeCacheSize=128m'
& 'C:\Program Files (x86)\sbt\bin\sbt.bat' --server --no-colors 'testOnly MACTreeFloodSpec'
```

Expected RED evidence: SBT reports `welcome to sbt 2.0.6`, then fails before simulation with `(Compile / packageBin) java.nio.file.AccessDeniedException` while replacing `accelerator_2.12-0.1.0-SNAPSHOT.jar`.

- [ ] **Step 2: Create the minimal local version lock**

Create exactly this file content:

```properties
sbt.version=1.12.15
```

Use `accelerator/project/build.properties`; do not create `plugins.sbt`, `.jvmopts`, or a global SBT configuration file.

- [ ] **Step 3: Confirm SBT 1.12.15 is selected**

Run:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.20.8-hotspot'
$env:JAVA_OPTS = '-Xms1G -Xmx8G -Xss4M -XX:ReservedCodeCacheSize=128m'
& 'C:\Program Files (x86)\sbt\bin\sbt.bat' --server --no-colors --version
```

Expected: the runner downloads SBT 1.12.15 if it is not cached, then reports the project version as `1.12.15`. No source or test file changes occur.

- [ ] **Step 4: Run the GREEN dynamic regression**

Run:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.20.8-hotspot'
$env:JAVA_OPTS = '-Xms1G -Xmx8G -Xss4M -XX:ReservedCodeCacheSize=128m'
& 'C:\Program Files (x86)\sbt\bin\sbt.bat' shutdown
& 'C:\Program Files (x86)\sbt\bin\sbt.bat' --server --no-colors 'testOnly MACTreeFloodSpec'
```

Expected: `MACTreeFloodSpec` passes the depth-4 FIFO/full-backpressure scenario, reports no `AccessDeniedException`, and leaves any `target/` or `test_run_dir/` output ignored.

- [ ] **Step 5: Inspect scope and commit the version lock**

Run:

```powershell
git status --short
git check-ignore -v accelerator/project/build.properties
git diff --check
git diff -- accelerator/project/build.properties
```

Expected: `build.properties` is ignored by the directory rule but is the only intended project metadata source file. Force-stage only it:

```bash
git add -f accelerator/project/build.properties
git diff --cached --check
git commit -m "build: pin FLOOD to sbt 1.12.15"
```

Do not stage `accelerator/project/target/`, `accelerator/target/`, generated JARs, or simulator output.

## Plan Self-Review

- Spec coverage: Task 1 locks the exact SBT version, preserves system SBT 2.0.6, runs the focused dynamic regression with JDK 17 and 8 GB heap, and records the expected Windows-package failure as RED evidence.
- Scope: no RTL/test source or global build-tool configuration is changed.
- Type consistency: `sbt.version` is the standard `project/build.properties` key consumed by the SBT runner; commands use the installed runner and JDK paths established in the environment baseline.
- Placeholder scan: every file content, command, expected outcome, and commit scope is explicit.