---
name: dual-ai-review
description: Multi-AI Review Skill - Uses Gemini CLI and Codex CLI for comprehensive code/paper review, cross-validation, and multi-perspective analysis. Activates when users request review, validation, or analysis using multiple AI models.
---

# AI Review Skill (Gemini + Codex)

## Overview

This skill enables multi-AI review workflows by leveraging both **Google Gemini CLI** and **OpenAI Codex CLI** for comprehensive analysis. Ideal for:
- Paper/thesis review and validation
- Code review from multiple perspectives
- Cross-checking AI outputs for accuracy
- Research verification and fact-checking

## Prerequisites

### Required Tools
- **Gemini CLI**: `gemini --version` (v0.21.1+ for Gemini 3)
- **Codex CLI**: `codex --version`

### Configuration
- Gemini: Authenticated via `gemini` login
- Codex: Config at `~/.codex/config.toml`

### Enable Gemini 3 Models
```bash
# Run these commands in Gemini CLI interactive mode:
/settings  # Toggle "Preview Features" to true
/model     # Select "Auto (Gemini 3)"
```

## Workflow Checklist

**For every AI review task, follow this sequence**:

1. **Verify tool availability**:
   ```bash
   gemini --version && codex --version
   ```

2. **Ask user for review parameters** via `AskUserQuestion`:
   - **Review Mode**: `gemini-only`, `codex-only`, `dual-review` (recommended), `sequential`
   - **Review Type**: `paper`, `code`, `logic`, `general`
   - **Depth**: `quick`, `standard`, `thorough`

3. **Execute review based on mode** (see Command Patterns below)

4. **Synthesize results**: Combine outputs, highlight agreements/disagreements

5. **Report to user**: Summary, confidence level, next steps

## Command Patterns

### Gemini CLI Commands

```bash
# Basic Review
gemini "Review the following content for [ASPECT]: [CONTENT]" 2>/dev/null

# Gemini 3 Flash - SWE-bench 78%, 3x faster, best value
gemini -m gemini-3-flash-preview "Deep analysis of: [CONTENT]" 2>/dev/null

# Gemini 3 Pro - Complex reasoning, highest quality
gemini -m gemini-3-pro-preview "Deep analysis of: [CONTENT]" 2>/dev/null

# File Review via stdin
cat file.py | gemini -m gemini-3-flash-preview "Review this code" 2>/dev/null

# YOLO Mode (Auto-approve)
gemini -y "Analyze and review: [CONTENT]" 2>/dev/null

# Resume Session
gemini -r latest "Continue the previous review" 2>/dev/null
```

### Codex CLI Commands

```bash
# Code Review - use gpt-5.2-codex (best code ability, 400K context)
# NOTE: Codex does NOT support stdin pipe, include content directly in prompt
codex exec -m gpt-5.2-codex -c model_reasoning_effort="high" -s read-only \
  --skip-git-repo-check --full-auto "Review this code: [CONTENT]" 2>/dev/null

# Paper/Text Review - use gpt-5.1-codex-max (better text ability, supports million tokens)
codex exec -m gpt-5.1-codex-max -c model_reasoning_effort="xhigh" -s read-only \
  --skip-git-repo-check --full-auto "Comprehensive review: [CONTENT]" 2>/dev/null

# File Review - read file content first, then include in prompt
# Example: CODE=$(cat file.py) && codex exec -m gpt-5.2-codex ... "Review: $CODE"

# Built-in Code Review (for git repos)
codex exec review -m gpt-5.2-codex --skip-git-repo-check --full-auto 2>/dev/null
```

## Review Modes

### Mode 1: Dual Review (Recommended)

```bash
# Step 1: Gemini Review
gemini -m gemini-3-flash-preview "Review this [paper/code] for:
1. Logical consistency
2. Technical accuracy
3. Potential issues
Content: [CONTENT]" 2>/dev/null > /tmp/gemini_review.txt

# Step 2: Codex Review (use 5.2-codex for code, 5.1-codex-max for text)
codex exec -m gpt-5.2-codex -c model_reasoning_effort="high" -s read-only \
  --skip-git-repo-check --full-auto \
  "Review this [paper/code] for:
  1. Logical consistency
  2. Technical accuracy
  3. Potential issues
  Content: [CONTENT]" 2>/dev/null > /tmp/codex_review.txt

# Step 3: Compare and synthesize (Claude does this)
```

