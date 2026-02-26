---
description: "移除 AI 生成的代码垃圾"
argument-hint: "<可选：要审查的文件路径或关注点>"
---
# Remove AI code slop

Check the diff against main, and remove all AI generated slop introduced in this branch.

Focus on the following categories (including but not limited to):

## Duplicate Code
- Structural duplication — similar logic repeated across functions/classes with only minor differences
- Boilerplate skeleton — copy-pasted class/function scaffolding that adds no real value

## Noise Code
- Empty function bodies (placeholder stubs with no implementation)
- Commented-out code blocks
- Dead branches — conditions that can never be true given the context
- Unreachable code after early returns, throws, or breaks
- Trivial comments that restate the code (e.g., `// increment counter` above `counter++`)
- Excessive comments disproportionate to the surrounding codebase style
- Unused imports or declarations
- Leftover boilerplate — redundant type checks, unnecessary null guards on non-nullable paths, default cases that duplicate existing logic

## Defensive Overreach
- Extra try/catch blocks that are abnormal for that area of the codebase (especially if called by trusted / validated codepaths)
- Unnecessary defensive checks on already-validated inputs
- Casts to `any` / force-unwraps added to bypass type issues instead of fixing them

## Security Anti-Patterns
- Broad catch blocks that silently swallow errors (e.g., `catch (Exception e) {}`)
- Hardcoded credentials, tokens, or secrets
- Injection risks from unescaped user input in string interpolation
- Unsafe deserialization of untrusted data
- Weak or deprecated crypto usage (MD5, SHA1 for security purposes)
- Sensitive data leaking into logs

## Style Inconsistency
- Any naming, formatting, or structural patterns that are inconsistent with the rest of the file

Report at the end with only a 1-3 sentence summary of what you changed
