# Walkthrough

## What was done

完成了共享 fabric boot，记录了六阶段任务事件，并将 `google-gemini/gemini-cli` 拉取到 `ref structure/gemini-cli`。随后对本地 `claude_code_annotated` 与 Gemini CLI 做了代码级结构测绘，不是停留在目录名，而是下钻到入口、调度、工具、记忆、扩展与多代理相关的核心文件。

最终产出了一份以 Gemini CLI 为主体的架构对比报告，核心判断是: Gemini 的优势在边界清晰，Claude 的优势在会话治理和工作流厚度。最优方案不是“把 Claude 整体搬过来”，而是把 Claude 的运行时模式嫁接到 Gemini 现有的 `packages/core` / `packages/cli` 分层里。

## Main conclusions

Gemini 已经有很好的 `Scheduler`、`ToolRegistry`、`MemoryContextManager`、`ExtensionLoader` 骨架，但缺一个更厚的 `SessionOrchestrator` 层。Claude 则已经把 `QueryEngine`、context compaction、team memory、forked subagent、bridge/daemon、dynamic skill loading 这些能力做成了产品态系统。

因此，Gemini 最应该优先吸收的，是 Claude 的四类模式: 长会话治理、skill 中层抽象、多代理生命周期、任务型 runtime；最不应该直接复制的，则是 Claude 那种巨型单仓入口形态。

## Artifacts

- `task.md`
- `gemini_claude_architecture_comparison.md`
- `installed_gemini_cli_integration.md`
- `run_local_gemini_cli.sh`

---

## Shared Fabric Assessment

这次进一步把目标从“研究 Gemini CLI 怎么优化”推进到了“如果 `gemini-2` 真要成为 David 以后默认使用的本地 CLI，它应该原生吸收哪些 shared-fabric 能力”。结论非常明确: 当前 shared framework 的真正强项不在 `global-agent-fabric/skills` 这个本地目录，而在三层组合上: `rules + sync scripts` 的治理骨架、`awesome-skills` 的超大外部技能库、以及 `continuous-learning + mempalace + user-question-profile` 组成的记忆与适配层。

因此，最值得加进 `gemini-2` 的不是“更多技能内容”，而是“技能操作系统”本身: native shared-fabric boot/postflight、skill discovery/routing、context budget/compaction、memory routing commands、以及 review/audit/debug 这些高频运行模式。工作流类内容如 `antigravity-workflows`、`architecture`、`docs-architect` 则更适合在下一阶段做成 first-class runtime routes，而不是一开始就把整个外部 skill 仓灌进 CLI 内核。

## New Artifact

- `gemini2_shared_fabric_feature_priorities.md`

---

## Gemini-2 Runtime Upgrade

这一步开始把 `gemini-2` 从“改过源码、能单独启动”的版本，推进成更像日常工程入口的 CLI。重点不是继续堆更多 skill 内容，而是把 shared-fabric 的目录协议和技能工作流真正接到运行时里，让用户能看见、检索、调用，并理解当前会话到底用了什么能力。

实现上我新增了 `sharedFabricRegistry.ts` 作为共享框架注册表，用来感知 `global-agent-fabric`、`awesome-skills` 索引、领域路由文档、workspace question-profile overlay 等资源；在此基础上扩展了 `/skills`，补上 `/skills active`、`/skills search`、`/skills recommend`、`/skills use`，并新增 `/fabric status` 与 `/fabric route`。其中最关键的是 `/skills use <name>`: 它会按需从 shared-fabric catalog 中把 skill 读进当前 session，再走 Gemini 现有的 `activate_skill` 工具链，所以这次不是“只会列 skill”，而是真的把 on-demand retrieval 接成了可执行能力。

为了修复你之前提到的“Gemini CLI 里看不出用了什么 skill”，我还补了两层显式反馈。第一层是在 `useGeminiStream.ts` 里，当 `activate_skill` 成功后，会直接在历史里写出 `Activated skill: ...`；第二层是在 `StatusDisplay.tsx` / `ContextSummaryDisplay.tsx` 里，把 active skill count 放进状态摘要。再加上 `gemini-2` 启动器现在会默认导出 shared-fabric root/workspace 环境变量，这一轮之后，`gemini-2` 已经具备了“共享框架可见、skill 可按需拉取、会话内激活状态可追踪”的基础日用形态。

## New Artifacts

- `ref structure/gemini-cli/packages/cli/src/services/sharedFabricRegistry.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/commands/fabricCommand.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/commands/skillsCommand.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/hooks/useGeminiStream.ts`
- `gemini-2`

---

## Gemini-2 QueryRuntime Deepening

