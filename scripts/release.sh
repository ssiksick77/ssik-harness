#!/usr/bin/env bash
# Releases a harness version: writes VERSION, commits, tags, and pushes.
# Usage: scripts/release.sh vN[.M]   (run from DEV/ on the branch to release)
# A major version (vN) needs migrations/vN.md. A minor version (vN.M) does not.
set -euo pipefail
[ $# -eq 1 ] || { echo "Usage: $0 vN[.M]" >&2; exit 2; }
v="$1"
[[ "$v" =~ ^v[0-9]+(\.[0-9]+)?$ ]] || { echo "FAIL: version must look like v3 or v3.1" >&2; exit 2; }
cd "$(dirname "$(realpath "$0")")/.."
[ -z "$(git status --porcelain)" ] || { echo "FAIL: commit or stash your changes first." >&2; exit 1; }
if [[ "$v" =~ ^v[0-9]+$ ]] && [ ! -f "migrations/$v.md" ]; then
  echo "FAIL: migrations/$v.md is missing. A major version needs one." >&2; exit 1
fi
git rev-parse "$v" >/dev/null 2>&1 && { echo "FAIL: tag $v already exists." >&2; exit 1; }
bash scripts/selftest.sh || { echo "FAIL: selftest failed. Fix it before you release." >&2; exit 1; }
if [ "$(cat VERSION 2>/dev/null)" != "$v" ]; then
  echo "$v" > VERSION
  # The template's version line must match; selftest compares it with VERSION.
  sed -i "s/^Harness: .*/Harness: $v/" _template/CLAUDE.md
  git add VERSION _template/CLAUDE.md
  git commit -m "chore: release harness $v"
else
  echo "VERSION is already $v; tagging HEAD."
fi
git tag -a "$v" -m "Harness $v"
git push origin HEAD
git push origin "$v"
echo "Released $v."
