# Sink or Swim — Game Vision

This document captures the current vision for **Sink or Swim** so the team and AI agents can build the same game without drifting into extra features.

---

# Core Concept

**Sink or Swim** is a 2D fake-computer desktop game about being a college student trying to get hired before graduation while money, debt, burnout, rejection, and interview pressure pile up.

The whole game is the computer screen.

The player is not walking around a world. The player is living inside a fake laptop/desktop interface where every app represents part of the job-search struggle:

- resume
- work/actions
- interview prep
- projects
- job board
- interviews
- money/debt
- burnout

The desktop is the game world.

The player opens windows, clicks apps, manages stats, receives notifications, builds projects, adds resume keywords, applies to jobs, and tries to get an offer before their checking account goes negative or they burn out.

---

# One-Sentence Pitch

**Sink or Swim** is a fake-desktop strategy game where your resume is your character build, job applications are your battles, Discover debt is the timer, and getting a job offer is how you stay afloat.

---

# Design Inspiration

The game should feel like a fake computer desktop, similar in spirit to games where the operating system itself is the game space.

The interface should feel like:

- a Mac-style desktop
- a laptop the player is trapped in during recruiting season
- a student job-search command center
- a stressful but playable simulation of applying, improving, interviewing, and surviving

The player should feel like they are inside the laptop where the job hunt actually happens.

---

# Title / Identity

Current title:

```text
Sink or Swim
```

The title captures the pressure of the game:

> You either get hired and stay afloat, or the combined pressure of money, debt, burnout, and rejection pulls you under.

---

# Main Player Goal

The player’s goal is:

```text
Get a job offer before checking goes negative, burnout breaks you, or graduation catches up.
```

The game is about survival through the job market.

---

# The Game Board

The game board is a fake desktop.

## Top Menu Bar

The top menu bar is always visible.

It should show the player’s key survival stats:

- current week
- money/checking account
- Discover debt
- burnout %
- confidence %
- interview skill %
- score
- current resume keywords
- End Week button / clock

The money value should become visually urgent when low.

The debt value should appear once Discover debt activates.

Current resume keywords should appear as scrolling or compact tags in the menu bar, so the player can always see their “build.”

## Bottom Dock

The bottom dock is the main navigation.

It should have Mac-style app icons. Hovering can make them bounce. Open windows should have a small dot indicator.

Dock apps:

1. **Resume**
2. **Work**
3. **Interview Prep**
4. **Projects**
5. **Job Board**
6. **Interview**

Each dock icon opens its own window.

---

# Main Windows

## Resume Window

Purpose:

Shows the player’s current resume build.

Contents:

- unlocked keywords
- projects completed
- resume score
- run stats
- visual keyword tags
- current resume strength
- job-readiness summary

Keywords should appear visually as tags or squiggles on/near the resume.

This is where the player sees what companies are reading.

## Work Window

Purpose:

This is the weekly actions window.

The player uses it to spend the week.

Possible actions:

- blast applications
- side gig
- network
- rest

These actions change stats like:

- money
- burnout
- confidence
- application count
- score
- keywords, if relevant

Work actions should have clear costs and effects.

## Interview Prep Window

Purpose:

Lets the player prepare for interviews before taking the real interview.

Prep options can include:

- mock interview
- DSA practice
- system design practice
- company research

Interview prep should improve the player’s interview skill and/or answer quality.

Interview prep may cost time, increase burnout, or compete with other actions.

## Projects Window

Purpose:

Lets the player build projects to improve the resume.

Projects unlock keywords and improve job match scores.

Projects should take time and should not all progress linearly. Some projects can give more or fewer points depending on time spent, difficulty, or completion state.

The player should have multiple buildable projects.

For the current vision, use 6 buildable projects.

Each project should show:

- project name
- progress
- time/effort cost
- keywords unlocked
- score gained
- burnout cost
- whether it helps interview prep

When a project is completed, it should add keywords to the Resume Window and improve matching on the Job Board.

## Job Board Window

Purpose:

Shows available jobs and match percentage.

Each job listing should show:

- company/job name
- icon
- match %
- required keywords
- status
- whether the player can apply
- whether the player has applied
- whether an interview is available

The job board should update live as the player gains keywords.

Jobs should feel like targets with thresholds.

When the player improves their resume, match percentages should change immediately.

Include a fallback job:

```text
McDonald's
```

The fallback job can appear with a very low or unusual match state and should support the game’s humor/pressure.

## Interview Window

Purpose:

The real interview minigame.

This window should be locked until the player qualifies for an interview.

Unlock condition:

```text
The player reaches the required match threshold for a job and applies.
```

The interview should use JSON-based questions and answers.

Each interview question should have:

- question text
- answer choices
- correct/strong answers
- weak/bad answers
- alignment scoring
- possible feedback

The interview result determines whether the player gets the job, gets rejected, or receives a bad/weak offer state.

---

# Core Game Loop

Each week, the player uses the fake desktop to decide what to do.

