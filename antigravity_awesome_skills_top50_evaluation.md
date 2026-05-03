# Antigravity Awesome Skills Top 50 Evaluation

## Upstream Snapshot

- Upstream repo: [sickn33/antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills)
- GitHub landing page currently advertises `1,441+` skills and release `v10.8.0`
- Local in-fabric repo path:
  - `/Users/david_chen/Antigravity_Skills/global-agent-fabric/skills/awesome-skills`
- Local `skills_index.json` currently indexes `1237` skills
- Indexed entries marked `uncategorized`: `1165`

## Overall Judgment

The repository is highly valuable, but the full library is too large to serve as the first retrieval surface for Gemini-2 day-to-day work. The correct pattern is:

1. hot-path curated shortlist
2. broader top-50 curated workflow layer
3. full awesome-skills fallback

This preserves breadth without turning every skill lookup into a noisy catalog search.

## Seamless Application Model

Gemini-2 should not require the user to name every skill explicitly.

The intended flow is:

1. Read the user's input as an intent signal.
2. First try MCP/tools if they already cover the task directly.
3. If not, check the hot-path 8-skill layer.
4. Then check the Top 50 current-workflow layer.
5. Only then fall back to the full awesome-skills corpus.

### Input-Driven Evaluation Rules

- If the user asks to plan, compare, research, or refine a prompt, prefer planning/research skills.
- If the user asks about agents, loops, orchestration, MCP, evaluation, or long-running workflows, prefer agent/runtime skills.
- If the user asks to build, refactor, test, review, secure, or document code, prefer engineering delivery skills.
- If the user asks for docs, PRDs, launch material, content, market analysis, or long-form writing, prefer docs/product skills.
- If the user asks for Nature-style academic polishing, data availability, or scientific figures, prefer the academic add-on skills.

## Curated Top 50

### 1. Planning & Research

| Skill | What it is for | Seamless trigger from user input |
| --- | --- | --- |
| `brainstorming` | Vague ideas -> structured solution space | “想法”, “方案”, “brainstorm”, feature ideation |
| `concise-planning` | Atomic implementation plans | “给我计划”, “拆解步骤”, implementation checklist |
| `architecture` | System design and tradeoffs | “架构”, “system design”, “tradeoff”, baseline comparison |
| `prompt-engineering` | Prompt quality and routing prompt tuning | “提示词”, “prompt”, “为什么 agent 不听话” |
| `deep-research` | Multi-source deep research with citations | “深度研究”, “全面调研”, evidence-backed overview |
| `exa-search` | Fast neural web/code/company search | “查一下最新”, “找案例”, “搜资料” |
| `context7-auto-research` | Fresh framework/library docs | “最新文档”, “这个 API 现在怎么写” |
| `documentation-lookup` | Targeted official docs retrieval | asks for exact framework or SDK usage |
| `search-first` | Research before custom implementation | “先看看有没有现成方案” |
| `iterative-retrieval` | Refine retrieval in several passes | context is incomplete or user asks for progressive narrowing |

### 2. Agent / Runtime Orchestration

| Skill | What it is for | Seamless trigger from user input |
| --- | --- | --- |
| `agent-harness-construction` | Better agent action spaces and tool surfaces | “怎么让 agent 更稳定”, tool/observation design |
| `agentic-engineering` | Eval-first agent engineering | “agent engineering”, “multi-agent”, “可靠 agent runtime” |
| `ai-first-engineering` | AI-native engineering workflow design | “AI 优先开发流”, team operating model |
| `autonomous-agents` | Autonomous planning/execution patterns | “自主代理”, “autonomous agent” |
| `autonomous-loops` | Long-running autonomous loop design | “loop”, “自动连续执行”, “RALPH 类似能力” |
| `continuous-agent-loop` | Continuous loops with quality gates | asks for persistent autonomous iteration |
| `workflow-orchestration-patterns` | Durable workflow orchestration | “orchestration”, “Temporal”, “长任务编排” |
| `mcp-server-patterns` | MCP server design patterns | “MCP server”, tool/resource/prompt server design |
| `eval-harness` | Evaluation harness for agents | “eval”, “benchmark”, “回归基准” |
| `verification-loop` | Verification-first execution loops | “verify every step”, “验证循环” |
| `cc-skill-context-compactor` | Compress huge logs/context safely | giant logs, token pressure, context overload |
| `cc-skill-parallel-auditor` | Parallel repo/file survey before refactor | many files, large scan, pre-refactor mapping |

