---
name: ui-work
description: Rules and checks for any task that touches a screen, a form, or a user-facing layout. Use before UI work starts — a new screen, a layout or form change, or visual polish. Reads the KRDS mode from DESIGN.md and sets the order of DESIGN.md, KRDS, and impeccable, plus the accessibility check in scripts/check.sh.
---

# ui-work

Run this before the first UI change of a task. These rules apply to every project under `DEV/`.

## Before you start

1. Read `DESIGN.md` in the project root. Its `## Harness` section holds `KRDS: default | strict | off`, the component library, and the UI stack. If `DESIGN.md` is missing, the project is on harness v2 or has no UI section yet: run `migrate`, or ask the user for the three values and create the file from `_template/DESIGN.md`.
2. Run `/skills`. Confirm that `impeccable` and `break-ui` are listed. `security-audit` is optional; its absence does not block UI work. For `default` and `strict`, also confirm `krds-plan` and `krds-improve`.
3. If a KRDS skill is missing, the submodule is probably not checked out. Tell the user to run `git submodule update --init` in `DEV/`.
4. If another skill is missing, run `DEV/.claude/scripts/link-harness.sh <project>`.
5. Do not continue the UI work while a required skill is missing. Tell the user which one.

## Order, by KRDS mode

`DESIGN.md` is always the first authority: its tokens, Overview, and Do's and Don'ts describe this project. The mode decides what fills the gaps.

### `default` (most projects)

1. Read `DESIGN.md`. Where it answers a question (layout, density, component shape, wording), follow it.
2. For a new screen, run `krds-plan` as a reference. For an existing screen, `krds-improve` is optional; run it when the user asks or when the screen is a form or a table. Take its structure, component choices, and accessibility notes as input, not as a verdict. Do not apply the KRDS theme, colors, fonts, or design tokens. Do not use `krds-transform`.
3. Run `impeccable` for the visual work.
4. On a conflict between KRDS and Impeccable, `DESIGN.md` decides. If it is silent, prefer the denser and simpler option, and write the decision into `## Do's and Don'ts` so the next screen matches.

### `strict` (public-service delivery, or when the user says so)

1. For a new screen, run `krds-plan`. For an existing screen, run `krds-improve`. These set structure, components, accessibility, and wording.
2. Do not apply the KRDS theme, colors, fonts, or design tokens unless the user asks for `krds-transform`.
3. Then run `impeccable` for visual quality inside that structure.
4. On a conflict, KRDS wins for structure, accessibility, and wording. Impeccable decides visual style inside that limit. `DESIGN.md` may narrow, not override, the KRDS rules.
5. Run the KRDS markup score at the baseline and after each round (see Checks).

### `off` (host-app extensions, single-screen tools, non-web UI)

1. Read `DESIGN.md`. Follow the host application's conventions where there is a host.
2. Run `impeccable` for the visual work.
3. No KRDS skill runs. The accessibility check still applies when the UI is HTML.

## Checks

Three kinds, kept apart. Run the scripts from the project root.

### Automated: accessibility (in `scripts/check.sh`)

- Script: `.claude/skills/ui-work/scripts/a11y-check.sh <page.html | URL>`
- It runs pa11y with the axe runner against WCAG 2.1 AA. Any error fails the step. This is the floor in every mode, including `off`, for HTML UI.
- Add one `run_step` line per page. Prefer built static files. A URL needs a running server.
- The first run downloads pa11y and a headless Chrome. It needs network access once.

### Advisory: KRDS markup score (`strict` only; never in `scripts/check.sh`)

- Script: `.claude/skills/ui-work/scripts/krds-score.sh <page.html> [min-score]` (default minimum: 95)
- Run it at the baseline and after each improvement round. Report the score and the delta to the user.
- Warning: the score only matches markup patterns (KRDS anchor ids, `krds-*` class names, a table, a form, and a badge on every page). The KRDS reference page itself scores 77.78. Do not add `krds-*` classes or elements only to raise the score.
- In `default` and `off`, do not run it unless the user asks.

### Human review (every mode)

Run both after the screen is complete. Their output is advice for the user, not a pass or fail.

- `/impeccable critique`: hierarchy, clarity, visual quality.
- `break-ui`: feed the screen worst-case data (long names, empty lists, huge counts, non-Latin text, emoji) and list what breaks with a fix for each. Append each real break to `ideas.md` as a `[later][fix]` line, or fix it in the current task when it is inside scope.

## Files

- `scripts/a11y-check.sh`: the accessibility check (pa11y pinned to 10.0.0).
- `scripts/krds-score.sh`: wraps `DEV/_tools/future-krds/scripts/krds-similarity.mjs`.
- `data/krds-reference.html`: the KRDS home page, used as the score reference.
- `DEV/.claude/skills/break-ui/`: vendored from Emil Kowalski's skills repository (see its `VENDOR.md`).
- Do not edit `DEV/_tools/future-krds/`. It is the upstream submodule. Put harness changes in this skill.
