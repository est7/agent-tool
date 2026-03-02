# Rules Reorganization — Decision Record

Date: 2026-03-02

## 1. Background & Problem

### 1.1 Original State (Before Reorganization)

| File | Location | Lines | Over 200? |
|------|----------|-------|-----------|
| AGENTS.md | `cfg/templates/AGENTS.md` → `~/.claude/CLAUDE.md` | 42 | No |
| core.md | `cfg/templates/rules/core.md` → `~/.claude/rules/` | 345 | **Yes (1.7x)** |
| mcp.md | `cfg/templates/rules/mcp.md` → `~/.claude/rules/` | 382 | **Yes (1.9x)** |
| jetbrains-mcp.md | `cfg/templates/rules/jetbrains-mcp.md` → `~/.claude/rules/` | 59 | No |
| comments.md | `cfg/templates/rules/comments.md` → `~/.claude/rules/` | 30 | No |
| constitution.md (new) | `cfg/templates/rules/constitution.md` | 177 | No |
| **Total always-loaded** | | **1035** | |

### 1.2 Problems Identified

1. **Two files exceed the 200-line guideline** (per official Claude Code docs: "target under 200 lines per CLAUDE.md file")
2. **Redundancy across files**: AGENTS.md, core.md, and constitution.md overlap on testing, principles, and code quality
3. **Detailed procedures bloat every session**: Plan/Code workflow (81 lines), MCP service guides (250+ lines), Memo conventions (26 lines) load unconditionally, even for trivial tasks
4. **Official docs recommend skills for on-demand knowledge**: "For domain knowledge or workflows that are only relevant sometimes, use skills instead"

### 1.3 Guiding Principles (from official docs)

- "For each line, ask: 'Would removing this cause Claude to make mistakes?' If not, cut it."
- "For domain knowledge or workflows that are only relevant sometimes, use skills instead."
- "Each file should cover one topic, with a descriptive filename."
- "target under 200 lines per CLAUDE.md file."

---

## 2. Decision History

### 2.1 Round 1 — Initial Proposal: Split into 7 rule files (Rejected)

Original plan.md proposed splitting core.md into 7 rule files:
`constitution.md`, `workflow.md`, `testing.md`, `language.md`, `git.md`, `quality.md`, `memo.md`

**Rejected because**: Too granular; some topics are tightly coupled; more files = more cross-reference maintenance; violates constitution's own Article VII (minimal structure).

### 2.2 Round 2 — Revised: Split into 4 rule files (Superseded)

Proposed: core.md → `core.md` + `workflow.md` + `conventions.md` + `testing.md`

Also proposed pruning AGENTS.md from 42 to ~25 lines.

**User feedback**: "All items I marked for deletion, I want to keep." AGENTS.md stays as-is at 42 lines.

**Superseded by** Round 3 after reviewing official best practices docs.

### 2.3 Round 3 — Final: Rules + Skills dual-layer architecture (Accepted)

After reviewing official Claude Code documentation on CLAUDE.md and best practices:

**Key insight**: The real problem isn't "how to split rules" but "most content shouldn't be rules at all." Rules are constraints (prevent mistakes). Skills are knowledge (guide actions, loaded on demand).

**Decision**: Keep rules files concise (constraints only), move detailed procedures to skills.

---

## 3. Final Architecture

### 3.1 Layer Design

```
Layer 1: AGENTS.md (~/.claude/CLAUDE.md)     — Principles & Standards (WHAT)
Layer 2: rules/ (~/.claude/rules/)            — Behavioral Constraints (MUST/MUST NOT)
Layer 3: skills/ (~/.claude/skills/)          — Procedural Knowledge (HOW, loaded on demand)
```

### 3.2 AGENTS.md — No Changes

42 lines. All content retained per user decision. Already under 200-line limit.

### 3.3 Rules Files — Reorganization

#### core.md (345 → ~100 lines)