这一轮开始把前面的 shared-fabric 接入，继续往“Claude Code 那种清晰工程能力”推进，但方法不是去生搬硬套一个新内核，而是把 Gemini CLI 已经内建的零件真正串起来。实际下钻后，我确认 Gemini 本身已经具备不少基础设施: `tryCompressChat` 能做上下文压缩，`MemoryContextManager` 已经分 global/extension/project/user-project memory lane，`invoke_agent` 已经是原生子代理工具，project temp / checkpoints / tracker 目录也都已经存在。所以这次的重点是“把这些能力变成清晰的用户入口和外部 bridge”，而不是继续做隐藏式内部增强。

具体实现上，我新增了 `QueryRuntimeService`，它会聚合当前 session id、model、token limit、last prompt token count、compression threshold、active skill、agent registry、memory lane 统计、checkpoint 计数以及 shared-fabric overlay 状态，并把这些内容写成一个 bridge snapshot 到项目 temp 目录下。基于它，新加了 `/runtime status`、`/runtime compact`、`/runtime bridge` 三个命令: 前者给出统一的 query runtime 状态面板，中间那个把 Gemini 原生压缩入口接成显式工程命令，后者则把 snapshot 写回给外部观察层。它还不是 Claude 那种常驻 daemon，但已经是一个真正可消费的 bridge seam。

同时，我把 team memory 和 subagent 也做成了显式命令。`/memory team` 现在会直接展示分层 memory lane 与 shared-fabric question-profile overlay；`/agents recommend <query>` 会把 agent registry 按任务语义做简单排序；`/agents task <agent> <prompt>` 则不再让用户依赖隐式 prompt steering，而是直接走 Gemini 原生 `invoke_agent` 工具，让“fork 一个子代理去做事”成为清楚可见的运行时操作。到这一步，`gemini-2` 还没有完整吸收 Claude Code 的 QueryEngine / daemon / team memory 产品态，但已经从“有零件”进化到“有清晰工程入口”的阶段。

## New Artifacts

- `ref structure/gemini-cli/packages/cli/src/services/queryRuntimeService.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/commands/runtimeCommand.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/commands/memoryCommand.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/commands/agentsCommand.ts`
- `ref structure/gemini-cli/packages/cli/src/services/BuiltinCommandLoader.ts`

---

## Gemini-2 Auto Routing and Shared-Fabric Seam Tightening

这一轮的目标不是再做一个新功能面板，而是把之前“看起来像已经接上”的几处能力补成真正默认生效的运行时行为。经过核对源码后，我确认 Gemini Core 本来就有自动压缩路径：当 `contextManagement` 没接管时，`client.ts` 会在每轮请求前调用 `tryCompressChat(...)`，而 `chatCompressionService.ts` 本身也会先触发 `PreCompress` hook。所以“自动上下文压缩”不是我们凭空新增的能力，真正缺的是 shared-fabric overlay 还没有自动进 prompt、skill/agent 路由还停留在显式命令层，以及 shared-fabric 的 canonical postflight 还没有 CLI 内入口。

因此这次新增了 `SharedFabricAutoRouter`。它会在正常用户文本请求进入 `useGeminiStream` 时自动做三件事：第一，第一次会话请求时把 global user-question profile、runtime bootstrap order、workspace overlay 作为 `<shared_fabric_context>` 注入；第二，根据 `SharedFabricRegistry` 的 routed skill 结果做保守型自动 skill 激活，只在高置信度且非高风险时触发，并且通过真实 `activate_skill` synthetic history 把 `<activated_skill>` 指令链补给模型；第三，基于 agent registry 做轻量 agent hint 路由，把推荐 agent 明确写进 `<shared_fabric_routing>`，同时保留“若要委托，必须走显式 `invoke_agent`”这条工程边界。对应的用户可见反馈也不再缺席：session context、auto-loaded skill、auto-routed agent 都会直接显示在 history 里。

shared-fabric 生命周期也更紧了。`gemini-2` 启动器现在会在普通运行时自动执行 `preflight_check.py` 和 `sync_all.py --skip-export`，并输出 `[BOOT_OK]`；而在 CLI 内又补了 `/fabric sync <summary>`，它会读取 workspace user-question profile overlay，组装 user-question-profile payload，再直接调用 canonical `postflight_sync.py` 写回 `[SYNC_OK]` 风格的 postflight bundle。这样一来，`gemini-2` 至少在安全的工程边界内已经具备了“自动 boot + 自动 context ingestion + 自动 skill/agent 路由 + CLI 内 postflight write-back”的完整闭环。唯一还不能声称 fully automatic 的部分，是退出时无摘要、无任务判断的隐式 postflight，我刻意没有伪造，因为那会违背 shared-fabric 的 canonical contract。

## New Artifacts

- `ref structure/gemini-cli/packages/cli/src/services/sharedFabricAutoRouter.ts`
- `ref structure/gemini-cli/packages/cli/src/services/sharedFabricAutoRouter.test.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/hooks/useGeminiStream.ts`
- `ref structure/gemini-cli/packages/cli/src/ui/commands/fabricCommand.ts`
- `gemini2_technical_framework.md`
