# Workflow Patterns

## Sequential Workflows

For complex tasks, break operations into clear, sequential steps. Give Claude an overview of the process towards the beginning of SKILL.md:

```markdown
Filling a PDF form involves these steps:

1. Analyze the form (run analyze_form.py)
2. Create field mapping (edit fields.json)
3. Validate mapping (run validate_fields.py)
4. Fill the form (run fill_form.py)
5. Verify output (run verify_output.py)
```

## Conditional Workflows

For tasks with branching logic, guide Claude through decision points:

```markdown
1. Determine the modification type:
   **Creating new content?** → Follow "Creation workflow" below
   **Editing existing content?** → Follow "Editing workflow" below

2. Creation workflow: [steps]
3. Editing workflow: [steps]
```

**Tip**: If workflows become large with many steps, push them into separate files and tell Claude to read the appropriate file based on the task.

## Checklist Pattern

For complex, multi-step tasks, provide a checklist that Claude can copy and track progress:

```markdown
## PDF form filling workflow

Copy this checklist and check off items as you complete them:

Task Progress:
- [ ] Step 1: Analyze the form (run analyze_form.py)
- [ ] Step 2: Create field mapping (edit fields.json)
- [ ] Step 3: Validate mapping (run validate_fields.py)
- [ ] Step 4: Fill the form (run fill_form.py)
- [ ] Step 5: Verify output (run verify_output.py)

**Step 1: Analyze the form**

Run: `python scripts/analyze_form.py input.pdf`

This extracts form fields and their locations, saving to `fields.json`.

[Continue with detailed step instructions...]
```

The checklist helps both Claude and users track progress through multi-step workflows.

**When to use checklists:**
- Tasks with 4+ sequential steps
- Operations where skipping a step causes problems
- Workflows that may be interrupted and resumed

## Feedback Loops Pattern

For quality-critical tasks, implement validation loops: run validator → fix errors → repeat.

This pattern greatly improves output quality.

**Example 1: Style guide compliance (for Skills without code):**

```markdown
## Content review process

1. Draft content following the guidelines in STYLE_GUIDE.md
2. Review against the checklist:
   - Check terminology consistency
   - Verify examples follow the standard format
   - Confirm all required sections are present
3. If issues found:
   - Note each issue with specific section reference
   - Revise the content
   - Review the checklist again
4. Only proceed when all requirements are met
5. Finalize and save the document
```

**Example 2: Document editing (for Skills with code):**

```markdown
## Document editing process

1. Make your edits to `word/document.xml`
2. **Validate immediately**: `python ooxml/scripts/validate.py unpacked_dir/`
3. If validation fails:
   - Review the error message carefully
   - Fix the issues in the XML
   - Run validation again
4. **Only proceed when validation passes**
5. Rebuild: `python ooxml/scripts/pack.py unpacked_dir/ output.docx`
6. Test the output document
```

The validation loop catches errors early.

**When to use feedback loops:**
- Batch operations
- Destructive changes
- Complex validation rules
- High-stakes operations

**Implementation tip**: Make validation scripts verbose with specific error messages like "Field 'signature_date' not found. Available fields: customer_name, order_total, signature_date_signed" to help Claude fix issues.

## Plan-Validate-Execute Pattern

When Claude performs complex, open-ended tasks, it can make mistakes. The "plan-validate-execute" pattern catches errors early by having Claude:

1. Create a plan in a structured format (e.g., `changes.json`)
2. Validate that plan with a script before executing it
3. Only then apply the changes

**Example**: Updating 50 form fields in a PDF based on a spreadsheet:

```markdown
## Form update workflow

1. **Analyze**: Run `analyze_form.py` to extract current fields
2. **Create plan**: Generate `changes.json` mapping spreadsheet data to form fields
3. **Validate plan**: Run `validate_changes.py changes.json`
   - Checks all referenced fields exist
   - Validates data types match
   - Ensures no conflicting values
4. **Execute**: Only if validation passes, run `apply_changes.py`
5. **Verify**: Run `verify_output.py` on the result
```

**Why this pattern works:**
- Catches errors early before changes are applied
- Machine-verifiable validation provides objective checks
- Claude can iterate on the plan without touching originals
- Clear debugging with specific error messages
