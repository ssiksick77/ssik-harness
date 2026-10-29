#!/usr/bin/env bash
# Runs every check for this project, in order. Stops at the first failure.
# Claude runs this after each change (see DEV/CLAUDE.md, "Work loop").
#
# Fill the steps below for this project. Remove the lines you do not need.
# Each step is "run_step <label> <command>" so a label cannot be counted
# without its command. A command that needs a pipe or quotes goes in a
# function: f() { ...; }; run_step <label> f
# If no step is configured, this script FAILS on purpose. "No checks" is not
# the same as "checks passed". If the project has no tests yet, keep at least
# one step that proves the program starts (see the last example).

set -euo pipefail
cd "$(dirname "$0")/.."

# DEV root: walk up until a directory holds _template/ and .claude/skills/.
# Write "$DEV/_tools/...", never "../_tools": the project may sit inside a group.
DEV="$PWD"
while [ "$DEV" != "/" ] && ! { [ -d "$DEV/_template" ] && [ -d "$DEV/.claude/skills" ]; }; do
  DEV="$(dirname "$DEV")"
done

# run_step <label> <command...>
# Prints the label, runs the command, and counts it only when the command ran.
STEPS_RUN=0
run_step() {
  local label="$1"; shift
  echo; echo "== $label"
  "$@"
  STEPS_RUN=$((STEPS_RUN + 1))
}

# --- Examples. Replace with the real commands. ---------------------------

# run_step format    npx prettier --check .
# run_step lint      npx eslint .
# run_step typecheck npx tsc --noEmit
# run_step test      npm test

# run_step lint      ruff check .
# run_step typecheck mypy src
# run_step test      pytest -q

# run_step build     cargo build
# run_step test      cargo test

# Project with a UI: accessibility check (WCAG 2.1 AA) of a built page.
# One line per page. See "Checks" in .claude/skills/ui-work/SKILL.md.
# run_step a11y      .claude/skills/ui-work/scripts/a11y-check.sh dist/index.html

# Minimum for a project with no tests: prove it starts.
# run_step smoke     timeout 10 python -I src/main.py --help >/dev/null

# ------------------------------------------------------------------------

if [ "$STEPS_RUN" -eq 0 ]; then
  echo
  echo "FAIL: No checks configured. Add at least one step to scripts/check.sh."
  exit 1
fi

echo
echo "All $STEPS_RUN checks passed."