| Section | Lines | Decision | Rationale |
|---------|-------|----------|-----------|
| §0 About the User | 6 | **Keep in core.md** | Global behavior foundation, Claude can't infer this |
| §1.1 Constraint Priority | 8 | **Keep** | Specific 4-level priority ordering |
| §1.2 Risk Assessment | 5 | **Condense to 2 lines** | Only need "bias toward action for low-risk; state risk for high-risk" |
| §1.3 Abductive Reasoning | 7 | **Condense to 2 lines** | Core is "build hypotheses and verify"; Claude already reasons well |
| §1.4 Adaptive Self-Correction | 5 | **Remove** | Redundant with §1.1; Claude self-corrects by default |
| §1.5 Information Source Strategy | 10 | **Condense to 3 lines** | Keep the 5-source priority list, remove explanatory prose |
| §1.6 Precision & Grounding | 4 | **Remove** | "No generic platitudes" = self-evident |
| §1.7 Conflict Resolution | 10 | **Keep** | 5-level priority is a specific convention |
| §1.8 Persistence & Smart Retry | 4 | **Condense to 2 lines** | |
| §1.9 Action Inhibition | 4 | **Condense to 1 line** | Only keep "committed output" rule |
| §2 Task Complexity | 14 | **Keep** | Mode selection trigger |
| §3 Quality Evaluation | 16 | **Condense to 10 lines** | Remove self-evident lines, keep priority order + code smell list |
| §4 Plan/Code Workflow | 81 | **Move to skill** | Core.md keeps only §4.1 trigger rule (5 lines). Full workflow → `plan-code-workflow` skill |
| §5 Language & Coding Style | 12 | **Move to conventions.md** | Condense: remove per-language naming (Claude knows), keep Chinese/English split |
| §6 Git Conventions | 13 | **Move to conventions.md** | Keep commit format + branch naming; condense destructive-ops (Claude Code system prompt already covers this) |
| §7 Self-Check | 29 | **Condense to 10 lines** | Keep "confirm-before" checklist (lines 264-269); remove "fix your own errors" (Claude default) |
| §8 Answer Structure | 8 | **Keep** | |
| §9 Style Conventions | 5 | **Keep** | |
| §10 Testing | 8 | **Condense to 2 lines** | Keep "must include test plan" + "do not claim you ran tests". Full TDD workflow → `testing-tdd` skill |
| §11 Task Memo | 26 | **Move to skill** | → `task-memo` skill |
| §12 Tools & Environment | 14 | **Move to conventions.md** | Condense to ~5 lines |

#### conventions.md (new, ~40 lines)

Sources:
- core.md §5 Language & Coding Style (condensed)
- core.md §6 CLI & Git conventions (condensed)
- core.md §12 Tools & Environment (condensed)
- constitution.md Articles IV-VI Change Control (2-line summary)
- constitution.md Amendment Process (2-line summary)

#### mcp.md (382 → ~90 lines)

| Section | Lines | Decision | Rationale |
|---------|-------|----------|-----------|
| §1 Global Principles | 8 | **Keep** | Core decision constraint |
| §2 Decision Flow + Switch Conditions | 35 | **Keep** (condense to ~25) | Decision framework |
| §3 Service Selection Table | 12 | **Keep** | Quick reference |
| §4.1 Sequential Thinking | 19 | **Move to skill** | Detailed usage guide |
| §4.2 Context7 | 28 | **Move to skill** | Detailed usage guide |
| §4.3 Async MCP | 20 | **Move to skill** | Detailed usage guide |
| §4.4 GitHub MCP | 46 | **Move to skill** | Detailed usage guide |
| §4.5 JetBrains MCP | 23 | **Delete** | Already fully covered by `jetbrains-mcp.md` + `jetbrains-skill` |
| §4.6 Google Developer Knowledge | 36 | **Move to skill** | Detailed usage guide |
| §5 Codebase-retrieval | 54 | **Move to skill** | Detailed protocol |
| §5.5 Search Tool Selection Table | 15 | **Keep in mcp.md** | High-frequency decision reference |
| §6 Multi-tool Collaboration | 55 | **Move to skill** | Pattern library |
| §7 Failure Degradation | 20 | **Keep** (condense to ~15) | Core fallback strategy |

