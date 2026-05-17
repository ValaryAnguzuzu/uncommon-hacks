# Sink or Swim

**Sink or Swim** is an Uncommon Hacks 2026 prototype about surviving the job search before graduation catches up.

You play through a fake desktop OS as a college student trying to land an offer while managing money, debt, burnout, confidence, resume signal, projects, applications, and interviews.

## Game Loop

- Open desktop apps like Resume, Work, Prep, Projects, Jobs, Interview, and Discover.
- Spend limited weekly actions to earn money, build proof, improve skills, apply to jobs, or recover.
- Ship projects to unlock resume keywords.
- Match resume keywords against job listings.
- Unlock interviews, prep, and try to convert one into an offer.
- Survive weekly expenses, debt pressure, and burnout.
- Win by getting an offer before graduation.
- Lose if money, burnout, or time runs out.

## How to Run

1. Open Godot.
2. Import this folder by selecting `project.godot`.
3. Press Play.

The main scene is set to:

```text
res://BootScreen.tscn
```

## Architecture Overview

The game is structured like a fake operating system.

```text
BootScreen
  -> Desktop
      -> TopMenuBar
      -> Dock
      -> App Windows
      -> Tips / Toasts / Score Feedback
      -> WinScreen or LoseScreen
```

## Core Systems

### PlayerState

`scripts/PlayerState.gd` is the shared source of truth for the current run.

It stores:

- week number
- checking balance
- debt
- burnout
- confidence
- interview skill
- score / coins
- resume keywords
- completed projects
- applications sent
- unlocked interviews
- win/loss state

UI scenes read from `PlayerState` and refresh when `PlayerState.state_changed` is emitted.

### GameManager

`scripts/GameManager.gd` controls the high-level game flow.

It handles:

- starting a run
- ticking down the week timer
- ending weeks
- applying rent, food, and debt costs
- rolling weekly events
- resolving interviews
- checking win/loss conditions

### Desktop Shell

`Desktop.tscn` and `scripts/Desktop.gd` act as the fake OS shell.

They handle:

- opening app windows
- layering and focusing windows
- desktop icons
- dock actions
- tips from `data/messages.json`
- toast notifications
- floating score/coin feedback

### App Windows

Each major gameplay area is its own scene/script pair:

```text
ResumeWindow
WorkWindow
InterviewPrepWindow
ProjectsWindow
JobBoardWindow
InterviewWindow
DiscoverStatementWindow
TodayStatsWindow
```

Each window owns its local UI but updates shared game data through `PlayerState`.

## Data-Driven Content

Content is stored in JSON files:

```text
data/projects.json
data/jobs.json
data/messages.json
```

This makes it easier to add jobs, project types, keywords, and dynamic tips without rewriting the core game logic.

## Prototype Status

This is an early prototype built for a hackathon. The current focus is game feel, clarity, and a complete playable loop rather than final balance or polish.
