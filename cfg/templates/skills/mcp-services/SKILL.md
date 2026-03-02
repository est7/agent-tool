---
name: mcp-services
description: Detailed usage guides for MCP services (Sequential Thinking, Context7, Async MCP, GitHub, Google Developer Knowledge, Codebase Retrieval) and multi-tool collaboration patterns. Use when you need guidance on how to use a specific MCP service or combine multiple MCP services for complex tasks.
---

# MCP Service Usage Guides

Detailed guides for each MCP service. For decision flow and service selection, see `mcp.md`.

---

## 1. Sequential Thinking

Structured reasoning tool that decomposes complex problems into executable linear steps.

**When to use:**
- Multi-step task decomposition and ordering (e.g., refactoring plan, migration plan)
- Multi-option trade-off evaluation (need pros/cons before deciding)
- Risk identification and mitigation planning
- Root cause analysis during debugging

**When NOT to use:**
- Single-step simple tasks (just do it)
- Clear approach already decided, no trade-offs needed
- Pure information query (use `context7` or `codebase-retrieval`)

**Constraints:**
- 6-10 steps max, one sentence per step
- Output executable plan, do not expose intermediate reasoning
- Steps maintain linear dependency, avoid parallel branches

---

## 2. Context7

Technical documentation retrieval via `@upstash/context7-mcp`. Gets latest official docs for libraries/frameworks.

**When to use:**
- Query third-party library API usage and parameter signatures
- Confirm latest version breaking changes or new features
- Get official best practices and configuration
- Compare API differences between versions

