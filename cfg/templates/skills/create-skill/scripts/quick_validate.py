#!/usr/bin/env python3
"""Validate SKILL.md frontmatter against the supported skill schema."""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path


SUPPORTED_FIELDS = {
    "name",
    "description",
    "argument-hint",
    "disable-model-invocation",
    "user-invocable",
    "allowed-tools",
    "model",
    "context",
    "agent",
    "hooks",
}

# Retained for compatibility with existing/open-standard skills in the repo.
LEGACY_FIELDS = {"license", "metadata"}
ALL_FIELDS = SUPPORTED_FIELDS | LEGACY_FIELDS
BOOL_FIELDS = {"disable-model-invocation", "user-invocable"}
SCALAR_FIELDS = {"name", "description", "argument-hint", "model", "context", "agent", "license"}
FIELD_PATTERN = re.compile(r"^([A-Za-z0-9-]+):(.*)$")
NAME_PATTERN = re.compile(r"^[a-z0-9-]+$")
RESERVED_WORDS = {"anthropic", "claude"}
XML_TAG_PATTERN = re.compile(r"<[^>]+>")


@dataclass
class ValidationResult:
    """Structured validation result for a skill."""

    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

    @property
    def is_valid(self) -> bool:
        return not self.errors


def extract_frontmatter(content: str) -> tuple[str | None, str | None]:
    """Return the raw frontmatter and body, if present."""
    if not content.startswith("---"):
        return None, None

    lines = content.splitlines()
    if not lines or lines[0].strip() != "---":
        return None, None

    for index in range(1, len(lines)):
        if lines[index].strip() == "---":
            return "\n".join(lines[1:index]), "\n".join(lines[index + 1 :])

    return None, None


def collect_top_level_fields(frontmatter: str) -> dict[str, list[str]]:
    """Collect top-level YAML-like fields while preserving their raw payload."""
    fields: dict[str, list[str]] = {}
    current_key: str | None = None

    for line in frontmatter.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue

        if line[:1].isspace():
            if current_key is not None:
                fields[current_key].append(line)
            continue

        match = FIELD_PATTERN.match(line)
        if not match:
            current_key = None
            continue

        current_key = match.group(1)
        fields[current_key] = [match.group(2).rstrip()]

    return fields


def strip_inline_comment(value: str) -> str:
    """Remove inline comments outside quoted strings."""
    in_single = False
    in_double = False

    for index, char in enumerate(value):
        if char == "'" and not in_double:
            in_single = not in_single
        elif char == '"' and not in_single:
            in_double = not in_double
        elif char == "#" and not in_single and not in_double:
            if index == 0 or value[index - 1].isspace():
                return value[:index].rstrip()

    return value.rstrip()


def dedent_block(lines: list[str]) -> list[str]:
    """Remove the smallest common indentation from non-empty lines."""
    non_empty = [line for line in lines if line.strip()]
    if not non_empty:
        return []

    indent = min(len(line) - len(line.lstrip(" ")) for line in non_empty)
    return [line[indent:] if len(line) >= indent else "" for line in lines]


def scalar_value(raw_lines: list[str]) -> str | None:
    """Extract a scalar or block-scalar value from raw field lines."""
    if not raw_lines:
        return ""

    first = strip_inline_comment(raw_lines[0].strip())
    rest = raw_lines[1:]

    if first in {"", "~", "null"} and not any(line.strip() for line in rest):
        return ""

    if first.startswith(("|", ">")):
        return "\n".join(dedent_block(rest)).strip()

    if any(line.strip().startswith("-") for line in rest):
        return None

    combined = [first]
    for line in rest:
        if line.strip():
            combined.append(line.strip())

    value = "\n".join(part for part in combined if part)
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]

    return value


def parse_bool(value: str | None) -> bool | None:
    """Parse a YAML-like boolean."""
    if value is None:
        return None

    normalized = value.strip().lower()
    if normalized == "true":
        return True
    if normalized == "false":
        return False
    return None


def validate_allowed_tools(raw_lines: list[str], result: ValidationResult) -> None:
    """Validate allowed-tools as a scalar or YAML list."""
    if not raw_lines:
        return

    first = strip_inline_comment(raw_lines[0].strip())
    rest = [line for line in raw_lines[1:] if line.strip() and not line.lstrip().startswith("#")]

    if first:
        return

    if not rest:
        result.errors.append("Field 'allowed-tools' must be a comma-separated string or YAML list.")
        return

    if not all(line.lstrip().startswith("-") for line in rest):
        result.errors.append("Field 'allowed-tools' must use list items prefixed with '-'.")