```text
Start week
↓
Check stats in top menu bar
↓
Open windows from dock
↓
Choose work/actions
↓
Build projects or improve interview prep
↓
Apply to jobs when match is high enough
↓
Receive notifications/results
↓
End week manually or by idle timer
↓
Debt, burnout, applications, and job matches update
↓
Repeat until offer or loss
```

The player should always be asking:

```text
What should I do this week so I can get hired before I sink?
```

---

# Week System

The game is turn-based by week.

Week 1 should act as a soft tutorial.

Week 1 should teach:

- where the stats are
- how to open windows
- how to perform actions
- how keywords affect job match
- why money/debt matters
- why burnout matters
- how to end the week

A week can end in two ways:

1. the player clicks **End Week**
2. the idle timer runs out

The idle timer creates pressure if the player freezes.

Current target:

```text
30-second idle timer
```

If the player does nothing for too long, the game auto-ends the week.

---

# Action Points / Weekly Activities

The player should not be able to do everything every week.

Weekly activities should cost points, time, or limited opportunity.

Actions should affect different systems.

Examples:

| Action | Main Benefit | Cost / Risk |
|---|---|---|
| Blast applications | More applications sent | Burnout, rejection risk |
| Side gig | Money gained | Burnout, less career progress |
| Network | Better job opportunities | Time, uncertain payoff |
| Rest | Burnout decreases | No direct progress |
| Mock interview | Interview skill improves | Time/burnout |
| DSA practice | Technical interview prep improves | Time/burnout |
| Company research | Interview alignment improves | Time |
| Build project | Resume keywords improve | Time/burnout |

Actions should show floating point popups when clicked.

Examples:

```text
+$180
+React
+Burnout
+Interview Skill
-Confidence
```

---

# Player Stats

The player stats should be visible through the desktop UI.

Core stats:

- week
- checking/money
- Discover debt
- burnout
- confidence
- interview skill
- score
- resume keywords
- applications sent
- active interviews
- completed projects

These stats should drive the game.

They are not decoration.

---

# Resume / Keyword System

The resume is the player’s build.

Keywords are the main things companies score.

Keywords come from:

- completed projects
- interview prep
- networking/actions
- resume improvements

Keywords should appear as visual tags in:

- Resume Window
- top menu bar
- Job Board match calculations

Examples of keywords:

- React
- SQL
- Python
- Dashboard
- Git
- DSA
- Systems
- Communication
- Leadership
- Interview Prep
- Full Stack
- Data
- UI

The Job Board should recalculate match percentages when keywords change.

---

# Project System

Projects are how the player earns stronger resume keywords.

Projects should have nonlinear progress or scoring.

This means:

- some projects may give small early gains and large completion rewards
- some projects may require multiple weeks
- some projects may be high risk/high reward
- some projects may be better aligned with certain jobs

Project completion should:

- add keywords
- improve score
- improve job match %
- unlock resume tags
- possibly help interview answers

For the current build, use 6 buildable projects.

Agents should not invent a huge project list unless asked.

---

# Job Board / Match System

The Job Board shows jobs with live match percentages.

Each job should have:

- name
- icon
- required keywords
- match %
- application state
- interview lock/unlock state
- offer state

The match percentage should update when the player gains keywords.

Basic flow:

```text
Build projects / prep / resume keywords
↓
Resume keywords update
↓
Job Board match % updates
↓
Player applies when match is high enough
↓
Interview unlocks
↓
Interview determines offer/rejection
```

Jobs should only “read” or meaningfully evaluate resume data after the player applies or after a certain week/application condition, depending on the intended pacing.

This prevents the board from becoming too solved too early.

---

# Application System

Applications are how the player moves from resume-building to interviews.

The player can apply to jobs from the Job Board.

Application outcomes can include:

- rejected
- ghosted
- viewed
- interview unlocked
- bad offer
- good offer

Notifications should appear as toasts.

Examples:

```text
Application sent.
Resume viewed.
Rejected.
Interview unlocked.
Offer received.
```

---

# Interview System

The Interview Window is locked until the player qualifies.

Unlock condition:

```text
Reach the required match threshold for a job, then apply.
```

The interview system should be data-driven using JSON.

Each question should include:

- question text
- multiple answer options
- scoring values
- correct/wrong/aligned answer labels
- feedback text

Interview answers can be scored by:

- interview prep
- skill alignment
- keywords
- confidence
- burnout
- answer choice

The game can later integrate an LLM API for feedback on answers, but this is not required for the core build.

For now, use JSON-based Q&A.

---

# Finance / Discover Debt System

Money pressure is one of the core systems.

The player has a checking account/money value.

When money reaches zero, Discover debt activates.

Debt should feel automatic and threatening.

Rules from current vision:

1. Work/side gig puts money into checking.
2. Discover debt collects minimum payments from checking.
3. If checking goes negative, the player loses.
4. There can be a one-time lifeline.

The loss condition should be clear:

```text
If checking goes negative → lose
```

Debt should not be treated as random flavor. It is part of the survival clock.

---

# Burnout System

Burnout tracks when the player works too hard.

Burnout should increase from:

- blasting applications
- side gigs
- building projects
- heavy interview prep
- rejection outcomes

Burnout should decrease from:

- rest

