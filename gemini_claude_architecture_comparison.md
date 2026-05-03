# Gemini CLI 与 Claude Code 架构对比研究

## 1. 研究对象与基线

本次比较基于两个明确的代码基线展开。

`Gemini CLI` 使用的是我在 `2026-04-24` 拉取的 `google-gemini/gemini-cli` 最新主干，当前工作树头部为 `571ca5a555fa7748a945942e6e3bccff6a34cfda`，最近一次提交时间是 `2026-04-23 16:26:29 -0700`。本地 `Claude Code` 则使用你已经放在 `ref structure/claude_code_annotated` 中的 annotated 源码，当前头部为 `222d2dd97217bb55d99acc22cc314a7ba33d2850`，提交时间为 `2026-04-02 10:00:44 +0800`。

结论先行: 如果目标是“以 Gemini CLI 为主体吸收 Claude Code 的先进架构”，正确策略不是把 Claude 的整套单仓厚应用直接搬过去，而是保留 Gemini CLI 现有的分层边界，再选择性吸收 Claude 在会话编排、上下文压缩、技能动态装配、多代理工作流上的成熟模式。

## 2. 整体拓扑差异

Gemini CLI 现在是典型的 `monorepo + core/edge split`。根 `package.json` 声明了 `packages/*` workspace，核心拆成了至少五个面向边界的包: `packages/cli`、`packages/core`、`packages/sdk`、`packages/a2a-server`、`packages/vscode-ide-companion`。这意味着 Gemini 的主优势不是功能数量，而是“边界先行”: CLI 壳、核心执行引擎、SDK 输出面、A2A 服务面、IDE 协同面已经分开。

Claude Code annotated 则明显更像一个“单仓应用内核”。绝大多数能力都直接堆在 `src/*` 下: `assistant`、`coordinator`、`tasks`、`tools`、`plugins`、`bridge`、`remote`、`server`、`voice`、`buddy`、`memdir`、`skills`。这种结构的优点是产品工作流更厚，跨能力联动非常强；缺点是入口和运行时耦合更重，长期维护会更依赖经验性约束。

从架构成熟度角度看，Claude 更像“产品态 orchestrator”，Gemini 更像“平台态 runtime”。如果你要做融合，最值得做的是把 Claude 的产品态工作流能力嫁接到 Gemini 的平台态内核上。

## 3. 会话主循环与执行编排

Gemini 的入口相对干净。`packages/cli/src/gemini.tsx` 主要负责启动、认证、会话恢复、配置加载、清理注册与 UI 分流，交互式 UI 在 `packages/cli/src/interactiveCli.tsx`，而真正执行工具的调度逻辑已经下沉到 `packages/core/src/scheduler/scheduler.ts`。这个 `Scheduler` 是事件驱动的工具编排器，围绕 `SchedulerStateManager`、`ToolExecutor`、`ToolModificationHandler`、`policy` 与 `messageBus` 运行，说明 Gemini 已经把“模型回合”和“工具执行”拆开了。

Claude 的主循环明显更厚。`src/entrypoints/cli.tsx` 负责非常多的 fast path 分流，`src/main.tsx` 是一个超重量入口，既负责 commander CLI、配置、认证、策略、MCP、插件、桥接、agent、REPL、resume/fork，又负责大量 feature gate 的运行时拼装。而真正的对话执行中枢在 `src/QueryEngine.ts`，它持有会话状态、工具权限、消息历史、读文件缓存、技能发现状态、memory 注入状态，并通过 `submitMessage()` 维护跨 turn 的完整生命周期。

这里的对比非常关键。Gemini 的优势是“执行器清晰”；Claude 的优势是“会话语义丰富”。Gemini 现在的调度器已经很像一个好内核，但 session orchestration 仍然比较分散在 CLI 与 core 之间。Claude 则把 session 视为一等公民，围绕 fork、resume、compact、background agent、remote bridge、SDK replay 建立了厚状态机。

对 Gemini 的启发是: 下一步不该继续往 `gemini.tsx` 堆逻辑，而应该在 `packages/core` 里引入显式的 `SessionOrchestrator` 或 `ConversationRuntime` 层，把当前散落在 CLI startup、turn handling、session summary、checkpoint、subagent 调度中的逻辑收拢为统一会话运行时。

