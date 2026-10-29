#!/usr/bin/env bash
# Harness self-test. Runs in a temporary directory and never touches DEV/.
# release.sh runs it first. Run it by hand after a change to hooks, scripts,
# or the commit procedure. Exits 1 on the first failed test.
set -euo pipefail
DEV="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export MSYS=winsymlinks:nativestrict
G=(git -c user.name=selftest -c user.email=selftest@example.invalid -c commit.gpgsign=false -c core.autocrlf=false)
pass=0; fail=0
ok()   { pass=$((pass+1)); echo "ok   $1"; }
bad()  { fail=$((fail+1)); echo "FAIL $1"; }

# --- 1. Template project: links, hook, check.sh ---------------------------
t1() {
  local p="$TMP/dev1/proj"
  mkdir -p "$TMP/dev1"
  cp -r "$DEV/_template" "$TMP/dev1/_template"
  # Copy .claude without the krds-* links: their target (_tools/) is not in the
  # test tree, and Windows refuses a symlink to a missing target.
  mkdir -p "$TMP/dev1/.claude"
  tar -C "$DEV" --exclude='.claude/skills/krds-*' -cf - .claude | tar -C "$TMP/dev1" -xf -
  cp "$DEV/VERSION" "$TMP/dev1/VERSION"
  cp -r "$DEV/_template" "$p"
  # new-project sets the version line from VERSION; do the same here.
  sed -i "s/^Harness: .*/Harness: $(cat "$DEV/VERSION")/" "$p/CLAUDE.md"
  (cd "$p" && "${G[@]}" init -q && git config core.autocrlf false && "${G[@]}" commit -q --allow-empty -m init)
  "$TMP/dev1/.claude/scripts/link-harness.sh" "$p" >/dev/null
  [ -L "$p/.claude/skills/migrate" ] && [ -L "$p/.claude/agents/Reviewer.md" ] && ok "link-harness links skills and agents" || bad "link-harness"
  case "$(readlink "$p/.claude/skills/migrate")" in /*) bad "link is absolute" ;; *) ok "links are relative" ;; esac
  local out
  out="$(cd "$p" && echo '{"source":"startup"}' | CLAUDE_PROJECT_DIR="$p" bash .claude/hooks/session-start.sh)"
  echo "$out" | grep -q "Task base:" && ok "hook records task base" || bad "hook task base"
  echo "$out" | grep -q "Harness version" && bad "hook warns on matching version" || ok "hook silent when versions match"
  (cd "$p" && bash scripts/check.sh >/dev/null 2>&1) && bad "empty check.sh passed" || ok "empty check.sh fails"
  (cd "$p" && sed -i 's|^# run_step test      true|run_step test      true|' scripts/check.sh; sed -i 's|^# run_step format    npx prettier --check .|run_step smoke     true|' scripts/check.sh; bash scripts/check.sh >/dev/null 2>&1) && ok "check.sh passes with one step" || bad "check.sh with a step"
}

# --- 2. Hook: v2 project warns; compact keeps base and separates files -----
t2() {
  local p="$TMP/dev1/old"
  mkdir -p "$p" && cd "$p" && "${G[@]}" init -q && git config core.autocrlf false
  printf '# old\n\nThe shared rules apply.\n\n## Purpose\n\nx\n' > CLAUDE.md
  "${G[@]}" add CLAUDE.md && "${G[@]}" commit -q -m init
  echo u > user.txt
  local out
  out="$(echo '{"source":"startup"}' | CLAUDE_PROJECT_DIR="$p" bash .claude/hooks/session-start.sh 2>/dev/null || true)"
  [ -f .claude/hooks/session-start.sh ] || out="$(echo '{"source":"startup"}' | CLAUDE_PROJECT_DIR="$p" bash "$TMP/dev1/.claude/hooks/session-start.sh")"
  echo "$out" | grep -q "Project: v2. DEV: $(cat "$DEV/VERSION")" && ok "hook detects v2 project" || bad "hook v2 detection"
  echo mine > task.txt
  out="$(echo '{"source":"compact"}' | CLAUDE_PROJECT_DIR="$p" bash "$TMP/dev1/.claude/hooks/session-start.sh")"
  echo "$out" | grep -A3 "Changed in this task" | grep -q "task.txt" && ok "compact lists task files as yours" || bad "compact task files"
  echo "$out" | grep -A3 "Changed before the task" | grep -q "user.txt" && ok "compact keeps pre-task files" || bad "compact pre-task files"
  cd "$TMP"
}

# --- 3. Commit procedure: user's index survives, task hunk only -----------
t3() {
  local p="$TMP/cp" patch
  mkdir -p "$p" && cd "$p" && "${G[@]}" init -q && git config core.autocrlf false
  seq 1 40 > f.txt && "${G[@]}" add f.txt && "${G[@]}" commit -q -m init
  echo u > user.txt && git add user.txt
  sed -i '5s/.*/5 USER/' f.txt && git add f.txt
  sed -i '35s/.*/35 TASK/' f.txt && echo t > task.txt
  # step 1
  patch="$(mktemp)"; git diff --cached > "$patch"; git reset -q
  # step 2
  git add task.txt
  # step 3: keep only the TASK hunk
  git diff -- f.txt > "$TMP/f.patch"
  # Keep the header and only the hunk that contains TASK (awk).
  awk '
    /^@@/ { if (buf != "" && keep) printf "%s", buf; buf = ""; keep = 0; inhunk = 1 }
    { if (inhunk) { buf = buf $0 "\n"; if ($0 ~ /TASK/) keep = 1 } else print }
    END { if (buf != "" && keep) printf "%s", buf }
  ' "$TMP/f.patch" > "$TMP/f.task.patch"
  git apply --cached --recount "$TMP/f.task.patch"
  git diff --cached | grep -q '^+5 USER' && bad "user hunk leaked into task commit" || ok "task commit excludes user hunk"
  "${G[@]}" commit -q -m task
  # step 6
  git apply --cached "$patch" && ok "user's staged changes restored" || bad "restore of user's index"
  git diff --cached | grep -q '^+5 USER' && git diff --cached --name-only | grep -q user.txt && ok "restored index holds both user changes" || bad "restored index content"
  cd "$TMP"
}