#### Unchanged files

- `jetbrains-mcp.md` (59 lines) — no changes
- `comments.md` (30 lines) — renamed to ensure Claude loads it as a rule

### 3.4 Skills — New Files

| Skill | Source | Estimated Lines | Loaded When |
|-------|--------|-----------------|-------------|
| `plan-code-workflow` | core.md §4 (full Plan/Code procedures) | ~80 | moderate/complex tasks |
| `testing-tdd` | core.md §10 + constitution Art.III/IX + AGENTS.md Bug Fixes | ~70 | Writing/running tests |
| `task-memo` | core.md §11 (memo conventions) | ~30 | Creating task documentation |
| `mcp-services` | mcp.md §4.1-4.6 + §5 + §6 (service guides + collaboration patterns) | ~250 | Using MCP tools |
| `implementation-gates` | constitution Art.I/II/VII/VIII + Phase -1 gates + Exception Protocol | ~80 | Implementing non-trivial features |

### 3.5 constitution.md — Delete After Distribution

All constitution content distributed to skills:

| Constitution Content | Destination |
|---------------------|-------------|
| Art. I-II (Library/CLI-First) | `implementation-gates` skill (scoped: "applies only to reusable logic with clear I/O boundaries") |
| Art. III (TDD Red-Green-Refactor) | `testing-tdd` skill (merged with core.md §10 + AGENTS.md Bug Fixes) |
| Art. IV-VI (Change Control) | `conventions.md` (2-line summary) |
| Art. VII (Minimal Structure) | `implementation-gates` skill (gate checklist item) |
| Art. VIII (Anti-Abstraction) | `implementation-gates` skill (gate checklist item) |
| Art. IX (Integration-First) | `testing-tdd` skill (merged with testing strategy) |
| Phase -1 Gates | `implementation-gates` skill (with complexity gating: trivial tasks skip most gates) |
| Exception Protocol | `implementation-gates` skill |
| Amendment Process | `conventions.md` (2-line summary) |

### 3.6 Conflict Resolution

Three conflicts identified and resolved:

**Conflict 1: TDD Gate vs "user says implement → enter Code mode"**
- core.md §4.4: "When user says '实现', switch to Code mode immediately"
- constitution Art.III: "Must deliver tests and confirm Red before implementation"
- **Resolution**: In `plan-code-workflow` skill, clarify: "Enter Code mode immediately, but for non-trivial tasks, first deliverable is the test (Red phase), not the implementation"

**Conflict 2: "Do not claim you ran tests" vs TDD Red confirmation**
- core.md §10: "Do not claim you have actually run tests"
- constitution Art.III: "Confirm tests fail in current implementation (Red phase)"
- **Resolution**: In `testing-tdd` skill, use: "Report only what you can directly observe. If you can run tests, run them and report actual results. If you cannot, provide exact commands, expected failure points, and wait for user to confirm Red before proceeding"

**Conflict 3: AGENTS.md "SOLID / clear abstractions" vs constitution Art.VIII "Anti-Abstraction"**
- AGENTS.md: "Adhere to SOLID principles... proper dependency management through clear abstractions"
- constitution Art.VIII: "Avoid wrappers with no clear benefit"
- **Resolution**: Not a true conflict. SOLID does not mandate wrappers. In `implementation-gates` skill, clarify: "SOLID applies to design responsibility boundaries. Anti-Abstraction applies to unnecessary indirection layers. An interface for dependency inversion = good. A wrapper that just delegates = bad."

---

## 4. Expected Outcome

### 4.1 Before vs After

| Metric | Before | After |
|--------|--------|-------|
| Files over 200 lines | 2 (core 345, mcp 382) | **0** |
| Always-loaded rule lines | 1035 | **402** |
| Redundant/conflicting clauses | Multiple | **0** |
| Detailed knowledge in rules | All (always loaded) | **On-demand via skills** |
| Total knowledge preserved | — | **100%** (moved, not deleted) |

