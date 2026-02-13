# Ralph

![Ralph](ralph.webp)

Ralph is an autonomous AI agent loop that runs AI coding tools ([Copilot CLI](https://docs.github.com/en/copilot) or [Claude Code](https://docs.anthropic.com/en/docs/claude-code)) repeatedly until all PRD items are complete. Each iteration is a fresh instance with clean context. Memory persists via git history, `progress.txt`, and `prd.json`.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

[Read my in-depth article on how I use Ralph](https://x.com/ryancarson/status/2008548371712135632)

## Quick Start

Run this one-liner in your project directory to install Ralph:

```powershell
iex (irm https://raw.githubusercontent.com/snarktank/ralph/main/init-ralph.ps1)
```

This creates `scripts\ralph\` with everything you need, and updates your `.gitignore`.

## Prerequisites

- One of the following AI coding tools installed and authenticated:
  - [Copilot CLI](https://docs.github.com/en/copilot) (default)
  - [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`npm install -g @anthropic-ai/claude-code`)
- PowerShell 5.1+ (included with Windows) or PowerShell 7+ (cross-platform)
- A git repository for your project

## Setup

### Option 1: Copy to your project

Copy the ralph files into your project:

```powershell
# From your project root
New-Item -ItemType Directory -Path scripts\ralph -Force
Copy-Item \path\to\ralph\ralph.ps1 scripts\ralph\
Copy-Item \path\to\ralph\CLAUDE.md scripts\ralph\
```

### Option 2: Install skills globally

Copy the skills to your Claude config for use across all projects:

```powershell
Copy-Item -Recurse skills\prd $env:USERPROFILE\.claude\skills\
Copy-Item -Recurse skills\ralph $env:USERPROFILE\.claude\skills\
```

### Option 3: Use as Claude Code Marketplace

Add the Ralph marketplace to Claude Code:

```bash
/plugin marketplace add snarktank/ralph
```

Then install the skills:

```bash
/plugin install ralph-skills@ralph-marketplace
```

Available skills after installation:
- `/prd` - Generate Product Requirements Documents
- `/ralph` - Convert PRDs to prd.json format

Skills are automatically invoked when you ask Claude to:
- "create a prd", "write prd for", "plan this feature"
- "convert this prd", "turn into ralph format", "create prd.json"

## Workflow

### 1. Create a PRD

Use the PRD skill to generate a detailed requirements document:

```
Load the prd skill and create a PRD for [your feature description]
```

Answer the clarifying questions. The skill saves output to `tasks/prd-[feature-name].md`.

### 2. Convert PRD to Ralph format

Use the Ralph skill to convert the markdown PRD to JSON:

```
Load the ralph skill and convert tasks/prd-[feature-name].md to prd.json
```

This creates `prd.json` with user stories structured for autonomous execution.

### 3. Run Ralph

```powershell
# Using Copilot CLI (default)
.\scripts\ralph\ralph.ps1 [-MaxIterations 10]

# Using Claude Code
.\scripts\ralph\ralph.ps1 -Tool claude [-MaxIterations 10]
```

Default is 10 iterations. Use `-Tool copilot` or `-Tool claude` to select your AI coding tool.

Ralph will:
1. Create a feature branch (from PRD `branchName`)
2. Pick the highest priority story where `passes: false`
3. Implement that single story
4. Run quality checks (typecheck, tests)
5. Commit if checks pass
6. Update `prd.json` to mark story as `passes: true`
7. Append learnings to `progress.txt`
8. Repeat until all stories pass or max iterations reached

## Key Files

| File | Purpose |
|------|---------|
| `ralph.ps1` | The PowerShell loop that spawns fresh AI instances (supports `-Tool copilot` or `-Tool claude`) |
| `CLAUDE.md` | Shared prompt template used by both tools |
| `prd.json` | User stories with `passes` status (the task list) |
| `prd.json.example` | Example PRD format for reference |
| `progress.txt` | Append-only learnings for future iterations |
| `skills/prd/` | Skill for generating PRDs |
| `skills/ralph/` | Skill for converting PRDs to JSON |
| `.claude-plugin/` | Plugin manifest for Claude Code marketplace discovery |
| `flowchart/` | Interactive visualization of how Ralph works |

## Flowchart

[![Ralph Flowchart](ralph-flowchart.png)](https://snarktank.github.io/ralph/)

**[View Interactive Flowchart](https://snarktank.github.io/ralph/)** - Click through to see each step with animations.

The `flowchart/` directory contains the source code. To run locally:

```powershell
cd flowchart
npm install
npm run dev
```

## Critical Concepts

### Each Iteration = Fresh Context

Each iteration spawns a **new AI instance** (Copilot CLI or Claude Code) with clean context. The only memory between iterations is:
- Git history (commits from previous iterations)
- `progress.txt` (learnings and context)
- `prd.json` (which stories are done)

### Small Tasks

Each PRD item should be small enough to complete in one context window. If a task is too big, the LLM runs out of context before finishing and produces poor code.

Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

Too big (split these):
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### AGENTS.md Updates Are Critical

After each iteration, Ralph updates the relevant `AGENTS.md` files with learnings. This is key because AI coding tools automatically read these files, so future iterations (and future human developers) benefit from discovered patterns, gotchas, and conventions.

Examples of what to add to AGENTS.md:
- Patterns discovered ("this codebase uses X for Y")
- Gotchas ("do not forget to update Z when changing W")
- Useful context ("the settings panel is in component X")

### Feedback Loops

Ralph only works if there are feedback loops:
- Typecheck catches type errors
- Tests verify behavior
- CI must stay green (broken code compounds across iterations)

### Browser Verification for UI Stories

Frontend stories should include browser verification in acceptance criteria when browser testing tools are available. If no browser tools are available, note in the progress report that manual verification is needed.

### Stop Condition

When all stories have `passes: true`, Ralph outputs `<promise>COMPLETE</promise>` and the loop exits.

## Debugging

Check current state:

```powershell
# See which stories are done
(Get-Content prd.json | ConvertFrom-Json).userStories | Select-Object id, title, passes

# See learnings from previous iterations
Get-Content progress.txt

# Check git history
git log --oneline -10
```

## Customizing the Prompt

After copying `CLAUDE.md` to your project, customize it for your project:
- Add project-specific quality check commands
- Include codebase conventions
- Add common gotchas for your stack

## Archiving

Ralph automatically archives previous runs when you start a new feature (different `branchName`). Archives are saved to `archive/YYYY-MM-DD-feature-name/`.

## References

- [Geoffrey Huntley's Ralph article](https://ghuntley.com/ralph/)
- [Copilot CLI documentation](https://docs.github.com/en/copilot)
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