Burnout should affect:

- interview performance
- ability to take actions
- risk of losing

The player should understand that grinding every week has a cost.

---

# Notifications / Toasts

The game should use notifications to make the fake desktop feel alive.

Notifications should appear for:

- action results
- application outcomes
- debt collections
- money changes
- burnout warnings
- keywords unlocked
- project completion
- interview unlocks
- win/loss states

Notifications should feel like system popups from the fake computer.

---

# Floating Point Popups

Every action should create small floating popups showing what changed.

Examples:

```text
+$180
-$50 debt payment
+React
+Burnout
+Confidence
-Confidence
+Interview Skill
```

These make the game feel responsive.

---

# Win States

The player wins by getting a job offer.

There can be different offer states:

- bad offer
- good offer

A good offer is the ideal win.

A bad offer can be accepted if the player is desperate, depending on final scope.

For MVP, one offer state is enough.

Win screen should clearly show:

```text
You got the job.
You stayed afloat.
```

---

# Lose States

Primary lose condition:

```text
Checking goes negative.
```

Other possible lose conditions:

- burnout reaches breaking point
- graduation arrives with no offer
- debt overwhelms the player

For the current simplified build, prioritize:

```text
Checking negative → lose
```

Keep the loss text grounded.

---

# Current Working UI Direction

The intended UI direction is:

```text
Fake Mac desktop
```

Required layout:

## Top

Mac-style menu bar with:

- money
- debt
- burnout
- confidence
- interview skill
- score
- scrolling keywords
- week counter
- End Week button / clock

## Center

Desktop space where windows open.

Windows should be draggable if possible.

Each dock app opens a window in the desktop area.

## Bottom

Mac-style dock with icons:

- Resume
- Work
- Interview Prep
- Projects
- Job Board
- Interview

Dock icons should feel alive, with bounce/hover and open-window dot indicators.

---

# Required App Windows For Current Scope

Build these app windows:

1. Resume
2. Work
3. Interview Prep
4. Projects
5. Job Board
6. Interview

Do not add extra apps unless asked.

---

# Godot Scene Direction

This is a 2D UI game.

Use Godot `Control` scenes.

Core scenes:

```text
Main.tscn
BootScreen.tscn
Desktop.tscn
TopMenuBar.tscn
Dock.tscn
DesktopWindow.tscn
ResumeWindow.tscn
WorkWindow.tscn
InterviewPrepWindow.tscn
ProjectsWindow.tscn
JobBoardWindow.tscn
InterviewWindow.tscn
WinScreen.tscn
LoseScreen.tscn
ToastNotification.tscn
FloatingPointPopup.tscn
```

Do not build 3D scenes.

---

# MVP Implementation Priority

Build in this order:

1. Title screen
2. Boot/loading sequence
3. Fake desktop
4. Top menu bar stats
5. Bottom dock
6. Window opening/closing
7. Work window actions
8. Resume keywords display
9. Projects window keyword unlocks
10. Job board match % updates
11. Application/interview unlock flow
12. Interview JSON Q&A
13. Discover debt/checking loss
14. Toast notifications
15. Floating point popups
16. Win screen
17. Lose screen

---

# What Agents Should Not Add

Do not add these unless explicitly requested:

- 3D gameplay
- open world
- real job scraping
- login/accounts
- multiplayer
- huge procedural company system
- full email client
- complex finance simulation beyond Discover/checking rules
- real LLM integration before JSON Q&A works
- extra dock apps
- complex story mode
- character customization

Focus on the fake desktop loop.

---

# Core Architecture Rule

The UI should not own all the logic.

Use managers/systems.

Suggested managers:

```text
GameManager
WeekManager
PlayerState
WindowManager
ActionManager
ResumeManager
KeywordManager
ProjectManager
JobBoardManager
ApplicationManager
InterviewManager
FinanceManager
BurnoutManager
NotificationManager
EndingManager
```

UI windows should call manager functions.

Managers update state.

The desktop refreshes based on state.

Example:

```text
Player clicks Build Project
↓
ProjectsWindow calls ProjectManager.build_project(project_id)
↓
ProjectManager updates project progress
↓
KeywordManager unlocks keywords if completed
↓
ResumeManager updates resume tags
↓
JobBoardManager recalculates match %
↓
NotificationManager shows toast
↓
FloatingPointPopup shows point changes
```

---

# Main Design Principle

The game should always feel like the player is choosing between survival and career progress.

Examples:

```text
Side gig gives money but increases burnout.
Rest lowers burnout but costs a week.
Projects improve resume but take time.
Interview prep helps offers but does not pay bills.
Applications can create opportunities but also rejection.
Debt takes money automatically.
```

The player should never feel like there is one obvious perfect move.

---

# Final Scope Reminder

This game is not just a dashboard.

It is a fake computer desktop where every window is part of the survival strategy.

The core loop is:

```text
Open desktop apps
↓
Choose weekly actions
↓
Gain keywords / money / burnout / debt
↓
Apply to jobs
↓
Unlock interviews
↓
Answer interview questions
↓
Get offer or go negative
```

Build only what supports that loop.