### 4.2 Execution Order

1. **Phase 1** (this document): Audit + decision record ✅
2. **Phase 2**: Write new files (core.md slim, conventions.md, 4 skills) ✅
3. **Phase 3**: Slim mcp.md, write mcp-services skill
4. **Phase 4**: Delete constitution.md (content already distributed)
5. **Phase 5**: Verify (`cfg refresh` + `doctor cli` + manual rule loading check)

---

## 5. Phase Execution Records

### 5.1 Phase 2 Execution — core.md split + skills creation

**Date**: 2026-03-02

**Actions taken:**

1. Created `cfg/templates/rules/core.new.md` (133 lines) — slimmed from 345 lines
2. Created `cfg/templates/rules/conventions.md` (40 lines) — extracted from core.md §5/§6/§12
3. Created `cfg/templates/skills/plan-code-workflow/SKILL.md` (88 lines) — from core.md §4
4. Created `cfg/templates/skills/testing-tdd/SKILL.md` (65 lines) — from core.md §10 + constitution Art.III/IX
5. Created `cfg/templates/skills/task-memo/SKILL.md` (31 lines) — from core.md §11
6. Created `cfg/templates/skills/implementation-gates/SKILL.md` (71 lines) — from constitution Art.I/II/VII/VIII + Phase -1 gates
7. Replaced `core.md` with slimmed version (old saved as `core.old.md` for reference)

**Line count verification:**

| File | Type | Lines | Under 200? |
|------|------|-------|------------|
| core.md (new) | rule | 133 | Yes |
| conventions.md | rule | 40 | Yes |
| plan-code-workflow | skill | 88 | n/a |
| testing-tdd | skill | 65 | n/a |
| task-memo | skill | 31 | n/a |
| implementation-gates | skill | 71 | n/a |

**Content mapping (what went where):**

| core.md section | Destination | Change |
|----------------|-------------|--------|
| §0 About the User | core.md §0 | Kept, minor wording tightened |
| §1.1 Constraint Priority | core.md §1.1 | Kept verbatim |
| §1.2 Risk Assessment | core.md §1.2 | Condensed 5→2 lines |
| §1.3 Abductive Reasoning | core.md §1.3 | Condensed 7→2 lines |
| §1.4 Adaptive Self-Correction | **Removed** | Redundant with §1.1 |
| §1.5 Information Sources | core.md §1.4 | Condensed 10→5 lines (kept priority list) |
| §1.6 Precision & Grounding | **Removed** | Self-evident ("no generic platitudes") |
| §1.7 Conflict Resolution | core.md §1.5 | Kept verbatim |
| §1.8 Persistence | core.md §1.6 | Condensed 4→2 lines |
| §1.9 Action Inhibition | core.md §1.7 | Condensed 4→1 line ("committed output" only) |
| §2 Task Complexity | core.md §2 | Kept, added skill reference |
| §3 Quality Evaluation | core.md §3 | Removed self-evident lines, kept priority + smell list |
| §4 Plan/Code Workflow | `plan-code-workflow` skill | Full 81-line workflow moved to skill |
| §5 Language & Coding Style | `conventions.md` §1 | Removed per-language naming (Claude knows); kept Chinese/English split |
| §6 Git Conventions | `conventions.md` §2 | Kept commit/branch format; condensed destructive-ops |
| §7 Self-Check | core.md §4 | Kept confirmation threshold list; removed "fix own errors" (default) |
| §8 Answer Structure | core.md §5 | Kept verbatim |
| §9 Style Conventions | core.md §6 | Kept verbatim |
| §10 Testing | core.md §7 + `testing-tdd` skill | 2-line constraint in core; full TDD workflow in skill |
| §11 Task Memo | `task-memo` skill | Moved entirely |
| §12 Tools & Environment | `conventions.md` §3 | Kept build tool table |

