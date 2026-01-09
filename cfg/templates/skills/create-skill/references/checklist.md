# Pre-Release Checklist

Before sharing a Skill, verify these items.

---

## Core Quality

- [ ] **Description is specific** - includes key terms and trigger context
- [ ] **Description includes both** what the Skill does AND when to use it
- [ ] **Description uses third person** - "Processes files" not "I help you"
- [ ] **Name follows conventions** - lowercase letters, numbers, hyphens only
- [ ] **Name uses gerund form** - e.g., `processing-pdfs` not `pdf-processor`
- [ ] **SKILL.md body under 500 lines**
- [ ] **Additional details in separate files** (if needed)
- [ ] **No time-sensitive information** (or in "old patterns" section)
- [ ] **Consistent terminology** throughout
- [ ] **Examples are concrete** - not abstract
- [ ] **File references one level deep** from SKILL.md
- [ ] **Progressive disclosure used** appropriately
- [ ] **Workflows have clear steps**

---

## Frontmatter Validation

- [ ] **name** - max 64 chars, lowercase/numbers/hyphens only
- [ ] **name** - no XML tags, no reserved words (anthropic, claude)
- [ ] **description** - non-empty, max 1024 chars
- [ ] **description** - no XML tags, written in third person
- [ ] **allowed-tools** (if used) - valid tool names
- [ ] **model** (if used) - valid model ID
- [ ] **context** (if used) - only valid value is `fork`
- [ ] **agent** (if used) - valid agent type, only with `context: fork`
- [ ] **hooks** (if used) - valid hook structure

---

## Code and Scripts

- [ ] **Scripts solve problems** rather than punt to Claude
- [ ] **Error handling is explicit** and helpful
- [ ] **No "voodoo constants"** - all values justified with comments
- [ ] **Required packages listed** in instructions and verified as available
- [ ] **Scripts have clear documentation**
- [ ] **No Windows-style paths** - all forward slashes
- [ ] **Validation/verification steps** for critical operations
- [ ] **Feedback loops included** for quality-critical tasks

---

## Testing

- [ ] **At least three test scenarios** created
- [ ] **Tested with Haiku, Sonnet, and Opus** (if supporting multiple models)
- [ ] **Tested with real usage scenarios**
- [ ] **Team feedback incorporated** (if applicable)

---

## File Structure

- [ ] **SKILL.md exists** in skill root directory
- [ ] **Directory name matches** skill name in frontmatter
- [ ] **No extraneous files** (README.md, CHANGELOG.md, etc.)
- [ ] **References organized** by domain or function
- [ ] **Scripts are executable** (`chmod +x`)

---

## Distribution Ready

- [ ] **LICENSE.txt included** (if distributing)
- [ ] **Skill packaged** with `package_skill.py`
- [ ] **Package validated** without errors