# --- 4. Review range includes the first commit ----------------------------
t4() {
  local p="$TMP/rr" base
  mkdir -p "$p" && cd "$p" && "${G[@]}" init -q && git config core.autocrlf false && "${G[@]}" commit -q --allow-empty -m base
  base="$(git rev-parse HEAD)"
  echo f > feature.txt && "${G[@]}" add feature.txt && "${G[@]}" commit -q -m feat
  [ "$(git diff --name-only "$base..HEAD" | wc -l)" -eq 1 ] && ok "base..HEAD includes the first commit" || bad "review range"
  cd "$TMP"
}

# --- 5. release.sh refuses a major version without a migration file --------
t5() {
  local out
  out="$(cd "$DEV" && bash -n scripts/release.sh 2>&1)" && ok "release.sh parses" || bad "release.sh syntax"
  [ -f "$DEV/migrations/$(cat "$DEV/VERSION" | sed 's/\..*//').md" ] && ok "migration file exists for current major" || bad "migration file for $(cat "$DEV/VERSION")"
}

# --- 6. Groups: DEV/<group>/<project>; hook, links, check.sh find DEV ------
t6() {
  local g="$TMP/dev1/grp" p="$TMP/dev1/grp/proj2" out
  cp -r "$DEV/_group-template" "$g"
  (cd "$g" && "${G[@]}" init -q && git config core.autocrlf false && "${G[@]}" add -A && "${G[@]}" commit -q -m group)
  cp -r "$DEV/_template" "$p"
  echo "/proj2/" >> "$g/.gitignore"
  (cd "$p" && "${G[@]}" init -q && git config core.autocrlf false && "${G[@]}" commit -q --allow-empty -m init)
  "$TMP/dev1/.claude/scripts/link-harness.sh" "$p" >/dev/null
  [ -f "$p/.claude/skills/migrate/SKILL.md" ] && [ -f "$p/.claude/hooks/session-start.sh" ] && ok "depth-2 links resolve" || bad "depth-2 links"
  out="$(cd "$p" && echo '{"source":"startup"}' | CLAUDE_PROJECT_DIR="$p" bash .claude/hooks/session-start.sh)"
  echo "$out" | grep -q "^Group: grp\." && ok "hook names the group inside a project" || bad "hook group line"
  out="$(cd "$TMP/dev1/proj" && echo '{"source":"startup"}' | CLAUDE_PROJECT_DIR="$TMP/dev1/proj" bash .claude/hooks/session-start.sh)"
  echo "$out" | grep -q "^Group:" && bad "depth-1 project reports a group" || ok "depth-1 project has no group line"
  # A project's own subfolder with progress.md is not a grouped project.
  mkdir -p "$TMP/dev1/proj/sub" && cp "$DEV/_template/progress.md" "$TMP/dev1/proj/sub/"
  out="$(cd "$TMP/dev1" && echo '{"source":"startup"}' | CLAUDE_PROJECT_DIR="$TMP/dev1" bash .claude/hooks/session-start.sh)"
  echo "$out" | grep -q "^- grp/proj2:" && ok "DEV root lists the grouped project" || bad "DEV root group listing"
  echo "$out" | grep -q "^- proj/sub:" && bad "DEV root lists a project's subfolder" || ok "DEV root skips a project's subfolder"
  echo "$out" | grep -q "^- grp:" && bad "DEV root lists the group as a project" || ok "DEV root skips the group itself"
  # A project deeper inside the group (grp/product/proj3) is listed and names the group.
  local p3="$TMP/dev1/grp/product/proj3"
  mkdir -p "$TMP/dev1/grp/product" && cp -r "$DEV/_template" "$p3"
  "$TMP/dev1/.claude/scripts/link-harness.sh" "$p3" >/dev/null
  out="$(cd "$TMP/dev1" && echo '{"source":"startup"}' | CLAUDE_PROJECT_DIR="$TMP/dev1" bash .claude/hooks/session-start.sh)"
  echo "$out" | grep -q "^- grp/product/proj3:" && ok "DEV root lists a depth-3 project" || bad "DEV root depth-3 listing"
  echo "$out" | grep -q "^- grp/product:" && bad "DEV root lists a middle folder" || ok "DEV root skips a middle folder"
  out="$(cd "$p3" && echo '{"source":"startup"}' | CLAUDE_PROJECT_DIR="$p3" bash .claude/hooks/session-start.sh)"
  echo "$out" | grep -q "^Group: grp\." && ok "depth-3 project names the top folder as its group" || bad "depth-3 group line"
  (cd "$g" && [ -z "$(git status --porcelain | grep proj2)" ]) && ok "group repo ignores the project folder" || bad "group gitignore"
  # check.sh resolves the same DEV from depth 1 and depth 2.
  local d1="" d2=""
  # Insert a probe step before the "no checks" guard; it writes $DEV to a file.
  for q in "$TMP/dev1/proj" "$p"; do
    sed -i 's|^if \[ "\$STEPS_RUN" -eq 0 \]; then|probe() { echo "$DEV" > .dev-probe; }; run_step probe probe\n&|' "$q/scripts/check.sh"
    (cd "$q" && bash scripts/check.sh >/dev/null 2>&1) || true
  done
  [ -f "$TMP/dev1/proj/.dev-probe" ] && d1="$(cat "$TMP/dev1/proj/.dev-probe")"
  [ -f "$p/.dev-probe" ] && d2="$(cat "$p/.dev-probe")"
  if [ -n "$d1" ] && [ "$d1" = "$d2" ] && [ "$(realpath "$d1")" = "$(realpath "$TMP/dev1")" ]; then
    ok "check.sh finds DEV from depth 1 and 2"
  else
    bad "check.sh DEV lookup ('$d1' vs '$d2')"
  fi
}

t1; t2; t3; t4; t5; t6
echo
echo "selftest: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