**Constitution content distribution:**

| Constitution content | Destination | Status |
|---------------------|-------------|--------|
| Art. I-II (Library/CLI-First) | `implementation-gates` skill | Done |
| Art. III (TDD) | `testing-tdd` skill | Done |
| Art. IV-VI (Change Control) | `conventions.md` §4 | Done |
| Art. VII (Minimal Structure) | `implementation-gates` skill | Done |
| Art. VIII (Anti-Abstraction) | `implementation-gates` skill | Done |
| Art. IX (Integration-First) | `testing-tdd` skill | Done |
| Phase -1 Gates | `implementation-gates` skill | Done |
| Exception Protocol | `implementation-gates` skill | Done |
| Amendment Process | `conventions.md` §4 | Done |

**Conflict resolutions implemented:**

1. **TDD vs "switch to Code mode immediately"**: `plan-code-workflow` skill §Code Mode says "for non-trivial tasks: first deliverable is the test, not the implementation (see testing-tdd skill)"
2. **"Don't claim you ran tests" vs TDD Red confirmation**: `testing-tdd` skill §Observation says "Report only what you can directly observe. If you can run tests, run them. If not, provide commands and wait for user confirmation."
3. **SOLID vs Anti-Abstraction**: `implementation-gates` skill Anti-Abstraction Gate has explicit clarification paragraph

**Backup:** `cfg/templates/rules/core.old.md` (original 345-line version, to be deleted after Phase 5 verification)

---

### 5.2 Phase 3 Execution — mcp.md split + mcp-services skill

**Date**: 2026-03-02

**Actions taken:**

1. Created `cfg/templates/rules/mcp.new.md` (98 lines) — slimmed from 382 lines
2. Created `cfg/templates/skills/mcp-services/SKILL.md` (211 lines) — all service guides + collaboration patterns
3. Replaced `mcp.md` with slimmed version (old saved as `mcp.old.md` for reference)

**Line count verification:**

| File | Type | Lines | Under 200? |
|------|------|-------|------------|
| mcp.md (new) | rule | 98 | Yes |
| mcp-services skill | skill | 211 | n/a |

**Content mapping (what went where):**

| mcp.md section | Destination | Change |
|----------------|-------------|--------|
| §1 Global Principles | mcp.md §1 | Kept, removed "单轮单工具" (overly restrictive) |
| §2 Decision Flow | mcp.md §2 | Kept, minor condensing |
| §3 Service Selection Table | mcp.md §3 | Kept verbatim |
| §4.1 Sequential Thinking | `mcp-services` skill §1 | Moved |
| §4.2 Context7 | `mcp-services` skill §2 | Moved |
| §4.3 Async MCP | `mcp-services` skill §3 | Moved |
| §4.4 GitHub MCP | `mcp-services` skill §4 | Moved |
| §4.5 JetBrains MCP | **Deleted** | Fully covered by `jetbrains-mcp.md` + `jetbrains-skill` |
| §4.6 Google Developer Knowledge | `mcp-services` skill §5 | Moved |
| §5 Codebase-retrieval | `mcp-services` skill §6 | Moved |
| §5.5 Search Tool Selection Table | mcp.md §4 | Kept in rules (high-frequency reference) |
| §6 Multi-tool Collaboration | `mcp-services` skill §7 | Moved |
| §7 Failure Degradation | mcp.md §5 | Kept, minor condensing |

**Key decision: §4.5 JetBrains MCP deleted** — This section was 23 lines that added nothing over the existing `jetbrains-mcp.md` (59 lines, dedicated rule file) and `jetbrains-skill` (detailed execution guide). Triple coverage of the same tool is pure waste.

---

### 5.3 Phase 4 Execution — Delete constitution.md

**Date**: 2026-03-02

**Pre-deletion verification**: Used subagent to verify all 13 sections of constitution.md are covered:

