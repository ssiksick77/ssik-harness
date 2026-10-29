---
name: <PROJECT NAME>
description: <one-line tagline>
# Tokens are added by `/impeccable document` once there is code to scan.
# Until then, leave this frontmatter as it is.
---

# Design System: <PROJECT NAME>

This file is the single place for the visual rules of this project. `DEV/CLAUDE.md` and the skill `ui-work` read it; Impeccable reads and rewrites the canonical sections (`document`, `doctor`). The section "Harness" belongs to the harness and is never rewritten by Impeccable.

## Harness

<!-- Read by ui-work. Keep the keys and the exact values. -->

- KRDS: default
  <!-- default: KRDS structure and accessibility are a reference; this file and Impeccable decide. The a11y check in scripts/check.sh is the floor.
       strict: KRDS wins on structure, accessibility, and wording; the KRDS markup score is reported each round.
       off: no KRDS skill runs; only the a11y check applies. Use for host-app extensions and single-screen tools. -->
- Component library: <none | name>
- UI stack: <e.g. plain HTML, React, Svelte, SillyTavern extension UI>

## Overview

<Visual direction in two or three sentences: mood, density, what it must not look like. Example: "Dense, plain, keyboard-first. A tool used all day; nothing decorative.">

## Do's and Don'ts

<!-- Project-specific UI rules, one per line. Impeccable keeps this section and may add to it. -->

- <e.g. Every table is sortable by its header.>
- <e.g. Money is right-aligned, integer won, thousands separators.>
