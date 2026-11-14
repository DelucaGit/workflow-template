---
name: issue
description: Turn a plain-language idea, feature or bug into GitHub issues that follow WORKFLOW.md (PRD → Epic → Story → Task, labels, sub-issues, Blocked by, board in Backlog). Use when the user types /issue, or asks to create, write or file a GitHub issue, epic, story, task or bug.
---

# /issue

Create GitHub issues in the current repo that follow `~/.claude/workflow-template/WORKFLOW.md`. Read that file first if it is not already in context. The templates in `~/.claude/workflow-template/.github/ISSUE_TEMPLATE/` give the exact headings for each type.

Helper script: `bash ~/.claude/skills/issue/scripts/gh-link.sh <command>` (commands below). Run everything from the project folder.

## Fixed rules

- Everything written to GitHub is **English**: titles, bodies, comments. Talk to the user in their language.
- Title prefixes: `[PRD]`, `[Epic]`, `[Story]`, `[Task]`, `[Bug]`.
- Labels: exactly one `type:*`. `priority:*` only on stories and bugs. `size:s` or `size:m` only on tasks; anything bigger is split. `status:blocked` on any issue with an open blocker.
- Everything lands in **Backlog** on the board. This skill never moves anything to Ready or further.
- Nothing is created before the user approves the draft.

## Flow

1. **Setup** – run `gh-link.sh setup`. It creates whatever is missing (the 11 labels, a board with Backlog/Ready/In progress/In review/Done) without asking. Tell the user in one line what it created, if anything.
2. **Understand** – read the user's description. If they named a level ("story under #12", "tasks for #20", "bug"), use it. Otherwise decide the level yourself (see Levels).
3. **Duplicates** – `gh issue list --state open --search "<key words>"` with 2–3 searches. If something looks similar, say so in the draft: "Looks like #18 *…*. Create anyway, or add as a comment on #18?"
4. **Draft** – show the full draft in chat: tree of titles, labels, parent, Blocked by, and each body filled in with the template headings. Then stop and wait.
5. **Create** – after the user's yes, for each issue in top-down order:
   - `gh issue create --title … --body-file … --label …` (write bodies to temp files)
   - `gh-link.sh sub <parent> <child>` for each parent link
   - `gh-link.sh block <issue> <blocker>` for each Blocked by
   - `gh-link.sh board <issue>` to add it to the board in Backlog
6. **Report** – list the created issues as links in a tree.

## Levels

| User gives | Create |
|---|---|
| A big goal with several deliveries | **Epic** + its thinnest first story that still goes end to end. No PRD: the epic stays loose until the user plans it into a version. |
| Something a user can try | **Story** under the epic it belongs to (ask which if unclear, or leave it under none). **No tasks.** |
| "tasks for #N" (N is a story) | Four **tasks** under #N, see Tasks. |
| Something broken | **Bug**, see Bugs. |
| "PRD for vX" | **PRD** + milestone `vX` (`gh-link.sh milestone vX`). Ask which loose epics to put under it. |

## Tasks

Only when asked for a specific story. Read the code first so the file sections are real.

- Four tasks, in this order: **1. backend/logic → 2. API → 3. frontend → 4. end-to-end test**. Drop a layer the project does not have and say so. Each task is Blocked by the one before.
- Each task body: **What to do**, **Files to change / Files to create / Files read-only** (write "none" when empty), **Acceptance criteria** (testable), **Size**, **Out of scope**.
- Max 100 000 tokens of work per task; split anything bigger.
- File conflicts: list open tasks (`gh issue list --label type:task --state open`) and read their file sections. If an open task changes the same file, add Blocked by to it, unless they clearly touch different parts of the file.

## Bugs

Check which story is *In progress* on the board (`gh-link.sh in-progress`).
- If the bug breaks that story's end-to-end test or the feature being built, propose a **task under that story** (`type:task`, `size:*`).
- Otherwise propose a **bug** (`type:bug` + `priority:*`) in Backlog.
State which one you chose and why in one line of the draft. Bug body: **What happened**, **What should happen**, **Steps to reproduce**, **Environment**.

## Story and epic bodies

Plain language, no technical terms.
- Epic: **What is delivered**, **Why it is needed**, **How we know it is done**.
- Story: **As a [who] I want [what] so that [why]**, **Acceptance criteria** a person can see or try.
- Stories get a `priority:*` you propose.

## When something fails

Stop. Tell the user what failed, why if known, the options, and your recommendation. Retry the exact same command once only for an obvious network blip.