### Mode 2: Sequential Review (Deep Analysis)

```bash
# Step 1: Gemini Initial Review
GEMINI_OUTPUT=$(gemini -m gemini-3-flash-preview "Initial review of: [CONTENT]" 2>/dev/null)

# Step 2: Codex Validates Gemini Review
codex exec -m gpt-5.1-codex-max -c model_reasoning_effort="high" -s read-only \
  --skip-git-repo-check --full-auto \
  "Validate and expand on this review:
  Original Content: [CONTENT]
  Initial Review: $GEMINI_OUTPUT" 2>/dev/null
```

### Mode 3: Single AI Review

```bash
# Gemini Only
gemini -m gemini-3-flash-preview -y "Comprehensive review of: [CONTENT]" 2>/dev/null

# Codex Only (Code)
codex exec -m gpt-5.2-codex -c model_reasoning_effort="xhigh" -s read-only \
  --skip-git-repo-check --full-auto "Comprehensive review: [CONTENT]" 2>/dev/null

# Codex Only (Paper/Text)
codex exec -m gpt-5.1-codex-max -c model_reasoning_effort="xhigh" -s read-only \
  --skip-git-repo-check --full-auto "Comprehensive review: [CONTENT]" 2>/dev/null
```

## Review Type Templates

### Paper/Thesis Review

```bash
# Gemini - Focus on logic and clarity (use 3.0 Pro for best reasoning)
gemini -m gemini-3-pro-preview "As an academic reviewer, analyze this paper section:
1. Logical flow and argumentation
2. Clarity of expression
3. Methodology soundness
4. Citation appropriateness
5. Potential weaknesses

Content:
[PAPER_CONTENT]" 2>/dev/null

# Codex - Focus on technical accuracy (use 5.1-codex-max for text)
codex exec -m gpt-5.1-codex-max -c model_reasoning_effort="high" -s read-only \
  --skip-git-repo-check --full-auto \
  "As a technical reviewer, analyze:
  1. Mathematical/algorithmic correctness
  2. Code/implementation validity
  3. Experimental design
  4. Statistical analysis
  5. Reproducibility concerns

  Content: [PAPER_CONTENT]" 2>/dev/null
```

### Code Review

```bash
# Gemini - Architecture and design (use 3.0 Flash for speed)
# Gemini supports stdin pipe
cat code.py | gemini -m gemini-3-flash-preview "Review this code for:
1. Architecture and design patterns
2. Code organization
3. Naming conventions
4. Documentation quality
5. Maintainability" 2>/dev/null

# Codex - Implementation and security (use 5.2-codex for code)
# Codex: include file content directly in prompt
codex exec -m gpt-5.2-codex -c model_reasoning_effort="high" \
  --skip-git-repo-check --full-auto \
  "Review this code for:
  1. Security vulnerabilities
  2. Performance issues
  3. Bug potential
  4. Edge cases
  5. Best practices compliance

  Code:
  [FILE_CONTENT]" 2>/dev/null
```

### Logic Validation

```bash
# Cross-validate logical arguments
gemini -m gemini-3-pro-preview "Validate the logical consistency of this argument:
[ARGUMENT]
Check for: fallacies, assumptions, gaps in reasoning" 2>/dev/null

codex exec -m gpt-5.1-codex-max -c model_reasoning_effort="xhigh" -s read-only \
  --skip-git-repo-check --full-auto \
  "Analyze logical structure:
  [ARGUMENT]
  Identify: premises, conclusions, validity, soundness" 2>/dev/null
```

## Depth Configuration

### Quick Review
- Gemini: `gemini-3-flash-preview` (default), brief prompt
- Codex: `gpt-5-mini`, `model_reasoning_effort="low"`
- Use case: Fast sanity check

### Standard Review
- Gemini: `-m gemini-3-flash-preview`
- Codex: `gpt-5.2-codex` (code) / `gpt-5.1-codex-max` (text), `model_reasoning_effort="medium"`
- Use case: Regular code/document review

