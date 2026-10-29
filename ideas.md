# ideas

Features and fixes set aside for later. Append only; never delete. Change the status when an item is done or dropped.

Format: `- [status][kind] YYYY-MM-DD: <item> — <one line of context>`
Status: `later`, `done`, `dropped`
Kind: `idea` = a new feature or screen, set aside during brainstorming. `fix` = an improvement to existing code, noticed during the work loop. `sec` = a confirmed finding from a security audit; fix before `fix` items.

Who reads what:
- `brainstorm` reads the `[later][idea]` lines.
- The session start step reads the `[later][fix]` lines and offers at most one to the user when it fits the current task.
- The session start step also lists `[later][sec]` lines. Offer one of these before any `[later][fix]`.
- `wrap-up` commits this file together with `progress.md`.

