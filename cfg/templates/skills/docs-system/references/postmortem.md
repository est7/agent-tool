# Postmortem Guidance

## Purpose

`docs/postmortem/` stores documents that make failure patterns visible and reusable.

Each postmortem should help future work become more cautious and less repetitive.

## Entry Modes

### 1. Onboarding Historical Fixes

Use this when entering a mature repository with meaningful fix history.

- Review important historical fix commits
- Group related failure patterns
- Create durable postmortem reports instead of isolated notes
- Refresh `docs/postmortem/README.md`

### 2. Pre-release Check

Use this before a release or other high-risk delivery point.

- Read the most relevant existing postmortems
- Compare the current release scope against known failure patterns
- Surface concrete items to verify or fix
- Update related docs if new guardrails are discovered

### 3. Post-fix or Post-release Synthesis

Use this after meaningful fixes or after a release window.

- Convert fresh failures and fixes into durable reports
- Cross-link related design, research, or implementation docs when useful
- Refresh `docs/postmortem/README.md`

## Recommended Postmortem Structure

- Background and trigger
- Impact or regression surface
- Root cause
- Why it escaped earlier checks
- Guardrails or prevention rules
- Verification and follow-up
