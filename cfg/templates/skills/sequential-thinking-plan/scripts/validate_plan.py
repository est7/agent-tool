#!/usr/bin/env python3
"""Validate structured thinking output for deep-plan skill.

Parses markdown thinking steps and plan output, checks structural
completeness and quality gates. Returns JSON verdict.

Usage:
    python validate_plan.py <plan_file.md>
    cat plan.md | python validate_plan.py -

Exit codes:
    0 — all gates passed
    1 — one or more gates failed
    2 — parse error or invalid input
"""

import json
import re
import sys
from dataclasses import dataclass, field


@dataclass
class ThinkingStep:
    number: int
    total: int
    tag: str
    focus: str = ""
    findings: str = ""
    confidence: str = ""
    next_action: str = ""
    revises: int | None = None


@dataclass
class GateResult:
    name: str
    passed: bool
    details: str = ""


def parse_thinking_steps(content: str) -> list[ThinkingStep]:
    """Extract structured thinking steps from markdown."""
    steps: list[ThinkingStep] = []
    # Match: ### Step N/M [tag] or ### Step N/M [revision of Step X]
    pattern = re.compile(
        r"###\s+Step\s+(\d+)/(\d+)\s+\[([^\]]+)\]",
        re.IGNORECASE,
    )
    # Split content by step headers
    parts = pattern.split(content)
    # parts layout: [preamble, n1, m1, tag1, body1, n2, m2, tag2, body2, ...]
    i = 1
    while i + 3 <= len(parts):
        num = int(parts[i])
        total = int(parts[i + 1])
        tag_raw = parts[i + 2].strip()
        body = parts[i + 3] if i + 3 < len(parts) else ""

        # Parse revision reference from tag
        revises = None
        tag = tag_raw
        rev_match = re.match(r"revision(?:\s+of)?\s+(?:Step\s+)?(\d+)", tag_raw, re.IGNORECASE)
        if rev_match:
            revises = int(rev_match.group(1))
            tag = "revision"

        step = ThinkingStep(number=num, total=total, tag=tag)
        if revises:
            step.revises = revises

        # Extract fields from body
        for field_name, attr in [
            ("Focus", "focus"),
            ("Findings", "findings"),
            ("Confidence", "confidence"),
            ("Next", "next_action"),
        ]:
            m = re.search(
                rf"\*\*{field_name}\*\*\s*:\s*(.+?)(?=\n\s*-\s*\*\*|\n###|\Z)",
                body,
                re.DOTALL,
            )
            if m:
                setattr(step, attr, m.group(1).strip())

        steps.append(step)
        i += 4

    return steps


def parse_plan_sections(content: str) -> dict[str, bool]:
    """Check presence of required plan sections."""
    required = {
        "Problem Definition": False,
        "Analysis Summary": False,
        "Execution Plan": False,
        "Risks": False,
        "Open Questions": False,
    }
    for section in required:
        if re.search(rf"###?\s+{re.escape(section)}", content, re.IGNORECASE):
            required[section] = True
    return required


def extract_execution_steps(content: str) -> list[dict]:
    """Extract numbered execution steps and check for verification methods."""
    results = []
    # Look for numbered list items under Execution Plan
    exec_match = re.search(
        r"###?\s+Execution\s+Plan\s*\n(.*?)(?=\n###?\s|\Z)",
        content,
        re.DOTALL | re.IGNORECASE,
    )
    if not exec_match:
        return results

    block = exec_match.group(1)
    for line in block.strip().split("\n"):
        m = re.match(r"\s*\d+\.\s+(.+)", line)
        if m:
            text = m.group(1)
            has_verification = bool(
                re.search(r"→|verify|test|check|run|assert|confirm|validate", text, re.IGNORECASE)
            )
            results.append({"text": text, "has_verification": has_verification})
    return results


# ── Gate checks ──────────────────────────────────────────────

REQUIRED_COVERAGE = [
    "problem definition",
    "decomposition",
    "evaluation",
    "execution",
    "risk",
]

VALID_TAGS = {
    "analysis",
    "decomposition",
    "evaluation",
    "comparison",
    "revision",
    "branch",
    "synthesis",
}


def gate_step_format(steps: list[ThinkingStep]) -> GateResult:
    """Every step must have Focus, Findings, Confidence, Next fields."""
    if not steps:
        return GateResult("step_format", False, "No thinking steps found")
    missing = []
    for s in steps:
        fields_missing = []
        if not s.focus:
            fields_missing.append("Focus")
        if not s.findings:
            fields_missing.append("Findings")
        if not s.confidence:
            fields_missing.append("Confidence")
        if not s.next_action:
            fields_missing.append("Next")
        if fields_missing:
            missing.append(f"Step {s.number}: missing {', '.join(fields_missing)}")
    if missing:
        return GateResult("step_format", False, "; ".join(missing))
    return GateResult("step_format", True)


def gate_step_tags(steps: list[ThinkingStep]) -> GateResult:
    """All tags must be from the valid set."""
    invalid = []
    for s in steps:
        base_tag = s.tag.split(":")[0].strip().lower()
        if base_tag not in VALID_TAGS:
            invalid.append(f"Step {s.number}: unknown tag '{s.tag}'")
    if invalid:
        return GateResult("step_tags", False, "; ".join(invalid))
    return GateResult("step_tags", True)