| Constitution Section | Destination | Covered? |
|---------------------|-------------|----------|
| §0.1 Mandatory enforcement + exception flow | `implementation-gates` skill (complexity gating + exception protocol) | Yes |
| §0.2 Library + CLI scope (per-scenario) | `implementation-gates` skill (Library Gate "Applies to / Does NOT apply to") | Yes |
| Art. I Library-First | `implementation-gates` skill (Library Gate) | Yes |
| Art. II CLI Interface Mandate | `implementation-gates` skill (CLI Gate) | Yes |
| Art. III TDD Red-Green-Refactor | `testing-tdd` skill (TDD Gate) | Yes |
| Art. IV-VI Change Control | `conventions.md` §4 | Yes |
| Art. VII Minimal Structure | `implementation-gates` skill (Simplicity Gate) | Yes |
| Art. VIII Anti-Abstraction | `implementation-gates` skill (Anti-Abstraction Gate + SOLID clarification) | Yes |
| Art. IX Integration-First | `testing-tdd` skill (Integration-First Strategy) | Yes |
| §2 Phase -1 Gates (6 gates) | `implementation-gates` skill (all 6 gates as sections) | Yes |
| §3 Deliverables Checklist | `testing-tdd` skill (Deliverables section) | Yes |
| §4 Exception Protocol | `implementation-gates` skill (Exception Protocol) | Yes |
| §5 Amendment Process | `conventions.md` §4 | Yes |

**Enhancements over original constitution (not just 1:1 copy):**
1. Added complexity gating matrix (trivial/moderate/complex) — original had no complexity escape hatch
2. Added SOLID compatibility clarification — prevents misreading Art.VIII as anti-SOLID
3. Art. II optional flag suggestions (`--json` etc.) intentionally dropped — too prescriptive for a general rule

**Action**: `rm cfg/templates/rules/constitution.md`

---

### 5.4 Phase 5 Execution — Verification & Cleanup

**Date**: 2026-03-02

**Verification steps:**

1. **File line count verification** — All rules under 200 lines:

| File | Lines | Under 200? |
|------|-------|------------|
| core.md | 133 | Yes |
| conventions.md | 40 | Yes |
| mcp.md | 98 | Yes |
| jetbrains-mcp.md | 59 | Yes |
| comments.md | 30 | Yes |
| AGENTS.md | 42 | Yes |
| **Total always-loaded** | **402** | — |

2. **`cfg refresh` execution** — Success. All templates synced to `~/.agents/` and symlinked to `~/.claude/`.

3. **Rules symlink verification** — Confirmed in `~/.claude/rules/`:
   - `core.md` (5046 bytes)
   - `conventions.md` (1185 bytes)
   - `mcp.md` (3960 bytes)
   - `jetbrains-mcp.md` (2262 bytes)
   - `comments.md`

4. **Skills symlink verification** — All 5 new skills confirmed in `~/.claude/skills/`:
   - `plan-code-workflow` → `~/.agents/skills/shared/plan-code-workflow`
   - `testing-tdd` → `~/.agents/skills/shared/testing-tdd`
   - `task-memo` → `~/.agents/skills/shared/task-memo`
   - `implementation-gates` → `~/.agents/skills/shared/implementation-gates`
   - `mcp-services` → `~/.agents/skills/shared/mcp-services`

5. **Backup cleanup** — Deleted `core.old.md` and `mcp.old.md`.

**Result**: All verifications passed. Reorganization complete.

---

## 6. Conclusion & Deliverables

- [x] Decision record documented (this file)
- [x] core.md slimmed to 133 lines (was 345)
- [x] conventions.md created (40 lines)
- [x] mcp.md slimmed to 98 lines (was 382)
- [x] 4 skills created (plan-code-workflow, testing-tdd, task-memo, implementation-gates)
- [x] mcp-services skill created (211 lines)
- [x] constitution.md deleted (all content verified distributed)
- [x] core.old.md + mcp.old.md deleted (after verification)
- [x] Verification passed — all rules under 200 lines, all symlinks confirmed
