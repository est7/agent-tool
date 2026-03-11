#!/usr/bin/env python3
"""Initialize an enhanced Claude Code skill template."""

from __future__ import annotations

import sys
from pathlib import Path


SKILL_TEMPLATE = """---
name: {skill_name}
description: "TODO: Describe what this skill does and when Claude should use it."
# argument-hint: "[file] [format]"
# disable-model-invocation: true
# user-invocable: false
# allowed-tools: Read, Grep
# model: claude-sonnet-4-20250514
# context: fork
# agent: Explore
# hooks:
#   Stop:
#     - type: command
#       command: "./scripts/report.sh"
---

# {skill_title}

## Overview

TODO: Summarize the skill's purpose in 1-2 sentences. Keep the main instructions focused and move deep details into supporting files when needed.

## Invocation Notes

- Put trigger guidance in the frontmatter `description`, not in the body.
- Use `$ARGUMENTS`, `$ARGUMENTS[N]`, or `$N` when direct invocation should accept arguments.
- Use `${{CLAUDE_SKILL_DIR}}` inside shell commands so bundled files resolve correctly from any working directory.
- Use `!`command`` sparingly when live context must be injected before Claude reads the skill.

## Structuring This Skill

Choose the structure that best fits the skill. Delete any guidance that does not help the final version.

### 1. Workflow-Based

- Best for repeatable step-by-step procedures
- Shape: Overview -> Decision tree -> Step 1 -> Step 2 -> Verification

### 2. Task-Based

- Best for tool collections with several operations
- Shape: Overview -> Quick start -> Task A -> Task B -> Task C

### 3. Reference-Led

- Best for standards, conventions, or domain knowledge
- Shape: Overview -> Rules -> Examples -> Exceptions

### 4. Capability-Based

- Best for integrated systems with several related features
- Shape: Overview -> Capabilities -> Constraints -> Output expectations

## Main Instructions

TODO: Replace this section with the real operating instructions. Good skill content usually includes:

- concrete user intents the skill should handle
- output expectations or templates
- decision points and failure handling
- references to supporting files when more detail is needed

## Supporting Files

This scaffold creates example directories to show the intended resource split. Delete anything the final skill does not need.

### scripts/

Executable helpers for deterministic work, validation, data transformation, or repetitive operations. Claude can run these without loading them into context first.

### references/

Detailed documentation, schemas, examples, or domain guides that Claude should read only when relevant.

### assets/

Templates, sample files, or static resources meant to be used in outputs rather than loaded into context.

## Validation Checklist

- Replace the TODO description with a real trigger-oriented description
- Remove unused commented frontmatter fields
- Move long details into references instead of overgrowing `SKILL.md`
- Make sure any scripts or assets referenced here actually exist
"""

EXAMPLE_SCRIPT = '''#!/usr/bin/env python3
"""Example helper script for {skill_name}."""


def main() -> None:
    print("Replace this helper with a real script or delete it.")


if __name__ == "__main__":
    main()
'''

EXAMPLE_REFERENCE = """# Reference Notes for {skill_title}

Replace this file with the deep reference material for the skill.

Useful things to place here:

- schemas or API details
- long examples
- edge-case handling
- domain-specific terminology
"""

EXAMPLE_ASSET = """This placeholder represents a bundled asset.

Replace it with a real template, sample file, or static resource if the skill needs one.
"""


def title_case_skill_name(skill_name: str) -> str:
    """Convert a hyphenated skill name to Title Case."""
    return " ".join(part.capitalize() for part in skill_name.split("-"))


def validate_skill_name(skill_name: str) -> str | None:
    """Validate a scaffolded skill name."""
    if not skill_name:
        return "Skill name must not be empty."
    if len(skill_name) > 64:
        return "Skill name must be 64 characters or fewer."
    if skill_name.startswith("-") or skill_name.endswith("-") or "--" in skill_name:
        return "Skill name cannot start/end with '-' or contain consecutive hyphens."
    if any(char for char in skill_name if char not in "abcdefghijklmnopqrstuvwxyz0123456789-"):
        return "Skill name must use lowercase letters, digits, and hyphens only."
    return None


def init_skill(skill_name: str, path: str) -> Path | None:
    """Create a new skill directory with an enhanced starter template."""
    error = validate_skill_name(skill_name)
    if error:
        print(f"❌ {error}")
        return None

    skill_dir = Path(path).resolve() / skill_name
    if skill_dir.exists():
        print(f"❌ Error: Skill directory already exists: {skill_dir}")
        return None

    try:
        skill_dir.mkdir(parents=True, exist_ok=False)
        print(f"✅ Created skill directory: {skill_dir}")
    except Exception as exc:  # pragma: no cover - surfaced in CLI
        print(f"❌ Error creating directory: {exc}")
        return None

    skill_title = title_case_skill_name(skill_name)

    try:
        (skill_dir / "SKILL.md").write_text(
            SKILL_TEMPLATE.format(skill_name=skill_name, skill_title=skill_title)
        )
        print("✅ Created SKILL.md")

        scripts_dir = skill_dir / "scripts"
        scripts_dir.mkdir(exist_ok=True)
        example_script = scripts_dir / "example.py"
        example_script.write_text(EXAMPLE_SCRIPT.format(skill_name=skill_name))
        example_script.chmod(0o755)
        print("✅ Created scripts/example.py")

        references_dir = skill_dir / "references"
        references_dir.mkdir(exist_ok=True)
        (references_dir / "guide.md").write_text(EXAMPLE_REFERENCE.format(skill_title=skill_title))
        print("✅ Created references/guide.md")

        assets_dir = skill_dir / "assets"
        assets_dir.mkdir(exist_ok=True)
        (assets_dir / "example_asset.txt").write_text(EXAMPLE_ASSET)
        print("✅ Created assets/example_asset.txt")
    except Exception as exc:  # pragma: no cover - surfaced in CLI
        print(f"❌ Error creating skill contents: {exc}")
        return None

    print(f"\n✅ Skill '{skill_name}' initialized successfully at {skill_dir}")
    print("\nNext steps:")
    print("1. Replace the TODO description and body sections in SKILL.md")
    print("2. Keep only the official frontmatter fields this skill actually uses")
    print("3. Customize or delete the example files in scripts/, references/, and assets/")
    print("4. Run the validator when ready to check the skill structure")

    return skill_dir


def main() -> None:
    if len(sys.argv) < 4 or sys.argv[2] != "--path":
        print("Usage: init_skill.py <skill-name> --path <path>")
        print("\nSkill name requirements:")
        print("  - Lowercase letters, digits, and hyphens only")
        print("  - Maximum 64 characters")
        print("  - Example: data-analyzer")
        print("\nExamples:")
        print("  init_skill.py my-new-skill --path skills/public")
        print("  init_skill.py my-api-helper --path skills/private")
        print("  init_skill.py custom-skill --path /custom/location")
        sys.exit(1)

    skill_name = sys.argv[1]
    target_path = sys.argv[3]

    print(f"🚀 Initializing skill: {skill_name}")
    print(f"   Location: {target_path}")
    print()

    result = init_skill(skill_name, target_path)
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