def validate_skill(skill_path: str | Path) -> ValidationResult:
    """Validate a skill directory and return structured results."""
    result = ValidationResult()
    skill_path = Path(skill_path)
    skill_md = skill_path / "SKILL.md"

    if not skill_md.exists():
        result.errors.append("SKILL.md not found")
        return result

    content = skill_md.read_text()
    frontmatter, _ = extract_frontmatter(content)
    if frontmatter is None:
        result.errors.append("No valid YAML frontmatter found")
        return result

    fields = collect_top_level_fields(frontmatter)
    if not fields:
        result.errors.append("Frontmatter is empty")
        return result

    unexpected_keys = sorted(set(fields) - ALL_FIELDS)
    if unexpected_keys:
        result.errors.append(
            "Unexpected key(s) in SKILL.md frontmatter: "
            + ", ".join(unexpected_keys)
            + ". Supported fields: "
            + ", ".join(sorted(SUPPORTED_FIELDS))
        )

    legacy_keys = sorted(set(fields) & LEGACY_FIELDS)
    if legacy_keys:
        result.warnings.append(
            "Legacy field(s) detected: "
            + ", ".join(legacy_keys)
            + ". These are accepted for compatibility but are not part of the main Claude Code frontmatter surface."
        )

    name = scalar_value(fields.get("name", [])) if "name" in fields else None
    if name is not None:
        if not name:
            result.errors.append("Field 'name' must not be empty when provided.")
        else:
            if not NAME_PATTERN.match(name):
                result.errors.append(
                    f"Name '{name}' must contain only lowercase letters, digits, and hyphens."
                )
            if name.startswith("-") or name.endswith("-") or "--" in name:
                result.errors.append(
                    f"Name '{name}' cannot start/end with a hyphen or contain consecutive hyphens."
                )
            if len(name) > 64:
                result.errors.append(
                    f"Name is too long ({len(name)} characters). Maximum is 64 characters."
                )
            for word in RESERVED_WORDS:
                if word in name:
                    result.errors.append(
                        f"Name '{name}' contains reserved word '{word}'."
                    )
            if XML_TAG_PATTERN.search(name):
                result.errors.append(
                    f"Name '{name}' must not contain XML tags."
                )

    if "description" in fields:
        description = scalar_value(fields["description"])
        if description is None:
            result.errors.append("Field 'description' must be a string or block scalar.")
        elif not description:
            result.warnings.append(
                "Missing recommended 'description' content. Claude uses the description for automatic triggering."
            )
        elif len(description) > 1024:
            result.errors.append(
                f"Description is too long ({len(description)} characters). Maximum is 1024 characters."
            )
        elif XML_TAG_PATTERN.search(description):
            result.errors.append("Description must not contain XML tags.")
    else:
        result.warnings.append(
            "Missing recommended 'description' field. Claude uses the description for automatic triggering."
        )

    for field_name in ("argument-hint", "model", "license"):
        if field_name in fields:
            value = scalar_value(fields[field_name])
            if value is None:
                result.errors.append(f"Field '{field_name}' must be a string.")

    for field_name in BOOL_FIELDS:
        if field_name in fields:
            bool_value = parse_bool(scalar_value(fields[field_name]))
            if bool_value is None:
                result.errors.append(f"Field '{field_name}' must be true or false.")

    context_value = None
    if "context" in fields:
        context_value = scalar_value(fields["context"])
        if context_value is None:
            result.errors.append("Field 'context' must be a string.")
        elif context_value != "fork":
            result.errors.append("Field 'context' only supports the value 'fork'.")

    if "agent" in fields:
        agent_value = scalar_value(fields["agent"])
        if agent_value is None or not agent_value:
            result.errors.append("Field 'agent' must be a non-empty string.")
        if context_value != "fork":
            result.errors.append("Field 'agent' requires 'context: fork'.")

    if "hooks" in fields:
        raw_hooks = fields["hooks"]
        if len(raw_hooks) == 1 and not strip_inline_comment(raw_hooks[0].strip()):
            indented_lines = [line for line in raw_hooks[1:] if line.strip()]
            if not indented_lines:
                result.errors.append("Field 'hooks' must contain hook definitions.")

    if "allowed-tools" in fields:
        validate_allowed_tools(fields["allowed-tools"], result)

    return result


def print_result(result: ValidationResult) -> None:
    """Render validation output for CLI usage."""
    for warning in result.warnings:
        print(f"Warning: {warning}")

    for error in result.errors:
        print(f"Error: {error}")

    if result.is_valid:
        print("Skill is valid!")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python quick_validate.py <skill_directory>")
        sys.exit(1)

    validation = validate_skill(sys.argv[1])
    print_result(validation)
    sys.exit(0 if validation.is_valid else 1)
