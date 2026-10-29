#!/usr/bin/env bash
# Accessibility check (WCAG 2.1 AA) of one page: pa11y with the axe runner.
# Usage: a11y-check.sh <page.html | URL>
# Exits non-zero when pa11y finds an error. The first run downloads pa11y
# and a headless Chrome into the npm and puppeteer caches.
set -euo pipefail
[ $# -eq 1 ] || { echo "Usage: $0 <page.html | URL>" >&2; exit 2; }
command -v npx >/dev/null || { echo "FAIL: npx is not on PATH." >&2; exit 2; }

case "$1" in
  http://*|https://*) target="$1" ;;
  *)
    [ -f "$1" ] || { echo "FAIL: page not found: $1 (build the page first)" >&2; exit 2; }
    p="$(realpath "$1")"
    # Git Bash gives /c/...; Chrome needs C:/... in a file URL.
    command -v cygpath >/dev/null && p="$(cygpath -m "$p")"
    target="file:///${p#/}" ;;
esac

exec npx --yes pa11y@10.0.0 --runner axe --standard WCAG2AA "$target"
