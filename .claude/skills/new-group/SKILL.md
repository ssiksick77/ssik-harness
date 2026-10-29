---
name: new-group
description: Create a group folder under DEV/ that holds projects of a shared nature (DEV/<group>/<project>/). Use when the user asks to group projects, make a project bundle, or runs /new-group. A group is a small git repository with a CLAUDE.md of shared rules; the projects inside keep their own repositories.
---

# new-group

Create `DEV/<group>/` from `_group-template/`. Do not create or move projects in this skill; `new-project` and `adopt-project` take a group name.

## Paths

Find `$DEV` as `new-project` does (walk up until a directory holds `_template/` and `.claude/skills/`). Then:

```bash
GROUP="<group name>"
GDIR="$DEV/$GROUP"
```

## Rules

- A group sits directly under `DEV/`. No group inside a group. A project may sit at any depth inside the group (`<group>/<project>/` or `<group>/product/<project>/`); the folders in between are plain folders.
- A group has no `progress.md`. That is how the session hook tells a group from a project. Do not add one.
- A group name does not start with `_` (those folders belong to the harness).

## Steps

1. Ask the user for the group name if it is not given, and for one sentence on what the projects share. Use a short directory name without spaces.
2. Confirm that `$GDIR` does not exist. If it exists, stop and tell the user.
3. Copy `$DEV/_group-template/` to `$GDIR/` (both files: `CLAUDE.md`, `.gitignore`).
4. Fill `$GDIR/CLAUDE.md`: the name, the Purpose sentence, and any shared rules the user named. Leave the `Projects` and `Shared material` lists with their placeholder line when nothing is known yet.
5. Run `git init` in `$GDIR`, stage `CLAUDE.md` and `.gitignore`, and commit with the message `chore: create group`. Check `git config user.email` first as `new-project` step 10 does.
6. Create the GitHub repository and push, as `new-project` step 11 does, with `$GROUP` as the repository name. Skip when `gh auth status` fails and say so.
7. Report: the group path, the repository URL, and that the next step is `new-project` or `adopt-project` with this group.
