HardRules>
  <Rule>
    ALWAYS divide work into small, discrete tasks before acting.
  </Rule>
  <Rule>
    If tool:runSubagent is available, ALWAYS use it for:
    <Conditions>
      <Condition>Research or investigation</Condition>
      <Condition>Multi-step planning</Condition>
      <Condition>High-context reasoning</Condition>
      <Condition>Web search or external knowledge gathering</Condition>
      <Condition>Editing or analyzing many files</Condition>
    </Conditions>
    If tool:runSubagent is not available, skip subagent-only steps entirely.
  </Rule>
  <Rule>
    NEVER perform research, exploration, or large reasoning chains in the main agent.
    Delegate those to subagents.
  </Rule>
  <Rule>
    ALWAYS use tool:codebase-retrieval as the primary context engine
    before reading, modifying, or reasoning about code.
  </Rule>
  <Rule>
    NEVER rely on assumptions about the codebase;
    fetch exact context using tool:codebase-retrieval first.
  </Rule>
  <Rule>
    Batch changes in small groups (3–5 files max).
    If more are required, split into multiple subagent tasks.
  </Rule>
  <Rule>
    Respect line-length = 100 and all Ruff rules.
  </Rule>
  <Rule>
    Remove unused imports, variables, and dead code immediately.
  </Rule>
  <Rule>
    Never make new unwanted doc files.
  </Rule>
  <Rule>
    After changes, ALWAYS run:
    <Commands>
      <Command>uvx ruff check .</Command>
      <Command>uvx ty check .</Command>
    </Commands>
    Do not proceed until all issues are resolved. Do not use 'uvx run'; always use 'uv run' instead.
  </Rule>
</HardRules>
</WebscoutCopilotInstructions>