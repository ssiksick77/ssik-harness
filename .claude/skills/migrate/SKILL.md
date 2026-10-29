---
name: migrate
description: Bring a project that already uses the DEV harness up to the current harness version. Use when the session context reports a harness version mismatch, when the user runs /migrate, or when the user asks to update a project to the latest harness. Not for a project without harness files; that is adopt-project.
---

# migrate

Apply the harness changes between the project's version and `DEV/VERSION`. Change only harness files. Never touch project code, and never delete user content; move it.

## Paths

Find `$DEV` as `new-project` does (walk up until a directory holds `_template/` and `.claude/skills/`). `$PROJ` is the current project directory.

## Steps

1. Read the versions:
   - `$DEV/VERSION` → `target` (for example `v3`).
   - The `Harness:` line in `$PROJ/CLAUDE.md` → `current`. If the line is missing, `current` is `v2`.
   - If `current` equals `target`, say so and stop.
   - If `current` is newer than `target`, stop and tell the user to update `DEV/` first (`git pull` in `DEV/`).
2. Require a clean working tree. Run `git status --porcelain` in `$PROJ`. If it prints anything, stop and ask the user to commit or stash first. Harness changes must not mix with project changes.
3. List the migration files to apply: every `$DEV/migrations/vN.md` with `current < N <= major(target)`, in ascending order. A minor target (`v3.1`) adds no file beyond its major.
4. For each file, in order, do what it says:
   - Before you start, read the whole migration file and collect its `[ask]` questions. Ask them in one message, in order, so the user answers once. If the user skips a question, leave that step's placeholder in place and record it in step 8.
   - Add a section only when it is missing. Match by the `## ` heading, case-sensitive.
   - When a step moves content, copy it to the new place first, read both places, then remove it from the old place. Never remove content that was not copied.
   - Skip a step whose result is already present. Say "already present" in the report.
   - Never edit project code, tests, or build files. The migration touches only `CLAUDE.md`, `DESIGN.md`, `progress.md`, `ideas.md`, `scripts/check.sh`, `.gitignore`, and `.claude/`.
   - If a step cannot be applied as written (the file has an unexpected shape), do not improvise. Stop, show the user the file, and ask.
5. Run `"$DEV/.claude/scripts/link-harness.sh" "$PROJ"` so new skills and agents are linked.
6. Set the `Harness:` line in `$PROJ/CLAUDE.md` to `target`. If the line is missing, add it under the first paragraph.
7. Run `git diff` and read it whole. Confirm that only harness files changed and that no user content was removed. Then commit those files, staged by name, with the message `chore: migrate harness to <target>`. Follow "Commit procedure" in `DEV/CLAUDE.md`. Do not push; `wrap-up` pushes.
8. Report: the versions, every step applied, every step skipped and why, and the `[ask]` steps left with a placeholder.
