# workflow-template

Shared working rules for all projects: how we use GitHub (epics, stories, tasks, labels, board, sprints, PRs and releases).

This repo is the single source of truth. The rules live in `WORKFLOW.md`, and the labels and templates live here so every new project gets exactly the same pattern.

## `/issue` skill

`skills/issue/` is a Claude Code skill that turns a plain-language idea or bug into GitHub issues that follow `WORKFLOW.md`: it proposes the level, checks for duplicates, shows a draft, and after approval creates the issues with labels, sub-issues, Blocked by and Backlog status on the board. Missing labels or a missing board are created automatically.

### Install (once per machine)

Clone this repo to `~/.claude/workflow-template`, then link the skill folder so Claude Code finds it in every project.

Windows (directory junction, no admin rights needed):

```powershell
New-Item -ItemType Junction -Path "$HOME\.claude\skills\issue" -Target "$HOME\.claude\workflow-template\skills\issue"
```

macOS / Linux:

```bash
ln -s ~/.claude/workflow-template/skills/issue ~/.claude/skills/issue
```

To update: `git -C ~/.claude/workflow-template pull`.

Work on this repo itself is tracked under [Issues](../../issues).