### Thorough Review
- Gemini: `-m gemini-3-pro-preview` with detailed prompts
- Codex: `gpt-5.2-codex` (code) / `gpt-5.1-codex-max` (text), `model_reasoning_effort="xhigh"`
- Use case: Critical papers, security audits, important decisions

## Model Selection Guide

### Gemini Models (需要启用 Preview features)
| Task | Model | Notes |
|------|-------|-------|
| Quick check | gemini-3-flash-preview | SWE-bench 78%, 3x faster, low cost |
| Standard review | gemini-3-flash-preview | Best value |
| Deep analysis | gemini-3-pro-preview | Complex reasoning, highest quality |

### Codex Models
| Task | Model | Reasoning | Notes |
|------|-------|-----------|-------|
| Quick syntax | gpt-5-mini | none/low | Fast check |
| Code review | gpt-5.2-codex | medium/high | Best code ability, 400K context |
| Paper/Text | gpt-5.1-codex-max | high/xhigh | Better text ability, supports million tokens |
| Deep code | gpt-5.2-codex | xhigh | Security audit, complex refactoring |

### Model Selection Strategy
- **Code tasks** -> `gpt-5.2-codex` (stronger code ability)
- **Text/Paper tasks** -> `gpt-5.1-codex-max` (stronger text ability)
- **Both needed** -> Use 5.2-codex for code analysis, 5.1-codex-max for text analysis

## Output Synthesis

After running both AIs, Claude should:

1. **Compare Outputs**:
   - List points where both AIs agree (high confidence)
   - Highlight disagreements (needs human judgment)
   - Note unique insights from each AI

2. **Generate Summary**:
   ```
   ## AI Review Summary

   ### Consensus Points (High Confidence)
   - [Points both AIs agree on]

   ### Divergent Views (Review Needed)
   - Gemini says: [X]
   - Codex says: [Y]
   - Recommendation: [Claude synthesis]

   ### Unique Insights
   - From Gemini: [...]
   - From Codex: [...]

   ### Action Items
   1. [Prioritized list of suggested changes]
   ```

3. **Confidence Rating**:
   - High: Both AIs agree
   - Medium: Partial agreement
   - Low: Significant disagreement (needs human review)

## Error Handling

### Gemini Errors
```bash
# If Gemini fails, check:
gemini --version  # Verify installation (need v0.21.1+)
gemini -h         # Check available options
/settings         # Make sure Preview features enabled
```

### Codex Errors
```bash
# If Codex fails:
codex --version
cat ~/.codex/config.toml  # Check config
# Try without sandbox:
codex exec --yolo -m gpt-5.2-codex "test" 2>/dev/null
```

### Fallback Strategy
If one AI fails:
1. Report the failure to user
2. Continue with available AI
3. Note reduced confidence in results

## Best Practices

1. **Always use stderr suppression** (`2>/dev/null`) for clean output
2. **For papers**: Focus Gemini on logic/clarity, Codex (5.1-codex-max) on technical accuracy
3. **For code**: Focus Gemini on design, Codex (5.2-codex) on implementation
4. **Save outputs** to temp files for comparison when doing dual review
5. **Use high reasoning effort** for critical reviews
6. **Cross-validate** important findings with both AIs
7. **Choose right Codex model**: code -> 5.2-codex, text -> 5.1-codex-max
8. **Codex stdin limitation**: Codex does NOT support stdin pipe (`|`), include content directly in prompt

## Example Workflows

### Paper Section Review
```
User: "Review my methodology section using ai-review"

Claude:
1. Asks for review mode (dual-review recommended)
2. Reads the methodology content
3. Runs Gemini 3 Pro for logic/clarity check
4. Runs Codex gpt-5.1-codex-max for technical validation
5. Synthesizes results
6. Presents unified review with confidence levels
```

### Code Security Audit
```
User: "Security review this file with ai-review"

Claude:
1. Asks for depth (thorough for security)
2. Runs Gemini 3 Flash + Codex gpt-5.2-codex with security-focused prompts
3. Compares vulnerability findings
4. Prioritizes by severity and agreement level
5. Provides remediation suggestions
```

## Resume Capability

Both tools support session resume:

```bash
# Gemini
gemini -r latest "Continue with additional review points"

# Codex
codex exec resume --last "Continue the analysis"
```

Inform user: "You can resume this review session anytime with either tool."
