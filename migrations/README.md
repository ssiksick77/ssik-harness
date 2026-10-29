# migrations

One file per major harness version: `vN.md`. It lists what the skill `migrate` must change in a project that is on version N-1 (or older) to bring it to version N.

Rules for a migration file:
- Write it while the version is being built, one line per project-side change.
- Describe the change as a procedure ("add section X after section Y"), not as a diff. Project files hold user content; a diff would overwrite it.
- Never delete user content. Move it.
- Mark every step that needs a user decision with `[ask]`.
- A minor version (`v3.1`) has no file. `migrate` only updates the `Harness:` line.

`migrate` reads the files from the project's version up to `DEV/VERSION`, in order.