def gate_coverage(steps: list[ThinkingStep]) -> GateResult:
    """Required topic areas must each appear in at least one step."""
    covered_text = " ".join(
        f"{s.tag} {s.focus} {s.findings}".lower() for s in steps
    )
    missing = []
    for topic in REQUIRED_COVERAGE:
        # Flexible matching: check both tag and content
        if topic not in covered_text:
            # Second pass: check synonyms
            synonyms = {
                "problem definition": ["problem", "objective", "goal", "requirement"],
                "decomposition": ["decompos", "break down", "sub-problem", "mece"],
                "evaluation": ["evaluat", "alternative", "option", "approach", "comparison"],
                "execution": ["execut", "step", "implement", "action"],
                "risk": ["risk", "mitigation", "danger", "failure"],
            }
            found = any(syn in covered_text for syn in synonyms.get(topic, []))
            if not found:
                missing.append(topic)
    if missing:
        return GateResult("coverage", False, f"Missing coverage: {', '.join(missing)}")
    return GateResult("coverage", True)


def gate_termination(steps: list[ThinkingStep]) -> GateResult:
    """Final step's Next field must indicate gate transition."""
    if not steps:
        return GateResult("termination", False, "No steps to check")
    last = steps[-1]
    if "gate" in last.next_action.lower() or "→" in last.next_action:
        return GateResult("termination", True)
    return GateResult(
        "termination",
        False,
        f"Last step's Next is '{last.next_action}', expected '→ Gate'",
    )


def gate_low_confidence(steps: list[ThinkingStep]) -> GateResult:
    """Any step with confidence=low must be addressed by a later step."""
    low_steps = [s for s in steps if s.confidence.lower() == "low"]
    if not low_steps:
        return GateResult("low_confidence_addressed", True, "No low-confidence steps")

    low_numbers = {s.number for s in low_steps}
    addressed = set()

    for s in steps:
        if s.revises and s.revises in low_numbers:
            addressed.add(s.revises)
        # Also check if a later step's Focus references the low-confidence step
        for ln in low_numbers:
            if f"step {ln}" in s.focus.lower() and s.number > ln:
                addressed.add(ln)

    unaddressed = low_numbers - addressed
    if unaddressed:
        return GateResult(
            "low_confidence_addressed",
            False,
            f"Low-confidence steps not addressed: {sorted(unaddressed)}",
        )
    return GateResult("low_confidence_addressed", True)


def gate_plan_sections(sections: dict[str, bool]) -> GateResult:
    """Plan must contain all required sections."""
    missing = [k for k, v in sections.items() if not v]
    if missing:
        return GateResult("plan_sections", False, f"Missing sections: {', '.join(missing)}")
    return GateResult("plan_sections", True)


def gate_execution_verification(exec_steps: list[dict]) -> GateResult:
    """Every execution step should have a verification method."""
    if not exec_steps:
        return GateResult("execution_verification", False, "No execution steps found")
    no_verify = [s["text"][:60] for s in exec_steps if not s["has_verification"]]
    if no_verify:
        return GateResult(
            "execution_verification",
            False,
            f"{len(no_verify)}/{len(exec_steps)} steps lack verification: {no_verify}",
        )
    return GateResult("execution_verification", True)


def gate_minimum_steps(steps: list[ThinkingStep], complexity: str) -> GateResult:
    """Step count must meet minimum for the declared complexity."""
    minimums = {"simple": 3, "medium": 5, "complex": 8}
    minimum = minimums.get(complexity, 3)
    if len(steps) < minimum:
        return GateResult(
            "minimum_steps",
            False,
            f"Complexity '{complexity}' requires ≥{minimum} steps, got {len(steps)}",
        )
    return GateResult("minimum_steps", True)


def detect_complexity(content: str) -> str:
    """Try to detect declared complexity from the output."""
    m = re.search(r"complexity[:\s]+(simple|medium|complex)", content, re.IGNORECASE)
    if m:
        return m.group(1).lower()
    # Fallback: check for explicit level mention
    m = re.search(r"\*\*(simple|medium|complex)\*\*", content, re.IGNORECASE)
    if m:
        return m.group(1).lower()
    return "medium"


def validate(content: str) -> dict:
    """Run all gates and return structured results."""
    steps = parse_thinking_steps(content)
    sections = parse_plan_sections(content)
    exec_steps = extract_execution_steps(content)
    complexity = detect_complexity(content)

    gates = [
        gate_step_format(steps),
        gate_step_tags(steps),
        gate_coverage(steps),
        gate_termination(steps),
        gate_low_confidence(steps),
        gate_plan_sections(sections),
        gate_execution_verification(exec_steps),
        gate_minimum_steps(steps, complexity),
    ]

    all_passed = all(g.passed for g in gates)

    return {
        "passed": all_passed,
        "complexity": complexity,
        "thinking_steps_count": len(steps),
        "execution_steps_count": len(exec_steps),
        "gates": [
            {"name": g.name, "passed": g.passed, "details": g.details}
            for g in gates
        ],
    }


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <plan_file.md | ->", file=sys.stderr)
        sys.exit(2)

    source = sys.argv[1]
    try:
        if source == "-":
            content = sys.stdin.read()
        else:
            with open(source) as f:
                content = f.read()
    except (FileNotFoundError, IOError) as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(2)

    if not content.strip():
        print(json.dumps({"error": "Empty input"}))
        sys.exit(2)

    result = validate(content)
    print(json.dumps(result, indent=2))
    sys.exit(0 if result["passed"] else 1)


if __name__ == "__main__":
    main()
