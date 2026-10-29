#!/usr/bin/env bash
# KRDS markup score for one built HTML page. Advisory: not a check.sh step.
# Usage: krds-score.sh <page.html> [min-score]   (default min-score: 95)
# Exits 1 when the score is below min-score.
# Wraps _tools/future-krds/scripts/krds-similarity.mjs, which reads its
# ruleset from the current directory, so this script runs it from there.
set -euo pipefail
[ $# -ge 1 ] && [ $# -le 2 ] || { echo "Usage: $0 <page.html> [min-score]" >&2; exit 2; }
command -v node >/dev/null || { echo "FAIL: node is not on PATH." >&2; exit 2; }
[ -f "$1" ] || { echo "FAIL: page not found: $1 (build the page first)" >&2; exit 2; }

page="$(realpath "$1")"
min="${2:-95}"
here="$(dirname "$(realpath "$0")")"
krds="$(realpath "$here/../../../../_tools/future-krds")"
ref="$(realpath "$here/../data/krds-reference.html")"
[ -f "$krds/scripts/krds-similarity.mjs" ] || { echo "FAIL: run 'git submodule update --init' in DEV/." >&2; exit 2; }

cd "$krds"
# The scorer exits 1 below its own fixed threshold; this script applies min instead.
out="$(node scripts/krds-similarity.mjs "$page" "$ref")" || true
printf '%s' "$out" | MIN="$min" node -e '
  const r = JSON.parse(require("fs").readFileSync(0, "utf8"));
  const min = Number(process.env.MIN);
  console.log(`KRDS score ${r.score} (minimum ${min})`);
  if (r.summary.failed.length) console.log("Failed rules: " + r.summary.failed.join(", "));
  process.exit(r.score >= min ? 0 : 1);
'
