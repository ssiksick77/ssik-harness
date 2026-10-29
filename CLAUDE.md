# DEV/ — shared coding harness

This file applies to every project under `DEV/`. It holds only the rules that do not change between projects. Project facts (stack, commands, design, corrections) live in `<project>/CLAUDE.md`. Procedures live in the skills in `DEV/.claude/skills/`.

The harness needs bash, GNU coreutils (`realpath`), git, and symbolic links. On Windows run Claude Code from Git Bash or WSL; PowerShell alone is not enough.

## Start of a session

The SessionStart hook prints a "Session context" block: the Goal and Next action from `progress.md`, the open `[later][sec]` and `[later][fix]` items, the git state, the task base commit, and a harness version mismatch when there is one. On a fresh start it records the base commit and the files that were already dirty in `.claude/session-base.txt` (not committed). After a compact or a resume it reads that file back, so the files this task changed are listed as yours.

1. Read `<project>/CLAUDE.md` and the "Session context" block. On a fresh clone of `DEV/` with no project yet, offer the skill `start` once.
2. If the Next action disagrees with `git log` or the code, trust the code and the git state. Note the difference.
3. The user's current request wins over the recorded Next action.
4. The files listed under "Changed before this session" or "Changed before the task started" belong to the user or to another task. Do not commit them. Files under "Changed in this task" are yours; continue with them.
5. If a `[later][sec]` item exists, offer it first. Otherwise, if a `[later][fix]` item fits the current task, offer it once. Do not offer more than one.
6. If the block is missing, the hook did not run. Run `git status` and read `progress.md` and `ideas.md` yourself.
7. Read the files named in the task before you edit them. Delegate to the `Explore` agent (overridden in `DEV/.claude/agents/` to run on Haiku) when you do not know where to look, when the search would read far more than you need afterwards, or when the project is unfamiliar. Reading a few known small files is faster by hand. Before you change a file, read the file itself, not only Explore's summary of it.

## Brainstorming mode

Run the skill `brainstorm`, without asking, when:

1. a new empty project starts (not when `adopt-project` brings in existing code),
2. the task adds a new screen, a new command, or a new data structure (a bug fix, a change, or a refactor goes to "Clarify the request"),
3. the user asks for it (for example `/brainstorm`, "let's brainstorm", "아이디어 정리").

When the user speaks at idea level ("what if...", "~하면 어떨까", "~가 있으면 좋겠는데"), ask once: "Do you want to brainstorm this first?"

`brainstorm` reads "Principles" in `<project>/CLAUDE.md` and drops any approach that breaks one. The work loop does the same: a principle is not traded away for convenience. If a task cannot be done without breaking a principle, that is a scope change; ask the user.

## Clarify the request before work

Do not start the work loop on an ambiguous request. Ambiguous means that two reasonable readings lead to different code, or that the result cannot be checked.

1. Restate the request in one sentence: what the user wants, for whom, and how the result is checked.
2. Ask only about a guess whose answer changes the scope or the done condition. Decide the rest yourself. Do not ask about anything the user already told you.
3. Ask one question, or a small set of related questions, per message. Ask about the need, not the implementation. Offer concrete options when they help.
4. Stop when no remaining guess changes the scope or the done condition. Tell the user your own decisions in one line.
5. Write the sentence into `progress.md` as the Goal before the first change.

When a later step reveals a new ambiguity, pause and ask the same way.

## Work loop

Repeat until the task is done or a blocker stops you:

1. Choose one small change that you can reverse.
2. Make the change inside the task scope (see "ponytail"). Before the first edit to a file under "Sensitive paths" in `<project>/CLAUDE.md`, tell the user which files the task will touch there and why, and wait for a yes. One yes covers those files for the rest of the task; a new sensitive file needs a new yes. Append an unrelated improvement to `ideas.md` as a `[later][fix]` line instead of making it.
3. Run `scripts/check.sh` and read the output. "No checks configured" is a failure. Treat it as a blocker.
4. If a check fails, fix the cause. Do not remove or weaken the check.
5. When the check passes, commit with "Commit procedure". Follow the commit rule in `<project>/CLAUDE.md`.
6. Decide the next change from the result.

Do not make several large changes at once. For UI work, run the skill `ui-work` before the first UI change.

## Commit procedure

Every change in a commit belongs to this task. File names alone do not prove that. The order below matters: secure the user's index before you stage anything.

