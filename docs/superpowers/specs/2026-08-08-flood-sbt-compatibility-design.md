# FLOOD SBT 兼容性与动态验证修复设计

## 背景

FLOOD 基线仅包含 `build.sbt`，没有 `project/build.properties`。安装的 SBT 2.0.6 因此在首次运行时自动创建 `sbt.version=2.0.6`，并在 Windows 的 `(Compile / packageBin)` 阶段持续失败：临时 JAR 无法原子替换为 `accelerator_2.12-0.1.0-SNAPSHOT.jar`。该失败发生在 `MACTreeFloodSpec` 仿真启动前，导致 RTL 动态验证无法执行。

工程依赖 Scala 2.12.13、Chisel 3.5.3 和 chiseltest 0.5.3，属于 SBT 1.x 时代的构建组合。

## 目标

为 FLOOD 工程加入显式、可复现的 SBT 1.12.15 版本锁定，并在 JDK 17 下重新运行已新增的 `MACTreeFloodSpec` 动态回归。

## 非目标

- 不修改 RTL、测试逻辑、默认 Config 或 Diffusion 设计。
- 不卸载系统 SBT 2.0.6；SBT runner 根据工程锁定文件选择 1.12.15。
- 不修改全局 SBT 安装目录或用户级 JVM 配置。

## 方案比较

1. **推荐：提交 `accelerator/project/build.properties`，内容仅为 `sbt.version=1.12.15`。** 让每个开发者和 CI 使用同一兼容 SBT 1.x，变更最小且可审计。
2. 保持 SBT 2.0.6 并绕过 `packageBin`。需要临时 SBT 2 设置或复杂的 Windows 转义，构建不可复现，且未解决默认路径失败。
3. 卸载并全局降级 SBT。会影响其他项目，且仍无法在仓库中表达版本契约。

采用方案 1。

## 实施与验证

- 新增 `accelerator/project/build.properties`，UTF-8 文本且仅一行：`sbt.version=1.12.15`。
- 以 JDK 17、8 GB 临时 `JAVA_OPTS` 在前台运行 `testOnly MACTreeFloodSpec`。
- 成功标准：SBT 报告 1.12.15；新的 FIFO 满载回归通过；不出现 `packageBin` 的 JAR `AccessDeniedException`。
- 若首次启动需下载 SBT 1.12.15，允许下载官方构建组件；不得添加未审查依赖。
- 若仍失败，保留完整命令与输出，将问题归类为 Windows 文件锁而非 RTL 失败。

## 风险控制

`build.properties` 是项目本地锁定文件，不影响系统的 SBT 2.0.6。固定版本后先只运行单一 MACTreeFlood 回归；确认通过后再考虑扩展到 CIMCoreSpec 或全量测试。