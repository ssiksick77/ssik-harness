---
name: adopt-project
description: Bring an existing codebase under the dev/ harness without changing its code. Use when the user points at a directory that already has files (inside dev/ or elsewhere) and asks to add it as a project, set it up, or bring it into dev/. For an empty new project use new-project instead.
---

# adopt-project

Add the harness files to a project that already exists. Do not change the project's code, and do not lose any work that is already there. Brainstorming is not required; the project already has a direction.

## Paths

Find the dev/ root the same way as `new-project` (walk up from the current directory until a directory holds both `_template/` and `.claude/skills/`). Then set:

```bash
SRC="<the directory the user named>"          # where the files are now
NAME="$(basename "$SRC")"                      # or a name the user gives
GROUP="<path under DEV/, or empty>"            # e.g. STdev or STdev/product; see new-project "Paths"
PROJ="$DEV/${GROUP:+$GROUP/}$NAME"
```

## Steps

1. Confirm `$SRC` exists and holds files. If it is empty, stop and tell the user to use `new-project`. Ask once where the project goes: directly under `DEV/`, or a path inside an existing group (a subfolder such as `STdev/product` is fine). A group that does not exist yet is made with `new-group` first.
2. If `$SRC` is not at `$PROJ`, move it there (`git mv` is not needed; the directory moves whole, with its `.git`). The harness works only for projects under `DEV/`: the shared `CLAUDE.md`, the version check, and `migrate` all find `DEV/` by walking up from the project. If the user does not want to move it, stop; do not adopt it in place.
3. Secure the existing work before you add anything:
   - Warning: this commit is pushed to GitHub in step 11. Before you stage, look for secrets (`.env`, key files, tokens in config) and build output. If you find them and `.gitignore` does not exclude them, ask the user before you continue.
   - If `$PROJ` is not a git repository: run `git init`, stage everything, and commit with the message `chore: baseline before harness`. This commit records the user's work exactly as found. Do not run checks first; there are none yet.
   - If `$PROJ` is a git repository with a clean tree: do nothing.
   - If `$PROJ` is a git repository with uncommitted changes: do not commit them. Record the changed files for `progress.md` ("uncommitted before adoption") and continue. The harness files you add in step 5 go in their own commit.
4. Map the project with the `Explore` agent. Ask it for: language and framework, package manager, the directory layout with one line per directory, the entry point, and every check-like command it finds (in `package.json` scripts, `pyproject.toml`, `Makefile`, `justfile`, CI config, or a README). Read only the files it names. If `archify` is installed and the project has more than a handful of modules, offer the user an architecture diagram of the map; draw it only on a yes.
5. Add the harness files. Never overwrite a file that exists:
   - `CLAUDE.md` missing → copy `_template/CLAUDE.md` and fill it from step 4. Leave `<...>` placeholders only where the map gave no answer.
   - In both cases set the `Harness:` line to the content of `$DEV/VERSION` (add it under the first paragraph when missing).
   - `CLAUDE.md` exists → keep it. Append the template sections it lacks (`Principles`, `Commands`, `Commit rule`, `Design`, `Sensitive paths`, `Do not`, `Correction rules`), filled from step 4. Do not reorder or rewrite existing text. `[ask]` Principles and Sensitive paths need the user's answer; leave the template comment and one placeholder when they give none.
   - If the project has a UI and no `DESIGN.md`: copy `_template/DESIGN.md`, fill `## Harness` from step 4, and ask the user for the KRDS mode. If `DESIGN.md` exists (Impeccable wrote it), add only the `## Harness` section after the frontmatter.
   - `.gitignore` missing → copy from `_template/`. Exists → append `.archify/` and `.impeccable/cache/` if missing.
   - `progress.md`, `ideas.md` missing → copy from `_template/`.
   - `scripts/check.sh` missing → copy from `_template/` and fill it with the check commands found in step 4, as `run_step` lines. Do not invent commands. If none were found, leave every step commented out; the script then fails with "No checks configured", which is the correct state.
   - `scripts/check.sh` exists → keep it. Tell the user what the template version adds (the no-checks guard, `run_step`) and let them decide.
6. Run `scripts/check.sh` once and record the result as `new-project` step 7 does. A failing check is information, not something to fix in this skill.
7. Link the shared harness into `$PROJ/.claude/` with `"$DEV/.claude/scripts/link-harness.sh" "$PROJ"`, as `new-project` step 8 does. If it prints a warning about an existing `settings.json`, tell the user, and merge the `hooks` block only with their approval.
8. Ask the user one question: what is the next task? Use the answer as the Goal. If they do not know yet, set the Goal to "Adopted into the harness; first task not defined" and the Next action to "Define the first task with the user".
9. Fill `progress.md`:
   - Updated: today's date.
   - Goal: from step 8.
   - Done: "Adopted into the harness" with the baseline commit hash from step 3, if one was made.
   - Open issues: the check result from step 6; uncommitted files from step 3, if any; every placeholder still left in `CLAUDE.md`.
   - Next action: "Add the first check to scripts/check.sh" when checks are not configured; otherwise the first step of the Goal.
10. Commit only the files this skill added or changed (`CLAUDE.md`, `progress.md`, `ideas.md`, `scripts/check.sh`, `.claude/`), staged by name, with the message `chore: add harness files`. Do not stage the user's uncommitted changes from step 3.
    - When `GROUP` is set, register the project in the group repository as `new-project` step 10 does: `/$NAME/` in the group's `.gitignore`, one line under `## Projects` in the group's `CLAUDE.md`, committed there.
11. Connect GitHub (see "Git, GitHub, and personal information" in `dev/CLAUDE.md`):
    - No `origin` remote → create a private repository and push, as `new-project` step 11 does.
    - `origin` exists → keep it. Do not create a new repository. Ask the user once before you push to it.
12. Report to the user: the project path, the GitHub repository URL, the baseline commit if made, the check result, the placeholders left in `CLAUDE.md`, and the next action.
