# Rules System Plan

Goal: Use a shared rules template system (similar to commands/skills) so different projects can opt into technology-specific rules (Android, iOS, React, Vue, etc.) via symlinks, while keeping the source of truth in this repo.

## 1. Define Rules Template Layout

- Decide on canonical template locations under `cfg/templates/rules/`:
  - `cfg/templates/rules/android/`
  - `cfg/templates/rules/ios/`
  - `cfg/templates/rules/react/`
  - `cfg/templates/rules/vue/`
- Inside each tech folder, define standard subfolders and file naming:
  - `guidelines/*.md` (style, architecture)
  - `testing/*.md` (test conventions, coverage expectations)
  - `requirements/*.md` (checklists, quality gates)
- Ensure each `.md` file follows `agent-rules-spec.md` (optionally using `paths` for scoping).

## 2. Describe Target Layout in User Config (~/.claude/rules/)

- Decide how rules should appear in `~/.claude/rules/`, for example:
  - `~/.claude/rules/android/...`
  - `~/.claude/rules/ios/...`
  - `~/.claude/rules/react/...`
  - `~/.claude/rules/vue/...`
- Clarify that project-specific `.claude/rules/` will typically contain symlinks to these user-level rules or copies, depending on project needs.

## 3. Design cfg Subcommands for Rules Management

- Add a `cfg rules` subcommand family to `agent-tool.sh` (or cfg module), mirroring existing patterns (like `cfg init`, `cfg refresh`):
  - `./agent-tool.sh cfg rules list` — list available rule templates (android/ios/react/vue).
  - `./agent-tool.sh cfg rules install <tech>` — install/symlink rules for a given tech into `~/.claude/rules/<tech>/`.
  - `./agent-tool.sh cfg rules link-project <tech>` — create symlinks from project `.claude/rules/` to the selected `~/.claude/rules/<tech>/` set.
- Decide whether `install` uses copy or symlink:
  - Prefer symlink from `~/.agents/` or `cfg/templates/rules/` → `~/.claude/rules/` to allow central updates.

## 4. Integrate with Existing cfg Install/Symlink Flow

- Review existing `cfg/install_symlinks.sh` behavior:
  - How commands/skills/output-styles are synchronized to `~/.agents/` and then symlinked to Claude/Codex/Gemini.
- Extend this mechanism (or add a parallel path) so rules templates under `cfg/templates/rules/` are:
  - Copied/symlinked into `~/.agents/rules/<tech>/`.
  - From there, symlinked into `~/.claude/rules/<tech>/` when `cfg rules install <tech>` is executed.
- Ensure the design keeps responsibilities clear:
  - `cfg init/refresh` still handle base templates.
  - `cfg rules ...` specifically handles rules selection/installation.

## 5. Define Project-Level Usage Patterns

- Decide on recommended project patterns:
  - Option A: Project `.claude/rules/` contains symlinks pointing to `~/.claude/rules/<tech>/...`.
  - Option B: `cfg rules link-project <tech>` can copy templates into `.claude/rules/<tech>/` when projects need to diverge from the shared rules.
- Document how multiple techs can be combined in one project:
  - Example: a full-stack repo using `rules/react` + `rules/android`.
  - Clarify that `paths` in each rule file should keep scopes from interfering.

## 6. Document Workflow in CLAUDE.md and Specs

- Update `CLAUDE.md` (in this repo) with a short “Rules Workflow” section:
  - Explain that rules templates live under `cfg/templates/rules/`.
  - Describe `cfg rules install` and `cfg rules link-project` workflows at a high level.
- Extend `agent-rules-spec.md` with a brief note about:
  - Template origin (`cfg/templates/rules/`).
  - User-level location (`~/.claude/rules/`).
  - Recommended project `.claude/rules/` usage pattern (symlinks vs copies).

## 7. Implementation & Validation Steps (Later)

- After plan approval:
  - Implement `cfg rules` subcommands and wiring.
  - Create initial rule templates for at least one tech (e.g., `react`) as a reference.
  - Manually verify:
    - Rules appear in `~/.claude/rules/` as expected.
    - Project `.claude/rules/` symlinks/copies are created correctly.
    - Claude Code loads the rules (via `/memory`) and applies `paths` scoping correctly.