1. Snapshot the index before any staging. If `git diff --cached --quiet` reports staged changes, they are the user's: save them with `git diff --cached > "$(mktemp)"`, note the path, and clear the index with `git reset -q` (this unstages only; it changes no file). This is the one place the harness unstages the user's work, and it restores it in step 6.
2. Stage, by name, the files that only this task changed. Never use `git add -A` or `git add .`. Never use `git add -p`; it needs an interactive terminal.
3. For a file that mixes this task's edits with edits that were there before (see the session context):
   - Write `git diff -- <file>` to a temporary patch file outside the repository (`mktemp`). The index is clean for that file after step 1, so this diff holds both sets of edits.
   - Delete the hunks that are not from this task.
   - Run `git apply --cached --recount <patch>`. If it fails, do not retry with a different patch; leave the file out and record it.
4. Read the whole `git diff --cached`. If it still holds a change from another task, unstage that part and read again.
5. Commit. Leave `progress.md` and `ideas.md` out of code commits; `wrap-up` commits them.
6. Restore the user's staged changes from step 1: `git apply --cached <saved patch>`. If it fails, stop and tell the user where the saved patch is. Do not delete the patch file.

If you cannot split the changes safely, skip the commit, restore the user's index (step 6), and continue. Record in `progress.md` which changes are waiting and why. A patch file keeps text changes; file-mode changes, binary files, and renames are not reproduced. If the user's staged changes include one of those, do not run step 1; skip the commit and tell the user.

## ponytail

The plugin `ponytail` (from `DietrichGebert/ponytail`, user scope) keeps code minimal. If `/ponytail` is not available, tell the user and continue without it.

- Mode: `lite`, the default in `~/.config/ponytail/config.json`. At session start, run `/ponytail` with no argument and confirm `lite`. Do not use `full` or `ultra`.
- Scope: step 2 of the work loop only. Not during `brainstorm`, "Clarify the request", or `wrap-up`.
- The harness wins on conflict. "When to ask the user" decides when to ask, not ponytail's "do not stall".
- `scripts/check.sh` steps are never "code to delete". Its "one small test" goes into `scripts/check.sh` or the test suite.
- Its `shortcut: <limit>, <when to upgrade>` comments mark a deliberate simplification. Older code may use `ponytail:`. When you write one, also append the item to `ideas.md` as a `[later][fix]` line.

## Security audit

The skill `security-audit` (from `cloudflare/security-audit-skill`) runs a multi-phase audit with independent verification. It is optional and vendored into `DEV/.claude/skills/` when installed. If `/skills` does not list it, tell the user once and skip this section. It is heavy: several subagents, one run per invocation. Do not run it in the work loop.

Run it, in full mode, only:

- before the first release of a project that other people will use or that is published,
- when a feature that handles auth, payment, file upload, or an external API is complete,
- when the user asks.

How:

1. Ask the user before a full run. Say that it starts subagents and takes a while.
2. Run it on the project root. Its reports go outside the repository (`~/security-audit-skill/<repo>/run-N/`); do not copy them in.
3. Read `findings.json`. Append each `confirmed` finding to `ideas.md` as a `[later][sec]` line with the run number. Show the `needs_validation` list to the user and let them decide. Ignore `rejected`.
4. Do not apply the fixes it proposes directly. Each fix goes through the work loop and `scripts/check.sh`.
5. Record in `progress.md` under Decisions: the date, the run number, and the number of confirmed findings.

For a single question ("is this input handling safe?") use its guidance mode in conversation; that needs no approval.

## Attempt limit

- If the same check fails 3 times in a row, change your approach.
- At 5 failures, stop. Record the blocker with `wrap-up`. Report what you tried and why it failed.

## When to ask the user

Ask only when:

- the request is ambiguous (see "Clarify the request before work"),
- the change moves the goal or the scope,
- the action cannot be reversed (delete, send, publish, deploy),
- the change touches a path listed under "Sensitive paths" in `<project>/CLAUDE.md`,
- the action needs credentials or external access (a private GitHub repository from `new-project` or `adopt-project` is already approved),
- this task's changes and earlier changes overlap, and you cannot split them,
- the work direction changes,
- a large feature is complete, or a change touched a Sensitive path (one question: update `progress.md` and review).

For all other decisions, decide and continue. Record a decision in `progress.md` when it affects later work.

## progress.md and review

Update `progress.md` with the skill `wrap-up`:

- without asking, when a blocker stops the work or the user ends the session,
- when the user asks for an update,
- after asking, when a large feature is complete or the work direction changes.

When a large feature is complete, or when a change of any size touched a Sensitive path, ask one question: "Update progress.md and run a review now?" On yes, run the `Reviewer` agent before `wrap-up`:

