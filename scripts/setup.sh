#!/usr/bin/env bash
# Start wizard. Checks that this PC can run the harness and fixes what it
# can (the KRDS submodule). Prints one line per check and, at the end, what
# is left for you to do. Safe to run again. Run it from Git Bash:
#   scripts/setup.sh
DEV="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DEV"
export MSYS=winsymlinks:nativestrict
todo=()
ok()  { echo "ok    $1"; }
bad() { echo "TODO  $1"; todo+=("$2"); }

command -v git >/dev/null && ok "git $(git --version | awk '{print $3}')" \
  || bad "git is not installed" "Install Git for Windows: https://git-scm.com/download/win"
command -v realpath >/dev/null && ok "GNU coreutils (realpath)" \
  || bad "realpath is missing" "Run this script from Git Bash, not PowerShell or cmd"

name="$(git config --global user.name || true)"; mail="$(git config --global user.email || true)"
if [ -n "$name" ] && [ -n "$mail" ]; then
  ok "git identity: $name <$mail>"
  case "$mail" in *@users.noreply.github.com) ;; *) echo "      note: a noreply address keeps your email private: git config --global user.email \"<id>+<login>@users.noreply.github.com\"" ;; esac
else
  bad "git identity is not set" "git config --global user.name \"<nickname>\" && git config --global user.email \"<id>+<login>@users.noreply.github.com\""
fi

if command -v gh >/dev/null; then
  gh auth status >/dev/null 2>&1 && ok "gh logged in" || bad "gh is not logged in" "gh auth login  (GitHub.com, HTTPS, browser)"
else
  bad "gh is not installed" "Install GitHub CLI: https://cli.github.com"
fi

command -v claude >/dev/null && ok "claude $(claude --version 2>/dev/null | head -1)" \
  || bad "Claude Code is not installed" "Install it from https://code.claude.com/docs then run: claude"

# Symbolic links: the harness links its skills into every project.
t="$(mktemp -d)"
if ln -s "$t" "$t/link" 2>/dev/null && [ -L "$t/link" ]; then ok "symbolic links (Developer Mode)"
else bad "symbolic links are refused" "Windows Settings > System > For developers > Developer Mode: On. Then open a new Git Bash"; fi
rm -rf "$t"

if [ -f _tools/future-krds/skills/krds-plan/SKILL.md ]; then ok "KRDS submodule"
elif git submodule update --init >/dev/null 2>&1; then ok "KRDS submodule (downloaded now)"
else bad "KRDS submodule not downloaded" "git submodule update --init  (needs network)"; fi

echo
if [ ${#todo[@]} -eq 0 ]; then
  echo "All checks pass. Next: run 'claude' in this folder and type /start"
else
  echo "${#todo[@]} thing(s) to do, then run scripts/setup.sh again:"
  for t in "${todo[@]}"; do echo "  - $t"; done
  exit 1
fi
