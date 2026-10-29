# <PROJECT NAME>

The shared rules in `DEV/CLAUDE.md` apply here; Claude Code reads every `CLAUDE.md` up the folder chain, including a group's. This file holds the facts of this project only.

Harness: v4.1

## Purpose

<One or two sentences. What this tool does and for whom.>

## Principles

<!-- Three to five rules that do not change for the life of the project. brainstorm rejects an approach that breaks one; the work loop does not trade one away for convenience. Write each as a sentence that can be checked. -->

- <e.g. All data stays on this machine. No network call without a line here that names the host.>
- <e.g. Money is an integer in won. No floats, anywhere.>
- <e.g. One dependency per job. Prefer the standard library.>

## Stack and structure

- Language / framework: <e.g. Python 3.12 + FastAPI>
- Package manager: <e.g. uv, npm>
- Directories:
  - `src/` — <role>
  - `tests/` — <role>

## Commands

- Run: `<command>`
- Check: `scripts/check.sh` (runs: <build / test / lint, in order>)
- Other: `<command>` — <what it does>

## Commit rule

Write commit messages in short English. First line: `<type>: <summary>` under 50 characters. Types: feat, fix, refactor, docs, chore, wip. Use `wip` only when `scripts/check.sh` did not pass; name the failing step in the body. For other types, add a body only when the reason is not clear from the summary.

## Design

Visual rules live in `DESIGN.md` (the `Harness` section holds the KRDS mode and the UI stack). Delete this section when the project has no UI.

## Sensitive paths

<!-- Files or directories where a mistake is expensive: money, stored data formats, auth, external interfaces, release config. The work loop asks the user before it edits one of these, even inside the task scope. One path per line with the reason. -->

- <e.g. `src/ledger/` — money calculations>
- <e.g. `src/storage/schema.py` — a change here needs a data migration>

## Do not

- <File or directory that must not be edited at all, and why>
- <External service that must not be called without approval>

## Correction rules

<!-- Add one rule per line. Format: - YYYY-MM-DD: rule -->
