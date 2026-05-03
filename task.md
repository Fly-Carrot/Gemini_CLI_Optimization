# Gemini CLI vs Claude Code Architecture Study

## Task

以 `Gemini CLI` 为主体，对本地 `ref structure/claude_code_annotated` 与最新 `google-gemini/gemini-cli` 做架构对比，判断哪些 Claude Code 架构模式值得迁移到 Gemini CLI，以及应该如何迁移。

## Baseline

- Workspace: `/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization`
- Claude baseline: `222d2dd97217bb55d99acc22cc314a7ba33d2850` (`2026-04-02`)
- Gemini baseline: `571ca5a555fa7748a945942e6e3bccff6a34cfda` (`2026-04-23`)

## Six-Stage Status

- [x] 路由: 识别为复杂架构研究任务，需要共享 fabric boot、远程仓库抓取、代码测绘与优化方案设计。
- [x] 规划: 将比较拆成四个切面: 会话主循环、工具与权限、上下文与记忆、扩展与多代理。
- [x] 自审: 核验核心证据文件，避免只看目录名下结论。
- [x] 分发: 将分析落到 Gemini `packages/core` / `packages/cli` 与 Claude `main.tsx` / `QueryEngine` / `tools.ts` / `skills` 等真实中枢。
- [x] 执行: 完成代码抓取、结构分析与报告写作。
- [x] 回奏: 已完成 canonical postflight sync，并写回 promoted learning、MemPalace 记录与 user-question-profile。

## Deliverables

- `gemini_claude_architecture_comparison.md`
- `walkthrough.md`
- `installed_gemini_cli_integration.md`
- `run_local_gemini_cli.sh`

---

## Follow-on Task: Gemini-2 Shared Fabric Priorities

### Task

盘点当前共享框架中的治理层、生成型 skill、外部 `awesome-skills` 技能库与记忆路由机制，判断如果 `gemini-2` 要成为本地默认日用 CLI，哪些能力值得内建，哪些应继续保持外置。

### Six-Stage Status

- [x] 路由: 识别为复杂产品化评估任务，目标不是单纯列 skill，而是为 `gemini-2` 形成内建能力优先级。
- [x] 规划: 将盘点拆成四层: shared-fabric 治理脚本、generated skill、awesome-skills 大库、记忆与工作流路由。
- [x] 自审: 核验 `global-agent-fabric` 实际 `skills/` 为空壳、真正技能面来自 `skills/sources.yaml` 指向的外部仓。
- [x] 分发: 下钻读取 `gemini-global.md`、`boot-sequence.md`、`runtime-map.yaml`、`memory/routes.yaml`、`skills-domain-map.md` 与代表性 skill 实体。
- [x] 执行: 完成 skill 盘点、优先级判断，并产出 `gemini2_shared_fabric_feature_priorities.md`。
- [x] 回奏: 将结论回写为共享 fabric 兼容的产品化路线，准备作为后续 `gemini-2` 实装依据。

### Deliverables

- `gemini2_shared_fabric_feature_priorities.md`
- `task.md`
- `walkthrough.md`

---

## Follow-on Task: Gemini-2 Native Shared Fabric Runtime

### Task

将 `gemini-2` 从“本地源码版 Gemini CLI 启动器”推进为更适合日常替代官方 `gemini` 的入口，重点补三类能力: shared-fabric 状态可见性、按需 skill 检索/加载/激活、以及更明确的工程工作流反馈。

### Six-Stage Status

- [x] 路由: 识别为复杂运行时改造任务，需要同时处理 CLI 架构接缝、shared-fabric 目录协议、技能检索与用户可见反馈。
- [x] 规划: 将实现拆成三层: shared-fabric registry、`/skills` 与 `/fabric` 命令面、会话内 active-skill 可见性与启动器环境接入。
- [x] 自审: 核验现有 Gemini CLI 的 skill 机制确实存在，但缺少显式的 skill 搜索、路由、active 可见性和 shared-fabric 状态入口。
- [x] 分发: 将改造落到 `sharedFabricRegistry.ts`、`skillsCommand.ts`、`fabricCommand.ts`、`useGeminiStream.ts`、`StatusDisplay.tsx` 与 `gemini-2` 启动器。
- [x] 执行: 完成 shared-fabric registry、`/skills search|recommend|use|active`、`/fabric status|route`、skill 激活反馈、active skill 状态摘要与启动器环境变量接入。
- [x] 回奏: 已通过定向测试、typecheck、build，并准备执行 canonical postflight sync 与 user-question-profile 回写。

