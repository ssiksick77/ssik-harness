---
name: start
description: Start wizard for a fresh clone of the harness. Use when the user runs /start, says they just installed or cloned the harness, asks "where do I begin", or when DEV/ has no project yet and the user is new.
---

# start

Walk a new user from a fresh clone to their first project. Speak the user's language. One question per message. Do not write project code in this skill.

## Steps

1. Run the wizard script and read its output:
   ```bash
   scripts/setup.sh
   ```
   Run it from `DEV/`. If the current directory is a project, walk up to the directory that holds `_template/` and `.claude/skills/` first.
2. For every `TODO` line, explain in one or two plain sentences what it is for and show the command or setting from the script's list. Things the script cannot do (install a program, turn on Developer Mode, `gh auth login`) are the user's; wait until they say it is done, then run the script again. Stop when every line says `ok`.
3. Explain the harness in five lines: `CLAUDE.md` holds the rules Claude follows; each project is its own folder and its own GitHub repository under `DEV/`; `progress.md` is where a session resumes from; `scripts/check.sh` runs the project's checks after every change; `/wrap-up` saves and pushes. Point to `docs/harness-guide.html` for the long version.
4. Ask what the user wants to build first. If they have an idea, run the skill `brainstorm`, then `new-project`. If they have existing code, run `adopt-project`. If they have no idea yet, say that `claude` in `DEV/` plus "새 프로젝트를 시작하고 싶어" is the way back here, and stop.