**When NOT to use:**
- Query project's own code (use `codebase-retrieval`)
- General programming concepts (Agent's own knowledge is sufficient)
- Non-public internal docs or private APIs

**Constraints:**
- When using third-party libraries, **query Context7 first** to prevent generating outdated/non-existent APIs
- Workflow: `resolve-library-id` → `get-library-docs`
- Specify library name and version for accuracy
- Prioritize for features after Agent's knowledge cutoff date

**Choosing between Context7 and Google Developer Knowledge:**

| Query Target | Choose |
|-------------|--------|
| Google products (Android SDK, Firebase, Cloud, Maps, TensorFlow) | `google-developer-knowledge` |
| Non-Google libraries (OkHttp, React, Spring) | `context7` |
| Both involved (e.g., Retrofit + Firebase Auth) | Query each with its specialized tool |

---

## 3. Async MCP (Cross-Agent Collaboration)

Async invocation between different Agent CLIs via uvx, no extra config needed.

| Service | Direction | Best for |
|---------|-----------|----------|
| `claudecode-mcp-async` | Codex/Gemini → Claude Code | Deep code understanding, complex refactoring design |
| `codex-mcp-async` | Claude/Gemini → Codex | Code generation, rapid prototyping, batch modifications |
| `gemini-cli-mcp-async` | Claude/Codex → Gemini | Large context tasks, multimodal analysis (images/docs) |

**When to use:**
- Task exceeds current Agent's capability boundary (e.g., context window insufficient)
- Need different Agent's differential advantage
- Parallel processing of independent subtasks
- Second opinion / verification from another Agent

**When NOT to use:**
- Simple tasks current Agent can handle independently
- Real-time interactive scenarios (async has latency)
- Sensitive information that shouldn't cross Agent boundaries

---

## 4. GitHub MCP

Official MCP service via [github/github-mcp-server](https://github.com/github/github-mcp-server). Requires `GITHUB_PERSONAL_ACCESS_TOKEN`.

### Core Tools

| Category | Key Tools | Description |
|----------|-----------|-------------|
| **Code search** | `search_code` | Search code across GitHub with search syntax |
| **Repo discovery** | `search_repositories` | Find repos by keywords, language, stars |
| **Code reading** | `get_file_contents`, `get_repository_tree` | Browse repo structure and file content |
| **Commit history** | `list_commits`, `get_commit` | View commits and diffs |
| **Issue/PR** | `search_issues`, `search_pull_requests`, `create_pull_request` | Search and manage Issues/PRs |
| **Security** | `list_code_scanning_alerts`, `list_dependabot_alerts` | Code security and dependency alerts |
| **Actions** | `actions_list`, `actions_get`, `get_job_logs` | CI/CD workflow status and logs |

### Common Scenarios

**Finding similar open-source libraries:**
1. `search_repositories` by keyword + language + min stars
2. `get_file_contents` to read README and core code
3. `list_commits` to judge project activity

**Learning implementation patterns:**
1. `search_code` to find specific API/pattern usage in quality repos
2. `get_repository_tree` for project structure, then `get_file_contents` for specifics
3. `get_commit` to see how features were introduced incrementally

**When NOT to use:**
- Searching project's own code (use `codebase-retrieval`)
- Querying library official docs (use `context7`)
- Pure local tasks with no GitHub data needs

---

## 5. Google Developer Knowledge

Google's remote MCP service (HTTP), authenticated via `GOOGLE_DEVELOPER_KNOWLEDGE_API_KEY`.

### Tools

| Tool | Description |
|------|-------------|
| `search_documents` | Search Google developer docs, returns snippets + URLs |
| `get_document` | Get full document content by `parent` field |
| `batch_get_documents` | Batch get up to 20 documents (prefer over multiple `get_document`) |

### Coverage

Android, Firebase, Google Cloud, Chrome, Google AI, Google Maps/Ads/Search/YouTube, Google Home, TensorFlow, Web (web.dev), Apigee, Fuchsia

### Constraints

- **English results only**
- **Public docs only** (no GitHub, OSS sites, blogs, YouTube)
- **Network dependent** (requires Google Cloud online service)
- **Recommended workflow**: `search_documents` first → `get_document`/`batch_get_documents` for full text when needed

---

## 6. Codebase Retrieval (auggie-mcp)

AI semantic code search engine with natural language queries, cross-language retrieval, real-time indexing.

### When to Use (prefer over grep)

- **Understand business flow / architecture**: "Where is user authentication implemented?"
- **Trace call chains**: understand module responsibilities, business flow entry points
- **Pre-edit context**: before modifying code, query all involved classes/functions/properties

### When NOT to Use (use grep / IDE instead)

- Exact class/function definition lookup (e.g., `class Foo`)
- Find all references to a function
- View full file content
- Exact string/constant matching (UUID, config values, error messages)
- Code comment tag search (TODO, FIXME, HACK)

### Pre-Edit Deep Query Protocol

Before editing any file, **must** call codebase-retrieval for context:

| Rule | Description |
|------|-------------|
| **Full query** | Ask about all symbols involved in the edit in one call |
| **One-shot** | Don't make multiple calls unless new info requires clarification |
| **Include when in doubt** | Unsure if a symbol is relevant? Include it |
| **Position weighting** | Important symbols at end of query work best |

**Example:**
- Good: "I need to modify UserService.login(). Provide: UserService class definition, login method implementation, AuthProvider interface and TokenManager methods it calls"
- Bad: Querying each symbol separately in multiple calls

---

## 7. Multi-Tool Collaboration Patterns

### 7.1 Tech Selection Research

```
github (search_repositories) → context7 / google-developer-knowledge → sequential-thinking
  Discover candidates          Query API docs (by product)              Weigh pros/cons, decide
```

### 7.2 New Codebase Onboarding

```
codebase-retrieval → github (search_code) → context7 / google-developer-knowledge
  Understand local arch  Find similar implementations   Query dependency docs
```

### 7.3 Complex Feature Planning

```
codebase-retrieval → sequential-thinking → async-mcp (optional)
  Survey existing code    Plan steps              Delegate subtasks to other Agents
```

### 7.4 Bug Investigation

```
codebase-retrieval → github (search_issues) → context7 / google-developer-knowledge
  Locate problem code     Search known issues       Query correct API usage
```
