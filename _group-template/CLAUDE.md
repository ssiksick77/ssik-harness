# <GROUP NAME>

This folder is a group: `DEV/<GROUP NAME>/<project>/`, or deeper, for example `DEV/<GROUP NAME>/product/<project>/`. The shared rules in `DEV/CLAUDE.md` apply here and in every project below. This file holds the rules and facts that all projects of the group share. Project facts stay in `<project>/CLAUDE.md`.

A group is not a project: it has no `progress.md`, no `scripts/check.sh`, and no work loop of its own. Its own git repository tracks this file and the shared material; each project folder is ignored here and has its own repository.

## Purpose

<One or two sentences. What the projects in this group have in common, and for whom.>

## Projects

<!-- One line per project. new-project and adopt-project add a line here. -->

- `<project>/` — <one line>

## Shared rules

<!-- Rules that hold for every project in the group. One per line. A rule for one project goes in that project's CLAUDE.md. -->

- <e.g. Write prompt text that the AI model reads in English; UI text in Korean.>

## Shared material

<!-- Folders in this group that are not projects: specs, reference docs, scripts without a harness. One line each. -->

- `<folder>/` — <role>
