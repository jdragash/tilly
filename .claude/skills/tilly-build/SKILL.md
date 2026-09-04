---
name: tilly-build
description: Use when implementing approved Tilly work in the iOS app — building a screen from an agreed design, adding engine logic, or iterating on something already running in the simulator. Triggers on "let's build this", "implement the timeline", "make that change in the app". The main back-and-forth loop for developing Tilly.
---

# tilly-build

## Model

**Sonnet.** This is execution against decisions already made. If a genuine design question
surfaces mid-build — not "which shade" but "this layout doesn't work and needs rethinking"
— stop and say so: "This is a real design call, not an implementation detail. Worth an
Opus pass with `tilly-explore` before I keep going?" Don't quietly redesign in Sonnet.

## Read first

- **The plan at `docs/plans/<slug>.md`** — this is the specification. If no plan exists,
  stop and run `tilly-plan` rather than improvising one. Building without a plan means
  making design and architecture decisions in Sonnet, which is the thing the workflow is
  arranged to avoid.
- The brief at `docs/briefs/<slug>/brief.md` and the relevant `docs/DECISIONS.md` entries
- `CLAUDE.md` — the hard rules, especially the `Core/` boundary and the token rule
- `docs/DESIGN.md` — tokens, state grammar, copy rules

## Execute one step at a time

Work the plan's steps in order. For each: build it, run its stated verification command,
report the real output, then stop and confirm before starting the next. Don't run three
steps together because they look small.

**If a step is wrong, stop.** The specs were written before the code existed, so some will
be ambiguous, impossible, or simply mistaken. Say which and why — don't improvise a fix,
don't silently widen the scope, and don't implement something adjacent that seems close
enough. A wrong spec caught in one message costs far less than one followed to completion.

The same applies to anything the plan doesn't cover. A gap is a signal to ask, not licence
to decide.

## The loop

### 1. Attach the simulator panel first

Before building. `mcp__Claude_Code_iOS_Simulator__control` with `action: "attach"`. It
opens instantly on a booted device and errors harmlessly otherwise. Jake should be able to
watch the app come up rather than waiting for a screenshot afterwards.

### 2. Engine before UI

If the work touches recurrence, dates, or totals, that logic goes in `Core/` and gets tests
first. `Core/` must not import SwiftData. Pure functions over an injected `Calendar` — that
boundary is what makes the tests deterministic.

Write the failing test, watch it fail, then make it pass. The engine is the part where a
subtle bug is expensive and invisible.

### 3. Build, launch, look

```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Then launch and screenshot. **Verify it yourself** — don't ask Jake whether it worked when
you can look. Report what you actually see, including when it's wrong.

### 4. Iterate by editing

Once something is on screen, change it with small edits. "Row height down, section header
sticky, amount heavier" is three edits. Regenerating the view from the design again is the
failure mode this step exists to prevent.

### 5. Check the states

Before calling any screen done:

- Dark mode
- Dynamic Type at an accessibility size
- The empty state
- For timeline work: upcoming and charged, estimated and known, skipped

## Hard constraints

- **Never copy from Dime.** Patterns and reasoning only. Every line is original.
- **No raw values in views.** `Tokens.Text.amount`, never `.largeTitle`; never a literal
  hex or point size. If a token doesn't exist for what you need, add it to
  `DesignSystem/Tokens.swift` rather than inlining.
- **No `TimeInterval` date arithmetic.** `Calendar` components only.
- **Recurrence generates from the rule's anchor**, never from the previous occurrence.
  That's Dime's live drift bug; `docs/DECISIONS.md` has the detail.
- **Report real output.** Never "the build should pass". If it failed, paste what failed.
- **Don't hand-edit `.pbxproj`.** New `.swift` files are picked up automatically.
- **Watch file size.** A view file growing past a few hundred lines is a signal to split
  it. Dime's 98KB `InsightsView.swift` is the standing example of not doing this.
