# Gemini-2 Technical Framework

## Positioning

`gemini-2` 是一个以官方 `Gemini CLI` 为主体、以 shared fabric 为治理骨架、并吸收部分 Claude Code 运行时模式的本地日用 fork。设计目标不是重写 Gemini，而是在尽量保持 upstream syncability 的前提下，把它推进成一个更清晰、更工程化、更适合长期项目协作的 CLI runtime。

## Architecture

### 1. Upstream-Compatible Base Layer

- 上游基线仍然是 `google-gemini/gemini-cli`
- 改动集中在 `packages/cli` 的会话编排、命令层与运行时服务，而不是重写 `packages/core`
- 同步策略仍然是 patch-layer：继续跟 `upstream/main` rebase / cherry-pick，而不是演化成无法回收的 hard fork

### 2. Session and Query Runtime Layer

- `sessionOrchestrator.ts`
  负责 `ACP / interactive / non-interactive` 路由，是 Gemini-first 的会话编排接缝
- `queryRuntimeService.ts`
  聚合 session、token、compression threshold、memory lanes、active skills、agents、shared-fabric overlay、bridge snapshot
- `/runtime status | compact | bridge`
  让 QueryRuntime 从隐式内部状态变成显式工程入口

### 3. Shared-Fabric Integration Layer

- `sharedFabricRegistry.ts`
  感知 `global-agent-fabric`、`awesome-skills`、domain routing、workspace overlay
- `sharedFabricAutoRouter.ts`
  在普通用户请求进入 `useGeminiStream` 时自动做三件事：
  1. 注入 `<shared_fabric_context>`
  2. 高置信度自动激活 shared-fabric skill
  3. 生成显式 agent routing hint
- `gemini-2` launcher
  启动时默认运行 `preflight_check.py` 和 `sync_all.py --skip-export`，让 shared-fabric boot 成为入口默认行为

### 4. Skill Runtime Layer

- `/skills search`
- `/skills recommend`
- `/skills use`
- `/skills active`

关键点不只是“能列出 skill”，而是可以按需从 shared-fabric catalog 加载 skill，并通过真实 `activate_skill` synthetic history 把 `<activated_skill>` 指令返回给模型。

### 5. Agent Runtime Layer

- `/agents recommend <query>`
- `/agents task <agent> <prompt>`
- `sharedFabricAutoRouter` 会自动给出 agent hint，但不隐式强制 fork 子代理

这保持了 Claude Code 式的“可清晰委托”优点，同时避免过度自动化带来的黑箱行为。

### 6. Memory and Team Context Layer

- `/memory team`
  展示 global / extension / project / user-project memory lanes
- shared-fabric global user question profile
- workspace user question profile overlay

这使 `gemini-2` 不只是“当前会话的聊天壳”，而是开始具备稳定的团队上下文和用户偏好适配能力。

### 7. Shared-Fabric Write-Back Layer

- `/fabric status`
- `/fabric route <query>`
- `/fabric sync <summary>`

`/fabric sync` 会调用 canonical `postflight_sync.py`，并带上 user-question-profile distillation payload，从而把 Gemini-2 session 正式写回 shared fabric。

## What Is Automatic Now

### Automatic by Default

- Gemini Core context compression
- shared-fabric launcher boot
- global profile + runtime bootstrap + workspace overlay prompt injection
- conservative skill auto-routing and auto-activation
- conservative agent auto-hinting
- explicit skill usage visibility in history

### Explicit by Design

- 子代理真正执行仍走显式 `invoke_agent`
- canonical postflight summary 仍需通过 `/fabric sync <summary>` 提供任务摘要

这样做是为了避免“貌似无缝，实则偷偷伪造 postflight summary”的不可靠自动化。

## Claude-Code Ideas Already Absorbed

- dynamic skill loading
- thicker session orchestration seam
- visible query runtime
- memory lane visibility
- explicit subagent entrypoints
- shared runtime bridge snapshot

## Claude-Code Ideas Still Partial

- full QueryEngine equivalent
- richer context compaction / memory lane products
- daemon-style long-lived bridge
- autonomous forked subagent lifecycle orchestration

因此，`gemini-2` 现在更准确的定位是：**Gemini-first runtime with Claude-inspired workflow thickening**，而不是 Claude Code clone。

## Key System Highlights

1. **Upstream-friendly**: 保持官方 Gemini CLI 为底座，后续仍可持续同步更新。
2. **Visible engineering runtime**: 运行时、skills、agents、memory、compression 不再藏在黑箱里。
3. **Shared-fabric aware by default**: 启动即 boot，首轮即注入全局 profile 和 workspace overlay。
4. **Conservative automation**: 自动选 skill 和 agent，但只在高置信度时触发，并保持显式反馈。
5. **Canonical sync preserved**: 不直接写 `.ndjson`，而是继续走 shared-fabric 脚本与协议。
6. **Claude-style clarity without monolith drift**: 吸收 Claude 的运行时智慧，但不破坏 Gemini 原有的分层边界。

## Current Boundary

`gemini-2` 已经可以作为本地日用 CLI 的平替，但还不能宣称已经完整复制了 Claude Code 的厚 QueryEngine / daemon / autonomous subagent runtime。当前实现更适合作为一个稳健、可持续迭代的 Gemini-first fork。