## 4. 工具系统与权限策略

Gemini 的工具系统边界清楚。`packages/core/src/tools/tool-registry.ts` 管理所有工具注册、别名、动态发现工具、活跃工具集合；`packages/core/src/tools/definitions/*` 负责工具声明；`packages/core/src/policy/policy-engine.ts` 负责工具与 shell 命令的策略判定，还能针对 MCP 工具、subagent、argsPattern 做细粒度规则匹配；`packages/core/src/scheduler/scheduler.ts` 在执行前做 policy check、hook evaluate、confirmation resolve，再交给 executor。

Claude 的工具系统则更像“产品能力总线”。`src/tools.ts` 通过 `getAllBaseTools()` 拼接出完整工具面，里面不仅有文件、shell、web、MCP，还有 `AgentTool`、`TeamCreateTool`、`SendMessageTool`、`EnterPlanModeTool`、`WorkflowTool`、`MonitorTool`、`RemoteTriggerTool`、`PushNotificationTool` 等明显更偏 workflow/product 的能力。再叠加 `src/tasks.ts` 中的 `LocalAgentTask`、`RemoteAgentTask`、`DreamTask`、`LocalWorkflowTask`，可以看出 Claude 不是把“工具调用”当成唯一扩展点，而是把 task runtime 也纳入了一等抽象。

这意味着 Claude 的先进之处不只是工具多，而是它有两层抽象: tool layer 和 task layer。Gemini 现在有很好的 tool layer，但 task/workflow layer 还偏薄。你如果想让 Gemini 更接近 Claude 的高级工作流，不应该简单增加更多工具，而应该在 `packages/core` 之上新增更高一级的 `task/workflow runtime`。否则所有复杂工作流都会继续伪装成工具，导致工具层语义过载。

## 5. 上下文、记忆与压缩

Gemini 在记忆方面的设计是“层级清楚，但主动压缩较轻”。`packages/core/src/context/memoryContextManager.ts` 已经把 memory 切成 global、extension、project、user project 四层，并支持 `discoverContext()` 做 JIT 子目录记忆加载。这说明 Gemini 已经拥有不错的 context ingestion pipeline。它的另一个优点是 extension memory 能自动并入主上下文，这是后续可扩展性很强的一点。

但 Claude 在这一块明显更激进。`src/memdir/memoryTypes.ts` 不是简单的记忆读写，而是直接定义了 memory taxonomy: `user / feedback / project / reference`，并且明确规定什么不该记忆。更重要的是，Claude 不只“装载 memory”，还做“记忆治理”和“对话压缩治理”。从 `QueryEngine.ts`、`screens/REPL.tsx`、`services/compact/*`、`services/autoDream/*`、`services/teamMemorySync/*` 的组织可以看出，Claude 把 compact、snip、auto-dream consolidation、team memory sync 都当成长期会话治理能力。

这是 Gemini 当前最值得吸收、也最容易形成架构增益的一点。Gemini 已经有 session summary、checkpoint、memory service、subagent summary consolidation 的零散部件，但还没有形成 Claude 那种“长会话生存系统”。如果 Gemini 想往更强工程代理方向走，必须补齐这层。

我认为 Gemini 应该吸收 Claude 的不是具体 memory 文件格式，而是三条原则。

第一，记忆必须分 lane。至少要把用户偏好、项目状态、稳定参考、执行摘要分开，否则所有记忆最终都会变成不可控的 prompt 污染。

第二，压缩必须成为主动服务，而不是被动副产物。Claude 的 compact/snip/auto-dream 思路本质上是在持续控制上下文密度。Gemini 现在更像是“有 summary，但不是一个持续治理循环”。

第三，团队记忆与本地记忆应当解耦。Claude 的 team memory sync 非常像一个 repo-scoped collaborative lane。Gemini 如果未来要做团队代理，应该把它设计成 extension/service，而不是直接塞进本地 project memory。

## 6. 技能、命令与扩展机制