### 3. Engineering Delivery & Quality

| Skill | What it is for | Seamless trigger from user input |
| --- | --- | --- |
| `frontend-developer` | React/Next UI implementation | UI, component, responsive, frontend bug |
| `frontend-patterns` | Frontend architecture and performance | client state, rendering patterns, frontend structure |
| `backend-architect` | Scalable backend and APIs | backend structure, service boundaries, resilience |
| `backend-patterns` | Practical server-side patterns | API routes, service layer, backend best practices |
| `api-documenter` | API docs / portals / SDK doc | “API 文档”, OpenAPI, SDK docs |
| `api-design` | Resource modeling and API contracts | endpoint design, pagination, errors, versioning |
| `code-reviewer` | Focused code review | “review”, regression/risk-focused audit |
| `testing-patterns` | Test factories, mocks, patterns | Jest patterns, factories, mocking |
| `tdd-workflow` | TDD execution discipline | “TDD”, “先写测试”, “red green refactor” |
| `ai-regression-testing` | Catch AI-generated regressions | “回归测试”, “AI 改坏了什么” |
| `coding-standards` | Shared coding quality expectations | “规范”, “standards”, cleanup for consistency |
| `project-guidelines-example` | Project-specific skill template | building project conventions / local style rules |
| `security-review` | Security review for app logic | auth, secrets, input handling, payment/sensitive APIs |
| `security-scan` | Configuration and agent-surface security | scan `.claude`, `.agents`, config surfaces |

### 4. Docs, Product & Polish

| Skill | What it is for | Seamless trigger from user input |
| --- | --- | --- |
| `docs-architect` | Long-form technical docs from codebase | architecture manual, repo walkthrough, handbook |
| `documentation` | General documentation workflows | README, code comments, documentation pass |
| `architecture-decision-records` | ADR authoring and maintenance | “写 ADR”, significant design decisions |
| `product-manager-toolkit` | PRD/prioritization/discovery support | product planning, feature prioritization |
| `market-research` | Competitive/market analysis | market sizing, competitors, industry scan |
| `team-builder` | Build a multi-agent or role team | “组一个团队”, task-specific agent squad |
| `launch-strategy` | Release and launch planning | “发布”, “announcement”, GTM |
| `content-engine` | Platform-native content systems | multi-platform content or campaign production |
| `article-writing` | Long-form polished writing | guide, article, tutorial, newsletter |
| `liquid-glass-design` | Apple-style glass UI direction | macOS/iOS glassy visual design requests |
| `video-editing` | AI-assisted video workflows | cut footage, make video content, edit pipeline |

### 5. Academic Add-on

| Skill | What it is for | Seamless trigger from user input |
| --- | --- | --- |
| `nature-polishing` | Nature-style manuscript polishing | academic English, abstract/introduction/results polishing |
| `nature-data` | Data availability / FAIR / repository statements | “data availability”, FAIR, journal data statement |
| `nature-figure` | Publication-ready scientific figures | “Nature 风格图”, matplotlib paper figure |

## Operational Recommendation

For current Gemini-2 and shared-fabric work, use these three retrieval tiers:

1. `/Users/david_chen/Antigravity_Skills/global-agent-fabric/skills/curated/current-workflow`
2. `/Users/david_chen/Antigravity_Skills/global-agent-fabric/skills/curated/top50-current-workflow`
3. `/Users/david_chen/Antigravity_Skills/global-agent-fabric/skills/awesome-skills/skills`

## Why This Top 50, Not Another 50

This selection is biased toward the workflows that recur in the current project:

- Gemini-2 runtime design
- shared-fabric integration
- terminal/desktop interaction work
- architecture reviews
- agent/loop orchestration
- documentation and release-quality communication
- occasional academic/Nature-style output

It is intentionally not optimized for sales automation, CRM operations, generic social-media automation, or niche SaaS connectors, even though those exist in the full library.
