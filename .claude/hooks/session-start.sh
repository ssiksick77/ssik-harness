#!/usr/bin/env bash
# SessionStart hook. Prints the state that "Start of a session" in
# DEV/CLAUDE.md asks for. The output goes into Claude's context.
# It never blocks the session: every failure exits 0.
#
# Claude Code also fires SessionStart after a compact and on resume. The
# hook reads "source" from the JSON on stdin so that, after a compact, the
# files this session changed are not reported as someone else's.
# On a fresh start it records the task base (HEAD and the dirty files) in
# .claude/session-base.txt; later starts in the same task reuse it.
dir="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$dir" 2>/dev/null || exit 0

source="startup"
if [ ! -t 0 ]; then
  input="$(cat 2>/dev/null)"
  s="$(printf '%s' "$input" | sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$s" ] && source="$s"
fi

echo "## Session context: $(basename "$dir") (source: $source)"

if [ -f progress.md ]; then
  echo
  echo "### progress.md (Goal, Next action)"
  awk '/^## (Goal|Next action)/ {p=1; print; next} /^## / {p=0} p && NF' progress.md
fi

if [ -f ideas.md ]; then
  # Skip the example block inside <!-- ... -->.
  secs="$(awk '/<!--/ {c=1} !c && /^- \[later\]\[sec\]/ {print} /-->/ {c=0}' ideas.md)"
  if [ -n "$secs" ]; then
    echo
    echo "### ideas.md: open [later][sec] items (security; offer one of these first)"
    echo "$secs"
  fi
  fixes="$(awk '/<!--/ {c=1} !c && /^- \[later\]\[fix\]/ {print} /-->/ {c=0}' ideas.md)"
  if [ -n "$fixes" ]; then
    echo
    echo "### ideas.md: open [later][fix] items (offer at most one)"
    echo "$fixes"
  fi
fi

# Harness version: compare the project's "Harness:" line with DEV/VERSION.
# A project is "not DEV itself" when it has no _template/. A missing line means v2.
if [ ! -d _template ] && [ -f CLAUDE.md ]; then
  devver=""
  d="$dir"
  while [ "$d" != "/" ]; do
    if [ -f "$d/VERSION" ] && [ -d "$d/_template" ]; then devver="$(cat "$d/VERSION")"; break; fi
    d="$(dirname "$d")"
  done
  projver="$(sed -n 's/^Harness: *//p' CLAUDE.md | head -1)"
  [ -n "$projver" ] || projver="v2"
  if [ -n "$devver" ] && [ "$projver" != "$devver" ]; then
    echo
    echo "### Harness version"
    echo "Project: $projver. DEV: $devver. Offer the skill 'migrate' to the user once, then continue."
  fi
  # Group: the top-level folder under DEV that holds this project, when the
  # project is not directly under DEV. Folders between them are plain folders.
  if [ -n "$devver" ]; then
    rel="${dir#"$d"/}"
    case "$rel" in
      */*)
        echo
        echo "### Group"
        echo "Group: ${rel%%/*}. Its CLAUDE.md applies here; shared material lives in the group repository."
        ;;
    esac
  fi
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo
  echo "### git"
  echo "Branch: $(git branch --show-current 2>/dev/null)"
  git log --oneline -3 2>/dev/null
  base_file=".claude/session-base.txt"
  head="$(git rev-parse HEAD 2>/dev/null)"
  if [ "$source" = "startup" ] || [ ! -f "$base_file" ]; then
    # Fresh task: record the base. The dirty files here are not this task's.
    dirty="$(git status --short 2>/dev/null | grep -v '^?? \.claude/session-base\.txt$')"
    mkdir -p .claude
    { echo "base_sha=$head"; echo "recorded=$(date +%Y-%m-%dT%H:%M:%S)"; echo "pre_dirty:"; printf '%s\n' "$dirty"; } > "$base_file"
    echo "Task base: $head (recorded now)"
    total="$(printf '%s' "$dirty" | grep -c . || true)"
    if [ "$total" -gt 0 ]; then
      echo "Changed before this session ($total files; not yours; do not commit or unstage):"
      printf '%s\n' "$dirty" | head -20
      [ "$total" -le 20 ] || echo "... and $((total - 20)) more. Run 'git status --short' for the full list."
    else
      echo "Working tree: clean"
    fi
  else
    # Compact or resume inside the same task: keep the recorded base.
    base_sha="$(sed -n 's/^base_sha=//p' "$base_file")"
    echo "Task base: $base_sha (from $base_file; pass base..HEAD to Reviewer)"
    pre="$(sed -n '/^pre_dirty:/,$p' "$base_file" | tail -n +2)"
    now="$(git status --short 2>/dev/null | grep -v '^?? \.claude/session-base\.txt$')"
    if [ -n "$pre" ]; then
      echo "Changed before the task started (not yours):"
      echo "$pre" | head -20
    fi
    mine="$(comm -13 <(echo "$pre" | sort) <(echo "$now" | sort))"
    if [ -n "$mine" ]; then
      echo "Changed in this task (yours; continue with them):"
      echo "$mine" | head -20
    fi
  fi
fi

# DEV root: list the projects and check the KRDS submodule.
# A project is any folder with progress.md, at any depth inside a group, but
# not inside another project. Folders named _*, .*, or node_modules are skipped.
if [ -d _template ] && [ -d .claude/skills ]; then
  echo
  echo "### Projects"
  found=0
  last=""
  while IFS= read -r p; do
    p="${p#./}"
    # DEV's own progress.md is not a project.
    case "$p" in */*) ;; *) continue ;; esac
    proj="${p%/progress.md}"
    # Skip a progress.md inside a project already listed (paths come sorted).
    case "$proj" in "$last"/*) continue ;; esac
    last="$proj"
    found=1
    next="$(awk '/^## Next action/ {p=1; next} /^## / {p=0} p && NF {print; exit}' "$p")"
    echo "- $proj: ${next:-<no next action>}"
  done < <(find . -maxdepth 6 \( -name '_*' -o -name '.?*' -o -name node_modules \) -prune -o -name progress.md -print 2>/dev/null | LC_ALL=C sort)
  [ "$found" -eq 1 ] || echo "(none yet)"
  [ -f _tools/future-krds/skills/krds-plan/SKILL.md ] ||
    echo "WARNING: KRDS submodule is missing. Run 'git submodule update --init' in DEV/."
fi
exit 0
