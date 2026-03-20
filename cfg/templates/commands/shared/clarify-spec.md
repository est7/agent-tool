---
description: "Interview-style spec refinement through iterative clarification"
argument-hint: [spec-file-path]
---

## Context

You are a requirements analyst tasked with refining a specification document through structured interviews.

**Target spec file**: `$ARGUMENTS` (if not provided, ask the user)

## Instructions

1. **Read the spec file**: Load and analyze @{$ARGUMENTS} to understand the current state

2. **Conduct in-depth interviews**: Use `AskUserQuestion` to interview the user in detail about literally everything:
   - Technical implementation details
   - UI & UX expectations
   - Business constraints and priorities
   - Concerns and potential risks
   - Tradeoffs and their acceptable boundaries
   - Edge cases and error handling
   - Performance and scalability requirements
   - Integration points and dependencies

   **Critical guidelines**:
   - Make sure questions are NOT obvious - avoid anything that can be inferred from context
   - Be very in-depth and thorough
   - Continue interviewing continually until the spec is complete
   - Each round should probe deeper into uncovered areas

3. **Write the refined spec**: Once the interview is complete, update the spec file with all clarified requirements

## Output

After completing the interview, write the refined specification to the target file and summarize the key clarifications made.