Gemini 的扩展机制比表面上更先进。`packages/cli/src/config/extension-manager.ts` 负责 extension 的安装、启用、完整性校验、workspace trust、settings hydration；`packages/core/src/utils/extensionLoader.ts` 则负责 extension 的启动、停止、MCP 注入、policy rule 注入、memory refresh、agent registry reload、skill reload。也就是说，Gemini 已经有一个相当现代的 extension runtime，只是目前它还更偏“加载器”，产品层工作流还不够厚。

Claude 在技能和命令侧做得更成熟。`src/commands.ts` 把命令面做成了非常厚的操作系统；`src/skills/loadSkillsDir.ts` 则把 Markdown/frontmatter 技能做成了一个动态装配系统，支持路径作用域、frontmatter hooks、argument substitution、execution context、agent 指定、model/effort 指定。这是 Claude 最值得学习的一块，因为它让“轻量 skill”真的成为一类可治理的运行单元，而不是只是一些 prompt snippet。

Gemini 已经有 `CommandService` 和 extension/skill loader，但仍然更偏 provider aggregation。Claude 则把 skill 看成“半结构化可执行资产”。所以我建议 Gemini 下一步把 skills 从“能加载”升级到“能治理”。

具体而言，Gemini 可以在现有 extension system 上补四个能力:

1. 路径作用域 skill。类似 Claude `paths` frontmatter，让技能只有在某些目录或文件匹配时才被激活。
2. Skill execution context。允许 skill 声明自己是在主循环执行，还是 forked subagent 执行。
3. Skill-level hooks/policies。允许技能贡献自己的前后置检查，而不是只能依赖全局 policy。
4. Skill metadata indexing。把技能当成一类可搜索资源，而不是只在 slash command 层暴露。

## 7. 多代理、远程与桥接

Gemini 已经有多代理骨架，但还偏内核化。`packages/core/src/agents/agent-scheduler.ts` 能给 subagent 创建独立 scheduler，上下文通过 `AgentLoopContext` 注入；policy 里也已经能针对 subagent 做规则匹配，prompt 中还有“sub-agent execution consolidated into a single summary”的设计。这说明 Gemini 已经迈入多代理阶段，只是产品面和运维面还比较克制。

Claude 在这方面走得更远。代码里存在 coordinator mode、LocalAgentTask、RemoteAgentTask、fork session、bridge、daemon、assistant mode、remote-control、buddy 等多条能力线，说明它的多代理不是抽象存在，而是已经进入“可恢复、可桥接、可后台运行、可跨界面连接”的产品态。

我不建议 Gemini 直接复制 Claude 这种厚桥接体系，因为这会显著提高运行时复杂度和状态一致性成本。但 Claude 的一个设计值得明确吸收: subagent 不应只是工具调用的递归，而应拥有独立的生命周期、日志边界、权限边界和结果回填边界。

Gemini 当前最适合的演进路径，是先把 subagent 从“scheduler reuse”提升为“session-scoped worker runtime”，再决定是否增加 daemon/bridge。

## 8. 以 Gemini CLI 为主体的优化方向

### 8.1 我认为最应该优先做的，不是功能复制，而是新增一层运行时骨架

Gemini 当前已经有足够好的 `core` 边界，因此不应该把 Claude 那种巨型 `main.tsx` 风格搬进来。正确做法是在 `packages/core` 内新增一层显式 orchestration:

- `session-runtime/SessionOrchestrator`
- `session-runtime/ContextBudgetManager`
- `session-runtime/SubagentRuntime`
- `session-runtime/TaskRuntime`

这样可以把当前分散在 CLI、turn、summary、memory、agent scheduler 中的会话语义收敛起来，而不破坏现有 `cli/core/sdk` 的包边界。

### 8.2 第二优先级是补“长会话治理”

这里 Claude 的领先很明显。Gemini 应该新增一套上下文治理流水线，而不是继续只靠 summary 和 checkpoint 零件。

建议直接引入以下能力:

- `conversation compaction`
- `progressive context collapse`
- `lane-based memory extraction`
- `post-turn consolidation`
- `subagent result compression`

