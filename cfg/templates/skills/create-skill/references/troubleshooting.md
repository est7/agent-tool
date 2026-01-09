# Troubleshooting

## View and Test Skills

To see which Skills Claude has access to, ask: "What Skills are available?"

To test a Skill, ask Claude to do a task that matches the Skill's description. Claude automatically uses the Skill when the request matches.

---

## Skill Not Triggering

**Problem:** Claude doesn't use your Skill when it should.

**Solution:** Improve your description field.

The description is how Claude decides whether to use your Skill. Vague descriptions don't give enough information.

A good description answers:
1. **What does this Skill do?** List specific capabilities
2. **When should Claude use it?** Include trigger terms users would mention

**Bad:**
```yaml
description: Helps with documents
```

**Good:**
```yaml
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
```

---

## Skill Doesn't Load

**Problem:** Skill isn't available even though the file exists.

**Check the file path.** Skills must be in the correct directory with exact filename `SKILL.md` (case-sensitive):

| Type       | Path                                 |
|:-----------|:-------------------------------------|
| Personal   | `~/.claude/skills/my-skill/SKILL.md` |
| Project    | `.claude/skills/my-skill/SKILL.md`   |
| Plugin     | `skills/my-skill/SKILL.md` inside plugin directory |

**Check the YAML syntax.** Invalid YAML prevents loading:
- Frontmatter must start with `---` on line 1 (no blank lines before it)
- Frontmatter must end with `---` before markdown content
- Use spaces for indentation (not tabs)

**Run debug mode:**
```bash
claude --debug
```

This shows Skill loading errors.

---

## Skill Has Errors

**Problem:** Skill loads but fails during execution.

**Check dependencies are installed.** If your Skill uses external packages, they must be installed before Claude can use them.

**Check script permissions.** Scripts need execute permissions:
```bash
chmod +x scripts/*.py
```

**Check file paths.** Use forward slashes (Unix style) in all paths:
- Good: `scripts/helper.py`
- Bad: `scripts\helper.py`

---

## Multiple Skills Conflict

**Problem:** Claude uses the wrong Skill or seems confused between similar Skills.

**Solution:** Make each description distinct with specific trigger terms.

Instead of two Skills with "data analysis" in both descriptions, differentiate them:
- One for "sales data in Excel files and CRM exports"
- Another for "log files and system metrics"

The more specific your trigger terms, the easier for Claude to match the right Skill.

---

## Plugin Skills Not Appearing

**Problem:** You installed a plugin, but its Skills don't appear when asking "What Skills are available?"

**Solution:** Clear the plugin cache and reinstall:

```bash
rm -rf ~/.claude/plugins/cache
```

Restart Claude Code and reinstall the plugin:
```bash
/plugin install plugin-name@marketplace-name
```

**If Skills still don't appear**, verify the plugin's directory structure:

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json
└── skills/
    └── my-skill/
        └── SKILL.md
```

Skills must be in a `skills/` directory at the plugin root.

---

## YAML Frontmatter Errors

**Common mistakes:**

**Missing required fields:**
```yaml
# Wrong - missing description
---
name: my-skill
---
```

**Invalid name format:**
```yaml
# Wrong - uppercase and spaces not allowed
---
name: My Skill Name
---

# Correct
---
name: my-skill-name
---
```

**Reserved words:**
```yaml
# Wrong - cannot use "claude" or "anthropic"
---
name: claude-helper
---
```

**Wrong person in description:**
```yaml
# Wrong - uses first/second person
---
description: I help you process PDFs
---

# Correct - third person
---
description: Processes PDF files for text extraction
---
```
