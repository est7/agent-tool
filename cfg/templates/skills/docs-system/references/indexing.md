# Indexing Rules

## Required Indexes

- `docs/README.md` is the root table of contents for the documentation tree.
- `docs/postmortem/README.md` is the dedicated postmortem table of contents.

## Root Index Responsibilities

`docs/README.md` should:

- list every active category under `docs/`
- link to important entry documents
- point to module/subproject-local docs when they are important entry points
- keep archived material discoverable without treating it as active guidance

## Locality Rules

- Prefer the nearest existing docs location for subprojects and modules.
- When local docs are introduced or become important, add a pointer from the root `docs/README.md`.
- If a document becomes a long-lived project entry point, add or update a pointer from `AGENTS.md`.

## TOC Style

Keep indexes simple and filesystem-oriented.

- One short section per category
- Flat bullet list of important files
- Short one-line descriptions
- No duplicated full content inside the index
