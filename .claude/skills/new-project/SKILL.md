---
name: new-project
description: Create a new project directory under dev/ from _template/. Use when the user asks to start, create, or scaffold a new project, or runs /new-project.
---

# new-project

Create a new project under `dev/` from the template. Do not start feature work in this skill.

Before this skill runs, Brainstorming mode (see `dev/CLAUDE.md`) must be complete. If it is not, run it first and come back.

## Paths

Set these once at the start and use them for every path below. Do not mix relative paths.

```bash
# Walk up from the current directory until a directory holds both _template/ and .claude/skills/.
d="$(realpath "$PWD")"
while [ "$d" != "/" ] && ! { [ -d "$d/_template" ] && [ -d "$d/.claude/skills" ]; }; do
  d="$(dirname "$d")"
done
DEV="$d"
# If $DEV is "/", no dev/ root was found. Ask the user for the dev/ path.
```

This works from `dev/` itself and from any project under it. Set `NAME`, `GROUP`, and `PROJ` only after step 1 below confirms them:

```bash
NAME="<project name>"
GROUP="<path under DEV/, or empty for a project directly under DEV/>"   # e.g. apps, or apps/mobile
PROJ="$DEV/${GROUP:+$GROUP/}$NAME"
```

A group is a folder directly under `DEV/` with no `progress.md` (see `new-group`). `GROUP` may go deeper into the group (`apps/mobile`); the folders between the group and the project are plain folders with no rules of their own. List the existing groups with:

```bash
for g in "$DEV"/*/; do g="${g%/}"; case "$(basename "$g")" in _*) continue ;; esac; [ -f "$g/progress.md" ] || echo "$(basename "$g")"; done
```

## Steps

1. Ask the user for the project name if it is not given. Use a short, lowercase, hyphenated directory name. In the same message ask where the project goes: directly under `DEV/`, or a path inside an existing group (list the groups; the user may add a subfolder, for example `apps/mobile`). If the user names a group that does not exist, run `new-group` first and come back.
2. Confirm that `$PROJ` does not exist. If it exists, stop and tell the user.
3. Copy `$DEV/_template/` to `$PROJ/`.
4. Ask the user, in one message, for the facts that fill `$PROJ/CLAUDE.md`. Do not ask again for anything Brainstorming already settled; the problem sentence is the purpose.
   - three to five principles that will not change (if Brainstorming did not settle them)
   - sensitive paths: where a mistake is expensive (money, stored data, auth, external interfaces)
   - language and framework
   - package manager
   - run command, if known
   - check commands (build, test, lint), if any exist
   - if the project has a UI: visual direction, component library, UI stack, and the KRDS mode (`default`, `strict`, `off`); these go into `DESIGN.md`. If there is no UI, delete `DESIGN.md` and the `## Design` section.
   - files that must not be edited by hand
5. Set the `Harness:` line in `$PROJ/CLAUDE.md` to the content of `$DEV/VERSION`. Fill every `<...>` placeholder with the answers. Remove placeholder lines that do not apply. Keep the "Correction rules" section empty.
6. Fill `$PROJ/scripts/check.sh` with the check commands the user gave. Remove the example lines you do not use. Make the script executable.
   - If the user gave no check commands, leave every step commented out. The script then fails with "No checks configured". That failure is the correct state at this point. Do not add a placeholder step to make it pass.
7. Run `$PROJ/scripts/check.sh` once and record the result:
   - Checks configured and passed → note "checks: configured, pass" for `progress.md`.
   - Checks configured and failed → fix the script only if the error is in the script (a typo, a wrong path). If the project code is missing, note the failure for `progress.md`.
   - "No checks configured" → note "checks: not configured" for `progress.md`.
8. Link the shared harness into the project so Claude Code finds it from inside `$PROJ`:
   ```bash
   "$DEV/.claude/scripts/link-harness.sh" "$PROJ"
   ```
   It links every skill, every agent, `settings.json` (hooks), and `hooks/` with relative paths. Never replace these links with absolute paths: they are committed, and an absolute path leaks the home directory.
9. Fill `$PROJ/progress.md` and `$PROJ/ideas.md`:
   - Updated: today's date.
   - Goal: the problem sentence from Brainstorming.
   - In progress: the first-version features with their done conditions, from Brainstorming.
   - Open issues: the check result from step 7. If checks are not configured, write "checks: not configured. Add at least one step to scripts/check.sh before feature work."
   - Next action: "Add the first check to scripts/check.sh" when checks are not configured; otherwise the first feature from the list.
   - `ideas.md`: append the "later" list from Brainstorming.
10. Run `git init` in `$PROJ`. Stage the template files and `.claude/` (the links from step 8). Commit with the message `chore: scaffold project from template`.
    - Before the commit, run `git config user.email`. If it is empty, stop and tell the user to set the global git identity. Do not set it in the repository.
    - When `GROUP` is set, register the project in the group repository (the first folder of `GROUP`, `$DEV/${GROUP%%/*}`): append the project path relative to that folder, with a leading and a trailing slash (`/$NAME/`, or `/product/$NAME/` when `GROUP` is `apps/mobile`), to its `.gitignore`; add one line for the project under `## Projects` in its `CLAUDE.md`; commit both there with the message `chore: add project <name>`.
11. Create the GitHub repository and push (see "Git, GitHub, and personal information" in `dev/CLAUDE.md`):
    ```bash
    gh auth status || echo "NOT LOGGED IN"
    gh repo create "$NAME" --private --source "$PROJ" --remote origin --push
    ```
    - If `gh auth status` fails, skip this step. Add "GitHub repository not created: gh is not logged in" to Open issues in `progress.md`.
    - If a repository with that name already exists, stop and ask the user for another name or for permission to use the existing one.
12. Report to the user: the project path, the GitHub repository URL, the check result, and the next action.