1. Commit the task's changes first (work loop step 5). The review range is `<base_sha>..HEAD`, where `base_sha` is the task base from the session context (`.claude/session-base.txt`). It is the commit before the task's first commit, so the first commit is included.
2. Call `Reviewer` with the project root, that range, the Goal, the done conditions from `progress.md` (In progress and Done), and round 1. Default model and effort come from its definition (Sonnet, high). If the feature touched a path under "Sensitive paths", call it with `model: fable` and `effort: high` instead: the same model as the main session, but in a fresh context and with more thinking time.
3. Fix every `Important` finding in the work loop. Decide each `Nit` yourself; say which ones you skipped.
4. Call `Reviewer` again for round 2 (then 3 if needed) with: the new range since the last review, the previous report in full, and the list of its `Important` IDs that you fixed. It rechecks every open `Important` at its original location, even on unchanged lines. Stop after round 3. If an `Important` is still open, record it in `progress.md` under Open issues and tell the user; do not start a fourth round.
5. Add the missing checks the review names to `scripts/check.sh` in the same task.
6. Then run `wrap-up`. Record in Decisions: the rounds run and the Important count per round.

Do not run `Reviewer` for a small change outside Sensitive paths; `scripts/check.sh` is the review there. Size is not the test; impact is.

## Git, GitHub, and personal information

- `DEV/` is its own repository. It tracks only the shared harness. After a clone, run `git submodule update --init`.
- `_tools/future-krds` is the upstream KRDS submodule. Do not edit it.
- Each project has its own private GitHub repository, created by `new-project` or `adopt-project` with `gh`. Ask before you make a repository public.
- Push only in `wrap-up`, or when the user asks. If `gh auth status` fails, tell the user to run `gh auth login`.
- Commit author: a nickname and the GitHub noreply address (`<id>+<login>@users.noreply.github.com`). Set them once in `~/.gitconfig`; `scripts/setup.sh` checks that they are set. Do not set `user.name` or `user.email` in a repository.
- Do not write the user's real name, personal email address, or home path into any file: author fields, `LICENSE` headers, file headers, docs, or symlink targets. If a tool generates such a field, remove it.
- Before the first push of a repository, search the tracked files for the user's email address and home path.

## Projects and harness versions

- Empty start → `new-project` (after `brainstorm`). Existing code → `adopt-project`. Project already on the harness, older version → `migrate`.
- All three run `DEV/.claude/scripts/link-harness.sh <project>`. It links the skills, the agents, `settings.json`, and `hooks/` with relative paths.
- `DEV/VERSION` holds the harness version. Each project records the version it is on in the `Harness:` line of its `CLAUDE.md`. A missing line means `v2`.
- When the session context reports a version mismatch, offer `migrate` once. Do not run it without the user's yes.
- Projects of a shared nature can sit in a group: `DEV/<group>/<project>/`, or deeper (`DEV/<group>/product/<project>/`); the folders between the group and the project are plain folders. No group inside a group. `new-group` creates a group from `_group-template/`; `new-project` and `adopt-project` ask once where a project goes.
- A project is a folder with `progress.md`, found at any depth inside a group but never inside another project. A group has no `progress.md`; it has a `CLAUDE.md` with the shared rules (Claude Code reads it for every project below) and its own small git repository that ignores the project folders. Folders that start with `_` are neither. Do not put a `progress.md` in a folder that is not a project.
- A project never reaches `DEV/` by counting parents (`../_tools`). It walks up to the directory that holds `_template/` and `.claude/skills/`, as `_template/scripts/check.sh` does.
- A release is made with `scripts/release.sh vN[.M]`. It runs `scripts/selftest.sh` first. A major version changes project files and needs `migrations/vN.md`; a minor version changes only `DEV/` files.

## Correction rules

When the user corrects a mistake, write the rule so the next session does not repeat it:

- Rule for this project only → `<project>/CLAUDE.md`, section "Correction rules".
- Rule for every project → "Correction rules (shared)" below. Tell the user that you changed the shared file.

When a committed change turns out to be broken later (a bug found in a later session, a revert, a user report), do not stop at the fix. Ask: which check should have caught this? Then:

- A check can catch it → add a `run_step` to `scripts/check.sh` (or a test the suite runs) in the same task as the fix.
- No check can catch it → write a correction rule as above.
- Record the answer in `progress.md` under Decisions, in one line: what broke, what now catches it.

## Writing rules for records

Write `progress.md`, commit messages, and correction rules in English (based on ASD-STE100):

- One instruction per sentence. Keep sentences under 20 words.
- Use the active voice and the present tense or the imperative.
- Use the same word for the same thing.
- Use no more than three nouns in a row. Do not omit articles or verbs.
- Write procedures in order. Put warnings before the step they apply to.

## Correction rules (shared)

<!-- Add one rule per line. Format: - YYYY-MM-DD: rule -->
