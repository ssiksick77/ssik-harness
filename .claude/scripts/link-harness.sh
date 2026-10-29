#!/usr/bin/env bash
# Links the shared harness into a project with relative symlinks:
# every skill, every agent, settings.json (hooks), and the hooks directory.
# Usage: link-harness.sh <project-dir>
# Safe to run again: it adds missing links and never replaces a file.
# Run it again after DEV/ gains a new skill or agent.
set -euo pipefail
# Git Bash (MSYS) makes copies for "ln -s" unless told to make real links.
# Real links need Windows Developer Mode or admin rights.
export MSYS=winsymlinks:nativestrict
[ $# -eq 1 ] || { echo "Usage: $0 <project-dir>" >&2; exit 2; }
proj="$(realpath "$1")"
[ -d "$proj" ] || { echo "FAIL: not a directory: $1" >&2; exit 2; }
dev="$(realpath "$(dirname "$(realpath "$0")")/../..")"
[ "$proj" != "$dev" ] || { echo "FAIL: the project cannot be DEV/ itself." >&2; exit 2; }

# link <target in DEV> <link path in project>
link() {
  local target="$1" path="$2" rel
  rel="$(realpath -s --relative-to="$(dirname "$path")" "$target")"
  if [ -L "$path" ] && [ "$(readlink "$path")" = "$rel" ]; then
    return
  elif [ -e "$path" ] || [ -L "$path" ]; then
    echo "skip (exists): ${path#"$proj"/}"
  else
    ln -s "$rel" "$path"
    echo "link: ${path#"$proj"/} -> $rel"
  fi
}

mkdir -p "$proj/.claude/skills" "$proj/.claude/agents"
for d in "$dev"/.claude/skills/*/; do
  d="${d%/}"
  link "$d" "$proj/.claude/skills/$(basename "$d")"
done
for f in "$dev"/.claude/agents/*.md; do
  link "$f" "$proj/.claude/agents/$(basename "$f")"
done
link "$dev/.claude/hooks" "$proj/.claude/hooks"
link "$dev/.claude/settings.json" "$proj/.claude/settings.json"

if [ -e "$proj/.claude/settings.json" ] && [ ! -L "$proj/.claude/settings.json" ]; then
  echo "WARNING: the project has its own .claude/settings.json."
  echo "Copy the \"hooks\" block from DEV/.claude/settings.json into it by hand."
fi