但实现形式要 Gemini 化。不要复制 Claude 的所有产品表面，而是复用 Gemini 已有的 `context/`, `services/sessionSummaryService.ts`, `services/memoryService.ts`, `core/turn.ts`。我更推荐的做法是在 `core/turn.ts` 与 `context/pipeline` 之间插入一个 `ContextBudgetManager`，专门决定哪些内容保留、压缩、外置到 memory lane、或变成 subagent summary。

### 8.3 第三优先级是把 skill 提升为真正的中层抽象

Claude 的经验表明，光有工具不够，复杂代理需要一层比工具粗、比 session 细的可组合能力单元。Gemini 已经有 skills 与 commands，但还可以更强。

建议 Gemini 在现有 extension + command 系统上补充:

- 路径作用域 skills
- frontmatter-like skill metadata
- forkable skill execution
- skill-specific policy contribution
- skill search/indexing

这样一来，很多今天必须做成 MCP server 或硬编码 slash command 的能力，可以降级为可治理 skill，系统复杂度会更平衡。

### 8.4 第四优先级才是更厚的多代理产品面

Claude 的 coordinator/fork/remote/bridge 很强，但这是高复杂度区域。我建议 Gemini 分三步走。

第一步，只做 `subagent runtime hardening`，包括独立日志、独立权限、独立 summary、独立 abort。

第二步，做 `background task runtime`，让部分 subagent 能脱离当前 turn 短暂运行。

第三步，再考虑 `bridge/daemon/remote-control`。否则过早上桥接层，会把 Gemini 当前干净的 core 边界污染掉。

## 9. 一个合理的融合蓝图

如果由我来设计 Gemini-first 的融合版本，我会采用下面这条技术路线。

短期，保留 `packages/cli` 作为 UI 和 command 壳，保留 `packages/core` 作为执行内核，只新增 `session-runtime` 与 `context-governance` 两个子域。这个阶段的目标不是“功能像 Claude”，而是把 Gemini 的会话语义变厚。

中期，把 `skill` 从命令附属品升级为中层运行单元，并把 extension 贡献统一映射到四类资产: tools、skills、agents、memory/policy contributions。这个阶段的目标是让扩展体系真正成为产品能力装配底座。

后期，再引入更厚的多代理和远程执行面，但必须坚持 Gemini 当前的包边界原则。也就是说，即便将来有 daemon 或 bridge，也应该优先新建 `packages/daemon` 或 `packages/remote`，而不是把逻辑继续堆回 `packages/cli`。

## 10. 最终判断

Claude Code 被认为“架构更先进”，我认为这个判断只对一半。它先进的地方，主要在于它已经把代理产品里的很多难题做成了运行时系统: fork、compact、memory taxonomy、task runtime、plugin/skill orchestration、remote bridge。它不先进的地方，是很多能力被堆进了一个很厚的单仓应用核中，长期演化成本会很高。

Gemini CLI 则相反。它在“架构边界”上其实比 Claude 更健康，但在“代理工作流厚度”上还没完全长出来。因此最优融合策略非常明确: 保留 Gemini 的分层架构，把 Claude 的会话治理、技能治理、上下文压缩、多代理工作流当成可移植模式，逐步嫁接进 Gemini `core` 的中层运行时，而不是反过来把 Gemini 做成另一个巨型 `main.tsx`。

一句话总结: Gemini CLI 应该向 Claude Code 学“运行时机制”，不要学“单体入口形态”。

## 11. 建议的落地顺序

如果后续要真的动手做改造，我建议按下面顺序推进。

1. 在 Gemini `packages/core` 中引入 `SessionOrchestrator` 与 `ContextBudgetManager`。
2. 把当前 summary/checkpoint/memory/subagent summary 合并为统一的长会话治理流水线。
3. 升级 skill 系统，加入路径作用域、fork context、metadata indexing、policy contribution。
4. 为 subagent 增加独立 lifecycle、日志与权限边界。
5. 最后再决定是否要引入 daemon / bridge / remote-control。

按照这个顺序，Gemini 会在不破坏现有优势的前提下，最大化吸收 Claude 的长板。