### Deliverables

- `ref structure/gemini-cli/packages/cli/src/services/sharedFabricRegistry.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/commands/skillsCommand.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/commands/fabricCommand.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/hooks/useGeminiStream.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/components/StatusDisplay.tsx`
- `gemini-2`

---

## Follow-on Task: Gemini-2 QueryRuntime Deepening

### Task

继续把 `gemini-2` 往 Claude Code 风格的厚工程运行时推进，但坚持 Gemini-first 路线。重点不是重写整个 CLI，而是在现有 Gemini Core 上补出更清晰的 query runtime、context compaction 可见性、team memory lane 视图、显式 forked subagent 入口，以及可供外部工具消费的 bridge snapshot。

### Six-Stage Status

- [x] 路由: 识别为复杂运行时深化任务，需要对齐 shared-fabric boot、六阶段日志、Gemini 现有压缩/记忆/agent 机制与 Claude 风格工程能力目标。
- [x] 规划: 将实现拆成四块: `QueryRuntimeService` 状态聚合、`/runtime` 命令面、`/memory team` 记忆分层可见性、`/agents recommend|task` 显式子代理入口。
- [x] 自审: 核验 Gemini CLI 已经内建 `tryCompressChat`、`MemoryContextManager`、`invoke_agent`、checkpoint/temp storage 等真实能力，避免空造新的平行系统。
- [x] 分发: 将改造落到 `queryRuntimeService.ts`、`runtimeCommand.ts`、`memoryCommand.ts`、`agentsCommand.ts` 与 `BuiltinCommandLoader.ts`，并补对应测试。
- [x] 执行: 完成 QueryRuntime bridge snapshot、`/runtime status|compact|bridge`、`/memory team`、`/agents recommend|task`，并让 `gemini-2` 构建后可直接运行。
- [x] 回奏: 已通过 `typecheck`、定向 `vitest`、`posttest build` 与 `./gemini-2 --version` 验证，接下来将执行 canonical postflight sync 与 user-question-profile 回写。

### Deliverables

- `ref structure/gemini-cli/packages/cli/src/services/queryRuntimeService.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/commands/runtimeCommand.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/commands/memoryCommand.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/commands/agentsCommand.ts`
- `ref structure/gemini-cli/packages/cli/src/services/BuiltinCommandLoader.ts`
- `gemini-2`

---

## Follow-on Task: Gemini-2 Auto Routing, Shared-Fabric Boot, and Release Readiness

### Task

核验 `gemini-2` 是否已经真正具备以下能力：持续跟随官方 Gemini CLI 升级、自动上下文压缩、自动选择合适的 shared-fabric skill 与 agent、显式展示当前使用的方法、以及与 shared fabric 的无缝衔接；对未实现的部分直接补齐，并整理成可公开分享的技术框架。

### Six-Stage Status

- [x] 路由: 识别为复杂运行时收尾与产品化任务，需要同时处理自动路由、shared-fabric 生命周期、验证、文档与发布状态。
- [x] 规划: 将缺口拆成四段: 事实核验、自动 shared-fabric prompt augmentation、launcher boot 与 postflight 命令面、技术框架整理与 GitHub 发布检查。
- [x] 自审: 核验 Gemini Core 现有自动压缩路径真实存在于 `client.ts` / `chatCompressionService.ts`，当前真正缺的是自动 overlay 摄入、自动 skill/agent 路由与 shared-fabric write-back 入口。
- [x] 分发: 将改造落到 `sharedFabricAutoRouter.ts`、`useGeminiStream.ts`、`gemini-2` 启动器与 `fabricCommand.ts`。
- [x] 执行: 完成 shared-fabric session context 自动注入、保守型自动 skill 激活、agent hint 自动路由、launcher preflight/sync boot、`/fabric sync` canonical postflight 入口，并通过 typecheck / vitest / build / launcher 版本验证。
- [ ] 回奏: 待执行本轮 canonical postflight sync 与 user-question-profile 回写；GitHub fork 发布仍受 `gh` 认证失效阻塞。

### Deliverables

- `ref structure/gemini-cli/packages/cli/src/services/sharedFabricAutoRouter.ts`
- `ref structure/gemini-cli/packages/cli/src/services/sharedFabricAutoRouter.test.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/hooks/useGeminiStream.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/commands/fabricCommand.ts`
- `gemini-2`
- `gemini2_technical_framework.md`
