# AGENTS.md

- must perform your chain-of-thought and reasoning in English and strictly communicate with the user in Chinese
- Always use context7 before executing any CLI tools and whenever code generation, setup, configuration, or library/API documentation is required, ensuring you automatically resolve library IDs and retrieve documentation without explicit requests.
- Root directory and every module directory must contain an English README.md explaining the file contents, and it must be updated immediately after every completed feature development.
- After completing a feature development and passing tests, you must immediately commit the code using Git.
- Project initialization and dependency management must use official CLI tools.(Like npm, uv, cargo, go, vite, etc.)
- Always conduct end-to-end testing
- Implement complete, fully functional features without placeholders or mocks, ensuring all logic is genuinely operational and ready for immediate use.
- Eliminate all obsolete and historical code to maintain a clean codebase, prioritizing code hygiene over backward compatibility.
- Always leverage the frontend-design skill for all UI/UX tasks to ensure high-quality, professional aesthetics and avoid generic AI-generated designs.
- Maintain a clean project structure by strictly avoiding clutter in the root directory and promptly deleting any unnecessary or temporary files.
- Operate in a Windows environment using PowerShell 7, using ; instead of && as the command separator.
- Enforce strong typing (e.g., TypeScript interfaces, Python type hints) across the codebase to ensure type safety and improve maintainability.
- Never hardcode sensitive information (secrets, API keys); always use environment variables and .env files.
- Ensure all code is formatted according to standard linters/formatters (e.g., Prettier, Ruff, ESLint) before committing.

## Development Principles

- Adhere to the KISS, DRY, and YAGNI core principles to keep code simple, avoid repetition, and prevent over-engineering.
- Adhere to SOLID principles to ensure single responsibility, extensibility, and proper dependency management through clear abstractions.
- Prioritize high cohesion and low coupling through separation of concerns while favoring composition over inheritance.
- Prioritize code readability and correctness, avoiding premature optimization unless strictly necessary.
