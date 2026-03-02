# MCP Rules — MCP Tool Usage Constraints

---

## 1. Global Principles

- **Offline first**: use local tools when they can accomplish the task; do not call external MCP. Default to 1 MCP per round; if using >2, state the reason and expected benefit
- **Minimal scope**: limit query scope; avoid excessive data capture
- **Traceable**: cite source when referencing external information

---

## 2. Decision Flow

```
Task received
  │
  ├─ Can Agent's built-in tools complete this?
  │    ├─ Yes, with sufficient efficiency → use native tools, skip MCP
  │    └─ No, or MCP is clearly better → select MCP tool (see §3)
  │
  └─ Execute and monitor
       ├─ Success → done
       └─ Failure → trigger switch (see below)
```

### 2.1 Switch Triggers

| Trigger | Condition | Action |
|---------|-----------|--------|
| **Error** | MCP tool fails ≥ 2 times consecutively | Switch to fallback or native tool |
| **Efficiency** | MCP call takes far longer than expected | Evaluate local tool alternative |
| **Capability** | Task exceeds current tool's scope | Switch to more suitable MCP or combine |
| **Discovery** | Better tool found during execution | Switch immediately |

### 2.2 Missing Tool Handling

When a task needs an MCP that is not configured:
1. Inform user what tool is missing and its value
2. Provide install/config command
3. Complete task with currently available tools (degraded execution)

---

## 3. Service Selection

| Service | Trigger | Purpose |
|---------|---------|---------|
| **sequential-thinking** | Decompose complex problems, evaluate options | Structured plans & milestones |
| **context7** | Query library/framework docs, API usage | Latest technical documentation |
| **claudecode-mcp-async** | Call Claude Code from Codex/Gemini | Cross-agent async collaboration |
| **codex-mcp-async** | Call Codex from Claude/Gemini | Cross-agent async collaboration |
| **gemini-cli-mcp-async** | Call Gemini from Claude/Codex | Cross-agent async collaboration |
| **github** | Search repos/code, manage Issues/PRs | GitHub platform search & management |
| **google-developer-knowledge** | Query Google product docs (Android, Firebase, Cloud, Maps) | Google official developer docs |
| **jetbrains** | IDE operations (navigate, refactor, run configs) | JetBrains IDE integration (SSE) |
| **auggie-mcp** (codebase-retrieval) | Understand local architecture, trace call chains | AI semantic code search |

For detailed usage guide of each service, see `mcp-services` skill.

---

## 4. Search Tool Quick Reference

| Scenario | Recommended Tool |
|----------|-----------------|
| Understand business flow / architecture | `codebase-retrieval` |
| Explore unknown code (no keywords) | `codebase-retrieval` |
| Exact symbol reference search | `grep` |
| Find TODO / FIXME | `grep` |
| Find config values / constants | `grep` |
| Cross-language call chain tracing | `codebase-retrieval` |
| Pre-rename reference check | `grep` |
| IDE navigation / refactoring / run | `jetbrains` |
| IDE code inspection | `jetbrains` |
| Google product docs (Android, Firebase, Cloud) | `google-developer-knowledge` |
| Non-Google third-party library docs | `context7` |

---

## 5. Failure Degradation

### 5.1 General Principles

- On primary service failure, try fallback service
- On total failure, provide conservative local answer with uncertainty noted

### 5.2 Per-Service Fallbacks

| Service | Fallback |
|---------|----------|
| `context7` | `google-developer-knowledge` (for Google products) or Agent knowledge + `WebSearch` |
| `google-developer-knowledge` | `context7` (if coverage overlaps) or Agent knowledge + `WebSearch` |
| `github` | `gh` CLI (`gh api`, `gh search`, `gh pr`) |
| `auggie-mcp` (codebase-retrieval) | `grep` + file reading + IDE index search |
| `jetbrains` | See `jetbrains-mcp.md` §5 degradation strategy |
| `sequential-thinking` | Agent internal reasoning (no external tool) |
| `async-mcp` (cross-agent) | Current Agent completes task independently |
