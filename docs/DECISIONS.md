# Decisions

Dated log of what was decided, what was rejected, and why each rejected option lost. The
rejections matter as much as the choices — they're what stops the same debate recurring in
three months.

Format: one entry per decision. Newest at the top.

An entry that has been overtaken says so directly beneath its date — **Superseded entirely**,
**Superseded in part**, or **Qualified**. Nothing is ever deleted or edited away, so that
marker is the only way to tell, at the entry itself, whether what you are reading still binds.
Where a supersession is partial, the marker names which half survived.

---

## The return pill appears a third of a screen away, not a screenful

**Decided:** 2026-09-09 · **From:** timeline usability pass

**Chosen:** the pill showing the way back to the current month appears once the reader is
240 points from the resting position, in either direction — `Tokens.Space.returnThreshold`.
About a third of a screen, so it arrives as soon as the month you are in is behind you.

**Rejected — a full viewport, which is what shipped.** `DESIGN.md` said only "away from the
current month" and never named a number, so the figure was chosen at implementation time and
overshot the working prototype's by three times. In practice it meant scrolling two whole
months into history before the way back offered itself, which reads as the control being
broken rather than as it being deliberate. The prototype had settled on 240 and was right.

**Rejected — showing it the instant the current month's header leaves the top.** The literal
reading of "away from the current month", and it flickers: a reader nudging the list around
the boundary would watch the control appear and disappear repeatedly. A threshold needs room
to be unambiguous, and a third of a screen is the smallest distance that reads as *leaving*.

**Follow-on, and it is a real one.** The distance driving this is measured against a cached
"where the current month rests", and that cache is known to drift — this file already records
it landing 702 and 493 points wrong on otherwise identical returns. At a 778-point threshold
that error mostly hid inside the tolerance. At 240 it does not: a 700-point error is three
times the threshold, so the pill can appear well away from where it should. **The threshold
is now correct and the measurement feeding it is not.** Recorded here rather than fixed in
passing, because it lives in the scroll geometry this project has already lost days to.

---

## Liquid Glass for what floats; plain paper for what pins

**Decided:** 2026-09-09 · **From:** timeline usability pass

**Chosen:** the floating "back to" pill uses the stock `.glass` button style. The pinned
month header uses an opaque ground that is the same surface as the page — paper, not glass.
`Tokens.Surface.pinned` is a colour rather than a material, and content passing beneath a
pinned header is hidden rather than tinted.

**Rejected — a material for both, which is what shipped.** `Material.bar` reads distinctly
grey against the list, and the header looked like a separate slab laid over the page rather
than part of it. The prototype had hand-rolled a near-white translucency in CSS, which is
close to what Liquid Glass now does natively — but the header is not the place for it.

**Rejected — Liquid Glass on the pinned header too.** Glass is for controls floating *above*
content; a full-bleed sticky header is not floating, and the platform's own answer there is
the scroll edge effect. Using it on both would have made the header and the pill read as the
same kind of object when only one of them is a control.

**Consequence, and it removes a known limitation.** With the pinned ground the same paper as
the page, the header can carry it *at rest* as well as pinned — drawing it unconditionally is
visually identical. That deletes the frame in which `isPinned` was briefly false after a
month opened and the header rendered with no ground at all, which is what made an opening
month flash transparent. The "pinned header lags its own background by a frame" limitation
recorded in `plans/timeline.md` goes with it: nothing conditional drives the background now.

---

## A saved place remembers the month, not the row

**Decided:** 2026-09-09 · **From:** timeline
**Qualifies:** "The timeline never resets your position" (2026-09-07). That entry stands;
this narrows what "the scroll position you left it at" delivers in v1.

**Chosen:** leaving and returning puts you back in the month you were reading, at the top of
it. If you were partway down that month, you lose that much. Everything else in that entry
holds — you are not thrown to the current month, the month you were in is still the month you
come back to, and where you land is never decided by how long you were away or whether the
process survived.

**Why this is a decision and not a bug left in.** The list keeps a month's name pinned to the
top of the screen while you read it, and a pinned header reports its position as zero for as
long as it is pinned, however far into the month you have gone. So the app can see which month
you are in but not where in it. That much can be fixed by measuring the month's body instead of
its name, and it was — the measurement works. What cannot currently be done is *acting* on it:
the call that scrolls to a month can place it at the top of the screen or below, never above,
and "you were partway into this month" is the above case. Point-based scrolling, which has no
such limit, blanked the list outright on this view — see Step 9 of `docs/plans/timeline.md` for
what was measured.

So the error is bounded and always in the same direction: right month, top of it. A reader who
was three rows down loses three rows. A reader who was at a month boundary — which is where the
unlock and the return control both leave you — loses nothing.

**Rejected — anchor on a month boundary that is on screen,** so the offset saved is always a
position the scroll call can reach. It is the right shape, and it needs a fallback for a month
taller than the screen, where no boundary is visible. With a realistic set of recurring
expenses most months are taller than the screen, so the fallback would be the common path and
the fix would mostly not be running. Worth revisiting when the position can be reached
directly.

**Rejected — hold the timeline until this works properly.** Three sessions had gone into it,
the remaining gap is a few rows in one direction, and the alternative is a finished feature
nobody can use. Shipping the limitation and naming it is the smaller cost.

**Revisit when** the two scroll coordinate systems on this view are understood — the plan
records the specific measurement to start from. Until then, treat "at the scroll position you
left it at" as "in the month you left, at its top".

---

## The timeline is one list you scroll, bounded at both ends

**Decided:** 2026-09-08 · **From:** timeline
**Supersedes:** "The current month is home; its neighbours are collapsed bars"
(2026-09-07), in its collapsed-bar half. Future above and past below is unchanged, and
so is the current month being where you land.

**Chosen:** the next month is always expanded, so you reach it by scrolling rather than
by opening anything. Below the current month, history runs continuously — months arrive
as you scroll, with no bar to tap — down to a floor. There are no collapsed month bars
in either direction. The list rests flush on the current month.

**Why the bars went:** they made ordinary movement into a sequence of decisions. Reaching
next month meant tapping it, which expanded a screenful above and put the reader somewhere
they had not asked to be. Going two or three months out and then wanting to come back meant
loading each month again on the way down. The bar was buying "what is coming next month, in
46 points" and charging for it with every other movement on the screen.

**This reverses "Rejected — one uninterrupted list, months arriving indefinitely as you
scroll" (2026-09-07), and the reason it lost no longer applies.** That rejection said an
unbounded list makes "the current month" true only at the instant you open the app. This
list is bounded at both ends — one month ahead, and the oldest charge behind — and a
control returns you to the current month from anywhere. Indefinite was the problem, not
continuous.

**Rejected — keep the bars and make them nicer.** The clunkiness is not in how the bar
looks. It is in there being a decision at all where the reader expected a scroll.

**Rejected — resting so the next month peeks into view.** Drawn, and it has a real
argument: the next month's header carries its name and total, which is exactly what the
collapsed bar was for, delivered free and without the bar. It lost on focus — the current
month is what the screen is about, and starting with two month names on it dilutes that.
The affordance it was buying is not needed: scrolling up is not a gesture anyone has to
be taught.

---

## Looking further ahead is a deliberate unlock, and it puts itself away

**Decided:** 2026-09-08 · **From:** timeline
**Supersedes:** "An opened month closes by cap, not by scrolling" (2026-09-07), entirely.

**Chosen:** at the top of the list sits a bar for the month after next. Tapping it opens
that month; the bar then offers the one after. Unlocked months close on their own once
the reader returns to the current month. Nothing accumulates, and there is no control to
tidy anything away.

**Why v1 stops at one month by default:** the further out you look, the more the months
are the same month. Deep future navigation is the calendar view's job in v1.1, and the
timeline is better for not trying to be it.

**Why a scroll-based close is legitimate now, having been rejected three weeks of work
ago.** The cap decision killed it on arithmetic: pushing an opened month off the top
needed a screenful below it, and below it sat one month and a 48-point bar — 798 points
against a 783-point screen. Under this structure, below an unlocked month sit next month,
the current month, and the whole of history. The trigger is reachable many times over.
The arithmetic changed because the structure did.

**The second fault in that entry is still real, and the fix is a latch.** A month opens
*above* the reader, outside the viewport, so any trigger phrased as "it is no longer
visible" fires in the frame it opens in — which was watched happening. This trigger
requires the reader to have travelled up into the unlocked month first, and only then
fires on the way back. It cannot close on open.

**Rejected — a hard wall with no way past it.** Honest and cheap, and it makes the app
unable to answer a question people genuinely have two months out.

**Rejected — pull past the top to unlock.** No furniture at rest, which is its whole
appeal. It hides the one thing on this screen that is not discoverable by scrolling, and
it is invisible to VoiceOver and Switch Control.

**Rejected — a "hide" control for months you opened.** Considered before the automatic
close was found. It is an ongoing obligation — the app leaving a mess and asking the
reader to clear it — which is what tenet 1 exists to prevent.

**Rejected — let unlocked months accumulate.** Bounded by nothing. The same fault the
cap decision was written to prevent, and the automatic close prevents it without a cap.

---

## History begins at the oldest charge you have entered

**Decided:** 2026-09-08 · **From:** timeline
**Supersedes:** the €0 collapsed bar below the current month, which was never decided —
it was a consequence of the engine generating nothing before an anchor.

**Chosen:** the list runs down to the oldest occurrence the app can generate, and stops.
Below it, one line: `Nothing before March.` A month between there and today that holds
nothing is **not listed at all** — the list simply skips it. No month anywhere renders a
€0 total for a month the app knows nothing about.

**What makes this safe is how expenses are entered, and it is worth stating as a rule
rather than leaving implicit.** A recurring expense is entered forward — you set it up
for its next occurrence, not for when it historically began. So anchors sit at or after
the point someone starts using the app, and "the oldest charge" is normally days or weeks
back, not years. Backdating is possible and occasionally deliberate; it is not the shape
of ordinary use.

**Rejected — start history at the date the app was installed.** The obvious answer, and
it fails the case that motivates backdating at all: someone who deliberately enters a
renewal date from earlier in the year would never see it. It also requires storing an
install date, which is a new persisted value and a migration, bought in exchange for
hiding data the user typed in on purpose.

**Rejected — list empty months with a €0 total.** Arithmetically true and substantively
false: the app has no idea what that month cost, only that no rule it holds reached it.
Stating €0 is a claim, and it is the same class of error as saying a bill was *paid* —
see tenet 1.

**Rejected — a collapsed bar below the current month reading €0.** Where this started.
It defeated the one thing justifying the bar: saying something useful without being
opened.

**Consequence for the sample data.** `SampleData.swift` anchors the annual insurance
three years back so that an annual rule recurs into view at all. That is not how anyone
enters a bill, and it is the single input that turns this decision's two empty months
into twenty-seven. The seed changes with this work.

---

## The app fills the top inset; the system draws over it

**Decided:** 2026-09-08 · **From:** timeline
**Supersedes:** "The system owns the top" in `DESIGN.md`, which told mockups to leave the
inset unpainted and was silent on what the running app puts there.

**Chosen:** the area behind the clock and the Dynamic Island carries the app's own
background, opaque, full width. Content scrolls under it and is hidden by it.

**Why anything is needed:** with a scroll view extending under the inset and nothing
covering it, rows render behind the clock on every scroll. It is not only rows — a month
header pins to the bottom edge of its own section as that section exits, so during every
hand-off a second month name sits in the inset directly above the pinned one. Whatever
fills the inset has to be opaque enough to hide a header.

**Rejected — iOS 26's scroll edge effect.** The obvious one-line answer. Tried in both
styles on the real screen and it had no visible effect.

**Rejected — a progressive blur, and a plain scrim.** The iOS 26 idiom, built properly in
the prototype and tuned twice. Both leak in the lower third of the inset, which is where
the outgoing header sits — so content stays legible *above* the pinned header, and reads
as broken ordering rather than as depth. The inset is 59 points; a ramp has nowhere to go.

**Rejected — the same translucent material the pinned header uses.** The consistent
answer, and a reasonable one: rows visibly pass under it, which is what the header already
does. Deferred rather than beaten — it is a surface treatment, changeable in one token
when the design pass happens, and solid is the cleaner starting point.

---

## A control returns you to the current month

**Decided:** 2026-09-08 · **From:** timeline

**Chosen:** a floating pill appears once the reader is away from the current month,
naming it and pointing the way — `↑ September` from below, `↓ September` from above.
Tapping it returns them, and closes any unlocked future months on the way.

**Why it is in v1 rather than after it:** it is what makes an unbounded-feeling list
safe. Downward travel used to be gated by tapping bars; it is now free scrolling through
however many months of history exist. The further someone can get, the more they need the
way back, and the two changes arrived together.

**Consequence, found in the prototype:** the pill floats over the list, so the list needs
a bottom inset of roughly the pill's height plus its margin. Without it the last line of
history sits underneath the control.

**Rejected — leaving it to v1.1 with the calendar view.** Where it was originally put.
The calendar view is a way to *go* somewhere; this is the way back, and it became load-
bearing the moment the bars came out.

---

## Prototypes and canvases are kept, and carry the date that settles a conflict

**Decided:** 2026-09-07 · **From:** `tilly-explore`
**Supersedes:** "A motion question gets a prototype, not another artboard", decided earlier
the same day, in its retention half only — specifically the rejection of "keep prototypes in
the repo as reference". Everything else in that entry stands.

**Chosen:** a prototype is committed to `docs/prototypes/<slug>.html` and kept. The canvas is
kept too, and a rejected direction stays drawn on it rather than being deleted. Both open
with a date, the questions they were built to settle, which direction won, and one line
naming the tiebreaker: *where this disagrees with `DECISIONS.md`, the decisions log wins.*

**Why the throwaway rule lost:** it was written to prevent a stale artifact being mistaken
for a spec, and it prevented that by destroying the only record of *how* a decision was
reached. `DECISIONS.md` can state that the scroll-based close trigger was rejected; it cannot
let anyone feel a month failing to close. Six months on, that difference is most of what a
new reader needs, and the rejections in this file are only half the picture without it.

The same argument was already accepted for the canvas — settled directions stay visible
precisely so a decision is not relitigated — and there was no reason for prototypes to be
governed by the opposite rule.

**The staleness risk was real and is handled differently.** A prototype runs, so it looks
more authoritative than a canvas, and this project has already had `tilly-plan` warn an
implementer about an approved-looking artboard that was wrong. Deletion is one answer to
that; a named tiebreaker inside the file is a better one, because it survives being found by
someone who has not read this file.

**Rejected — keep them untracked, on disk only.** The middle position, and the worst of the
three: kept for whoever happens to have that machine, absent for anyone else, and invisible
to `git log`.

**Consequence:** `tilly-explore`'s bring-into-line step changes from pruning to marking.
A rejected artboard is retitled and its annotation says why it lost; an artboard that turned
out to draw something impossible is annotated as superseded and kept. `CLAUDE.md`'s docs
contract gains the prototypes row.

---

## The month header carries what is left, and says so

**Decided:** 2026-09-07 · **From:** timeline
**Supersedes:** "Month headers carry the month's total" (2026-09-07), in its
current-month half. Collapsed bars and past and future months are unchanged.

**Chosen:** the current month's header reads `−€162 left`. Every other month — past,
future, and every collapsed bar — carries its plain total with no qualifier. When the
current month runs out, the sentence finishes: `€0 left`.

**What reframes this:** remaining and total differ in exactly one month. A future month has
nothing charged, so they coincide. A past month has nothing left, so remaining is zero. The
question was never "should headers show remaining"; it was what the *current* month says,
everywhere else being moot or degenerate.

**Why the word earns its place,** on a screen whose copy rule is to delete labels that
restate their control: without it the same slot silently means two things, and a past
month's total then reads as money still owed. That is not ambiguity, it is a figure that
looks wrong — an amount on a month you know is finished reads as an app that failed to
update. Tenet 3's test is whether removing the label leaves anything genuinely unclear.
Here it does.

**What it buys beyond the figure.** Once the header pins, the current month's remaining
amount is permanently on screen — which is the roadmapped headline number, delivered on the
month it describes instead of in a box above the content. `ROADMAP.md`'s v1 headline item is
deleted into this one.

**Rejected — the figure follows the tense and says nothing** (drawn as direction A). One
figure, no label, no second number, and it has the best property of the three: `−€162` is
the sum of the rows still sitting back, checkable on screen without scrolling. It lost
because a silent switch does not read as ambiguous, it reads as a miscalculation.

**Rejected — `−€162 of €1,521`** (direction B, second treatment). The most accurate and the
most heavy-handed: it prints a second number that is redundant in every month but one, and
on a collapsed bar it replaces one figure read at a glance with two.

**Rejected — the header keeps the total, and remaining moves to the upcoming/charged
boundary** (direction C). Drawn because it leaves this log and the roadmap untouched and
makes the past-month problem not exist rather than handled. It lost in motion: scroll past
the boundary and the figure is gone, which is the exact thing pinning the header was meant
to fix.

**Rejected — an `all paid` badge on finished months.** Proposed, and wrong on the word
before the placement: Tilly never knows a bill was paid, only that its date passed, which is
why `DESIGN.md` says *charged* throughout. A badge claiming payment is one step from a
control asking you to confirm it, and tenet 1 exists to prevent that. On past months it also
fails tenet 3 — August being over is not news — and it would put furniture on every month in
history.

**Rejected — tap the header to reveal the total.** An undiscoverable control, and it is
already roadmapped as a visible setting.

**Rejected — `−€162 left this month`.** The header says "September" two inches to the left.

---

## An opened month closes by cap, not by scrolling

**Decided:** 2026-09-07 · **From:** timeline
**Superseded entirely by** "Looking further ahead is a deliberate unlock, and it puts itself
away" (2026-09-08). Kept for the reasoning; nothing here still binds.
**Supersedes:** "The current month is home; its neighbours are collapsed bars"
(2026-09-07), in one sentence only — "opening a month and scrolling back closes it again,
returning to exactly the bar you opened". Everything else in that entry stands.

**Chosen:** at most two months are expanded at once. Opening a third collapses the far end —
the opposite end from where the reader is looking, off screen. Nothing closes because of
where you scrolled.

**Why the scroll trigger went:** it cannot fire. Pushing an opened month entirely off the
top requires everything below it to fill the screen, and below it there is one month plus a
48-point bar. Measured in the prototype at eleven recurring expenses: 798 points against a
783-point screen, leaving the opened month's bottom edge 30 points on screen at maximum
scroll, permanently. A month you opened could never be got rid of, and months would
accumulate into the single uninterrupted list this log already rejected.

This is arithmetic, not a badly chosen threshold, and it is why no second trigger was
adopted instead.

**Rejected — close on the hand-off,** when the next month's header reaches the top. Proposed
and tested; it fails the same arithmetic, and it has a second fault that is worse. Opening a
month deliberately places it *outside* the viewport so nothing under the reader's eyes
moves — so under this trigger a month becomes eligible to close the instant it opens. It was
watched opening and shutting itself in the same frame.

**Rejected — a screen-height spacer below the last bar,** which would make both scroll
triggers reachable. It buys the geometry by letting the reader scroll into blank space past
the end of history, and it makes a behaviour depend on a measurement that has to stay true.

**Rejected — let opened months accumulate.** The plan's own stated fallback. Bounded by
nothing, and over a few sessions it becomes the rejected list.

**Consequence for the anchor, and it inverts what the plan specified.** The plan said to pin
the scroll position to the top-most visible item. That is the wrong anchor: at rest the
top-most item is the collapsed bar about to be opened, so preserving its position expands it
downward and shoves the month being read off the screen. The anchor must be the month under
the *middle* of the viewport — the one actually being read — and it must follow that month
across a collapse into a bar. Anchoring on total content height is also wrong, because one
gesture can add a month at one end and drop one at the other, and the two deltas cancel.

---

## A motion question gets a prototype, not another artboard

**Decided:** 2026-09-07 · **From:** `tilly-explore`
**Superseded in part by** "Prototypes and canvases are kept, and carry the date that settles a
conflict" (2026-09-07), in its retention half only. When a prototype is warranted still binds.

**Chosen:** `tilly-explore` gains a third, conditional rung. When what is being decided is
what happens *over time* — pinning, hand-offs, a gesture that opens something and a scroll
that closes it again — the exploration builds one self-contained HTML prototype: no
libraries, no build, opens by double-clicking, variants on controls rather than in separate
files. It is untracked and thrown away when the decision lands.

**Why:** the timeline's month header was explored as six artboards including a four-frame
scroll sequence, and Jake's response was that it was hard to grasp without motion. That is
not a failure of the drawing. Three frames of a sequence are three still images of a thing
whose entire nature is that it moves, and adding a fourth frame does not converge on
anything.

The prototype cost about twenty minutes and immediately produced a fact that the brief, the
canvas and the written plan had all missed: **a month of eleven recurring expenses is 802
points against a 783-point viewport.** Nineteen points of scroll. The header therefore never
meaningfully pins at rest, and — worse — an opened neighbour month can never scroll far
enough out of view to trigger the close-on-scroll-back behaviour, so a month you open stays
open. At eighteen expenses there are 383 points of scroll and both behaviours work. The
design has a density threshold in it, and nothing static was ever going to show that.

**The controls are the rung's real value,** and worth stating separately from the motion.
Two sliders — where "today" falls in the month, and how many things recur — let Jake find
the boundary himself rather than be shown one point on one side of it. A prototype without
a control for the quantity the design turns on is just an animated artboard.

**Rejected — draw more frames.** The thing already tried. A sequence drawn as stills asks
the reader to animate it in their head, which is precisely the work they cannot do reliably;
it is the reason the rung exists.

**Rejected — prototype instead of the canvas.** The canvas settles type, spacing, colour,
hierarchy and the awkward content cases, and does all of it faster than a prototype would.
A prototype is a bad place to argue about a 13-point date line. The rungs answer different
questions and the prototype is the narrowest of the three.

**Rejected — keep prototypes in the repo as reference.** A prototype goes stale exactly the
way the timeline's canvas did, and it looks more authoritative than a canvas because it
runs. What survives a decision is the entry in this file.

**Consequence:** the prototype must state on the page itself what it cannot reproduce —
rubber-band overscroll, Liquid Glass, Dynamic Type, iOS momentum. A prototype mistaken for
a promise about feel is worse than no prototype.

---

## Exploration wireframes before it draws

**Decided:** 2026-09-07 · **From:** `tilly-explore`
**Supersedes:** "Exploration draws variants on the canvas, not as wireframes first",
decided earlier the same day

**Chosen:** the wireframe rung comes back. `tilly-explore` emits two or three ASCII
wireframes under a shared 500-token budget, stops for a choice, and only then builds a
canvas — for the chosen direction, plus at most one contender if a side-by-side is asked
for.

**Why the canvas-only version lost:** its premise was that a second direction costs an
artboard rather than a second canvas, so drawing them all is nearly free. It isn't.
Artboards at a real type scale with real content across every state are the most expensive
output this workflow produces, and drawing every direction at that fidelity spends the
budget before the cheap question has been answered. That question — which *shape* is right —
is one a wireframe answers badly at colour and type and well at layout, hierarchy, ordering
and density, which is the only ground the directions are competing on.

The two-lines-per-direction summary that replaced the wireframes was cheap, but it made the
argument in prose. Describing a layout is the one register worse than drawing it in boxes.

**Kept from the version being superseded.** The canvas rung keeps its awkward-case list, the
requirement to draw dark mode, the rule that the argument lives in the canvas's own
annotations, iteration in place on one URL, and the step that brings the canvas back into
line with this file once a decision lands. Only the question of *what gets drawn* changes.

**Rejected — draw every direction, but rough.** A deliberately low-fidelity canvas is a
wireframe that costs like a canvas. If the fidelity isn't real, the artboard has given up
the only thing it has over a wireframe.

**Rejected — decide from the wireframes and skip the canvas.** Wireframes can't settle type,
spacing or colour, and those decide whether a layout survives contact with real content.
The canvas isn't the redundant rung; it's the one the wireframe is buying time for.

**Consequence:** the requirement to draw an accessibility text size, added the same day, is
dropped. Deferred rather than rejected — the reasoning that motivated it still holds, and
it wants a cheaper home than every exploration canvas, probably a simulator check in
`tilly-ship`.

---

## Exploration draws variants on the canvas, not as wireframes first

**Decided:** 2026-09-07 · **From:** `tilly-explore`
**Superseded entirely by** "Exploration wireframes before it draws" (2026-09-07). Kept for the
reasoning; nothing here still binds.
**Supersedes:** the two-rung gate in `tilly-explore` — ASCII wireframes, then a canvas for
the winner only

**Chosen:** `tilly-explore` names two or three directions in a line or two each and then
draws all of them on one canvas. The canvas is where variants are compared and iterated,
and it is revised in place rather than replaced per pass.

**Why the wireframe rung lost:** it was there to stop three canvases being built to answer a
question one cheap artifact could settle — and the cost it was avoiding turned out not to
exist. Variants are artboards on a single canvas, so a second direction costs an artboard
rather than a second canvas. Meanwhile the rung had a real cost of its own: it settled
layout in the medium least able to show layout, and a design argument that has to be *read*
rather than *looked at* is being made in the wrong register.

The evidence is the timeline exploration, which reached a fifth pass by editing one canvas
repeatedly. That is the working mode, and the wireframe gate sat in front of it doing
nothing the canvas didn't do better.

**What was kept, because the rung was doing four jobs and only one of them was cost.** The
decision gate survives, moved to after the first canvas — Jake picks from something he can
see. The requirement to name which tenet each direction serves and strains survives, and
now lives in the canvas annotations beside the artboard it judges. The cap on how many
directions get drawn survives at two or three, because the constraint is what makes each one
an argument rather than a permutation.

**Rejected — keep the wireframes as an optional first rung.** Optional gates are not gates;
in practice they are skipped when the render feels imaginable, which is precisely when the
render turns out to disagree.

**Rejected — drop the pre-drawing description entirely and go straight to `/design`.** The
two lines per direction cost almost nothing and are what stop three artboards being three
versions of the same idea. So the skill keeps two gates rather than one: the directions are
approved before anything is drawn, and the drawn direction is chosen after. They ask
different questions — *are these worth drawing* and *which one won* — and the first is the
last point where changing course costs a sentence instead of a rebuild.

**Consequence:** `tilly-explore` also now requires dark mode and an accessibility text size
to be drawn, and requires the canvas to be brought into line with `DECISIONS.md` once a
decision lands. Both are failures this project actually hit — the timeline's accessibility
layout was wrong in a way only a render showed, and its canvas kept a `TODAY` badge that had
already been rejected, which `tilly-plan` then had to warn the implementer about.

## Time is carried by weight, not by form

**Decided:** 2026-09-07 · **From:** timeline
**Supersedes:** the state grammar hypothesis in `DESIGN.md`, written at kickoff

**Chosen:** an upcoming row sits back — name, date, icon and amount all at secondary
weight. A charged row comes forward at full weight. Certainty stays on a separate channel,
so the two never collide.

**Why this changed:** the kickoff position put temporal state on *form* — an outline dot
versus a filled one. Drawn at real size against real rows, the dot column turned out to be
informative for about four rows either side of the boundary and then to become a column of
identical filled dots for the whole of history, where every row is charged. It was paying a
permanent column for a local distinction.

The trap the original section named is real and both approaches survive it: an estimate
that has already been charged must not read as upcoming. What the hypothesis got wrong was
assuming the fix had to be *form*. Keeping the two axes on separate channels is the actual
requirement, and weight-plus-mark satisfies it without a new column.

**Rejected — outline versus filled dot** (the kickoff position). Works, and costs a column
that stops carrying information as soon as you scroll away from today.

**Rejected — lightness for both axes.** The original trap. An estimated past charge reads
as upcoming, which is exactly backwards.

---

## Estimates are marked, not approximated

**Decided:** 2026-09-07 · **From:** timeline

**Chosen:** an estimated amount carries an `EST` mark beside it. A month total containing
an estimate carries the same mark.

**Why:** a tilde is a quiet typographic hedge, and an estimate is not a hedge — it is a
claim the app is making about money that has not moved yet. It should look like one. The
mark also survives being small, which a tilde beside a large tabular figure does not.

**Rejected — a tilde prefix on the number.** Cheaper and quieter, and too quiet: at
13-point secondary weight it disappears, which is precisely when the reader most needs to
know the figure is soft.

**Open, and not this screen's problem:** where an estimated amount comes from. Nothing in
the engine predicts anything, and a variable bill can double between seasons, so the
realistic meaning of `EST` in v1 is "you entered roughly, and you will correct it when the
bill lands". That belongs to the editor and the overrides UI.

---

## A day is grouped only when it holds more than one charge

**Decided:** 2026-09-07 · **From:** timeline

**Chosen:** one charge on a day is an ordinary row carrying its own date beneath the name.
Two or more collapse under a single day heading with a day total, and the rows inside drop
their individual dates.

**Why:** a day total is real information when a day holds several charges and pure
repetition when it holds one. Grouping every day would restate each amount as its own
total, down the whole list. Because grouped rows give up their date line, the heading is
close to free — a grouped day costs almost nothing over the plain rows it replaces.

**Rejected — group every day** (the competitor's and Dime's past view). Consistent, and
consistently redundant on the majority of days, which hold exactly one charge.

**Rejected — a tinted card around the group.** Tried and drawn. Two problems: the card's
padding pushed the amounts inward, so grouped amounts stopped aligning with ungrouped ones
down the right edge; and the fill made an upcoming group visually heavier than a charged
row beneath it, which put a container in competition with the channel carrying time.

---

## Rules exist to close a group, and for nothing else

**Decided:** 2026-09-07 · **From:** timeline

**Chosen:** no separator between rows. A hairline appears above and below a grouped day
and nowhere else, so seeing one means those rows share a day and that total belongs to
them. Collapsed month bars keep a hairline for the same reason.

**Why:** a separator under every row is furniture — present regardless of what the row is,
and therefore saying nothing. Removing it left space to do the separating, which is quieter
and cheaper, and it gave the surviving rules a job.

**Rejected — a separator under every row.** The default list treatment, and what made the
screen feel busy in the first place.

---

## The current month is home; its neighbours are collapsed bars

**Decided:** 2026-09-07 · **From:** timeline
**Superseded in part.** The collapsed-bar half is replaced by "The timeline is one list you
scroll, bounded at both ends" (2026-09-08); the close-on-scroll sentence by "An opened month
closes by cap" (2026-09-07), itself since replaced. Future above and past below still binds.
**Supersedes:** "Timeline runs future-above, past-below, resting on the last actual charge"
(2026-09-04), in its resting-position half. Future above and past below is unchanged.

**Chosen:** the timeline shows one month expanded. Scrolling up runs out at the top of that
month rather than sliding into the next one; the next month sits above as a slim bar
carrying its own name and total, and pulling opens it. The month below behaves the same
way. Opening a month and scrolling back closes it again, returning to exactly the bar you
opened.

**Why the resting position changed:** the kickoff decision put the most recent actual
charge at the resting anchor, which required placing it deliberately about two thirds down.
Drawn against a realistic set of expenses, a month is close to one screenful, so landing at
the top of the current month puts the boundary at roughly that height on its own. A property
that emerges is better than one that has to be engineered, and it removes a magic number.

**Why the bar earns its place:** it answers "what is coming next month" without opening
anything, permanently, in 46 points.

**Rejected — one uninterrupted list, months arriving indefinitely as you scroll.** This is
what the brief specified and what the first exploration drew. It makes "the current month"
true only at the instant you open the app; one scroll and you are simply somewhere in time.

**Rejected — a fixed header showing what is next.** Guarantees the next charge is always
visible, and does it with a permanent box above the content — structurally the competitor's
home screen, and it prints the next charge twice.

**Consequence — crossing midnight into a new month.** Home moves while you are not looking.
The screen does what pulling the bar would have done: the new month opens *above* you, in
space you were not occupying, and nothing under your eyes moves. Two visible side effects
come with it and are correct: the boundary between upcoming and charged moves into the new
month, and anything still upcoming in the old one becomes charged.

---

## The timeline never resets your position

**Decided:** 2026-09-07 · **From:** timeline
**Qualified by** "A saved place remembers the month, not the row" (2026-09-09). This entry
stands; the newer one narrows what it delivers in v1.

**Chosen:** you return to the month you left, opened the way you left it, at the scroll
position you left it at — however long you were gone and whether or not the process
survived. The current month decides where you land exactly once, on the first run after
installing.

**Why:** iOS gives no reliable line between "switched away" and "launched fresh" — a
backgrounded app that gets killed reopens cold. Any rule that treats those differently is
therefore unpredictable in practice, and unpredictability is the failure itself rather than
a risk of it. Being thrown back to the top for reasons you cannot see is the specific thing
that makes a tool feel unreliable.

**Rejected — return to the current month on launch.** Keeps "home" literally true at all
times, and pays for it by discarding your place at a moment you cannot anticipate.

**Rejected — remember for the session, reset on next launch.** Sounds like a compromise and
is the worst of the three, because "next launch" is not a thing the user can observe.

---

## Nothing marks the boundary between upcoming and charged

**Decided:** 2026-09-07 · **From:** timeline

**Chosen:** no divider, no badge. The last row at secondary weight and the first at full
weight are the boundary.

**Why:** the state grammar already draws this line the length of the list. Anything added on
top is a second statement of something the reader has already been told.

**Rejected — a full-width dated divider.** Drawn first. It reads as a heavier structural
break than the months themselves, which is the wrong ranking.

**Rejected — a `TODAY` badge on the first charged row.** Better, and it lies most days: the
most recent charge is usually not today, so the badge ends up on a row dated some days ago.

**Rejected — a `TODAY` badge only when a charge falls today.** Truthful, and it appears and
disappears for reasons that are nothing to do with the reader.

---

## A moved occurrence leaves no trace at its original date

**Decided:** 2026-09-07 · **From:** timeline
**Settles:** open question 1 in the timeline brief

**Chosen:** a moved occurrence appears at its new date and nowhere else, with no note
explaining where it came from. This matches what the engine already reports.

**Why:** if a bill moved, it moved. A line reading "moved from the 1st" is metadata about an
edit rather than information about money, and the timeline is not an audit log. The genuinely
important question — whether an edit changes this occurrence or the whole series — is a
question the editor must ask at the moment of editing, not one the timeline can answer
afterwards.

**Rejected — a ghost row at the original date.** Explains the move, and does it by adding a
row for something that is not happening.

**Rejected — a secondary line at the new date.** Drawn, and cut. Cheaper than a ghost row and
still an explanation nobody asked for.

---

## Month headers carry the month's total

**Decided:** 2026-09-07 · **From:** timeline
**Superseded in part by** "The month header carries what is left, and says so" (2026-09-07),
in its current-month half only. Collapsed bars, past and future months still bind.
**Settles:** open question 5 in the timeline brief

**Chosen:** an expanded month header and a collapsed month bar both carry that month's
total, excluding skipped occurrences. A month containing an estimate marks its total `EST`.

**Why:** it draws the boundary against the roadmapped headline number cleanly, because they
are different quantities. A month header totals the whole month; the headline is "remaining
this month". Neither makes the other redundant.

**Rejected — no total in the header.** Quieter, and it leaves the collapsed month bar with
nothing to say beyond a name, which is most of what makes the bar worth its space.

---

## Every amount carries a minus sign

**Decided:** 2026-09-07 · **From:** timeline

**Chosen:** row amounts, day totals and month totals are all written as negative.

**Why:** it is not distinguishing anything — nothing on this screen is money arriving — but
it sets the register, the way a statement does. Rejected once as a label restating its own
context, and that was wrong: a label names a thing, a sign tells you which direction the
number runs.

**Rejected — unsigned amounts.** Defensible on the grounds that the whole screen is
outgoing, and it reads as a list of prices rather than a list of withdrawals.

---

## The timeline row reserves a leading slot for a category icon

**Decided:** 2026-09-07 · **From:** timeline

**Chosen:** every row leads with a fixed-size icon slot, and the occurrence's date moves
beneath the name. Colour is deferred; the slot and its position are settled now.

**Why:** an icon distinguishes categories without a text label, which is tenet 3 applied to
the thing categories are actually for. The alternative in use elsewhere is a category name as
a second line under the expense name — a label doing work an icon does faster.

**Rejected — a day-number column at the leading edge.** What the first exploration drew. It
works, and it spends the most valuable position in the row on something the month header and
the row's own date already carry.

**Consequence:** categories are still out of scope and still ship empty. Any icon in a
mockup is illustrative of the slot, not a proposed starter set — a rendered set of default
categories is exactly how tenet 4 gets broken by accident.

---

## The look-ahead slot is not reserved

**Decided:** 2026-09-07 · **From:** timeline
**Settles:** open question 3 in the timeline brief

**Chosen:** v1 reserves no space for the v1.1 look-ahead nudge.

**Why:** the collapsed month bar already answers "is something big coming" — it carries the
next month's total, permanently, without being opened. Most of what the slot was for is
therefore delivered. Reserving space on top of that means an empty box above the content
through the whole of v1, which is the specific failure `INSPIRATION.md` records.

**Rejected — a reserved region under the month header.** Drawn, and it looked exactly like
what it was: a box above the content, holding nothing.

---

## The timeline introduces spacing and dimension tokens

**Decided:** 2026-09-07 · **From:** timeline

**Chosen:** `Tokens` gains spacing, row-height, icon-size and corner-radius values, defined
by the timeline as the first screen that needs them, and used from the first view rather
than extracted later.

**Why:** the timeline's design turns on dimensions — row rhythm, the gap that replaced the
separators, the icon slot, the height of a collapsed month bar. Those are design decisions,
not incidental numbers, and `DESIGN.md` already records why bare layout numbers are the
seam's blind spot: a raw `.padding(8)` does not look wrong the way a hex literal does, so it
escapes review. Introducing the scale with the first screen that needs it is cheaper than
retrofitting it across several.

**Rejected — raw values now, extract a scale later.** Same argument the kickoff token
decision already rejected for fonts and colours, and it lost for the same reason: the
extraction is the expensive part.

**Rejected — design the full scale up front.** More than one screen's worth of guessing.
The timeline defines what the timeline needs; later screens extend it.

---

## The project file is authored by hand, once

**Decided:** 2026-09-06 · **From:** `docs/plans/app-scaffolding.md`

**Chosen:** `Tilly.xcodeproj/project.pbxproj` is written by hand, a single time, using
`PBXFileSystemSynchronizedRootGroup` for both targets — so the file holds no per-file
references at all and does not grow as the app does. The invariant this actually protects
turned out narrower than "don't touch it again":

> Adding, moving, or removing source files must never touch the project file.

Build settings are what a project file is *for* — fixing one that's wrong, or adding one
that's missing, is ordinary work, not a breach of "authored once".

**Why:** `CLAUDE.md` said "don't hand-edit `.pbxproj`", written so routine file additions
would never require project-file surgery. Authoring the project once, correctly, with
synchronized groups is precisely what makes that true forever after — but the rule as first
written didn't say so, and a later session stopped mid-build, unsure whether it was even
allowed to fix a build setting that turned out to be wrong (a missing launch-screen key was
scaling the whole app into a letterboxed compatibility mode). Two probes, built and run in a
scratch directory before the plan was finished, confirmed synchronized groups hold: a new
`.swift` file in a newly created nested directory compiled into both targets with the
`.pbxproj` byte-identical before and after.

**Rejected — create it in Xcode's GUI.** Guaranteed-canonical, but costs a wizard run that
can't be specified or verified in advance, and the template emits extras (asset catalog,
sample content, sometimes an XCTest target) that then need removing. The probe removed the
only real argument for it, which was risk.

**Rejected — XcodeGen or Tuist.** Neither was installed, both are third-party build tooling
in a project whose stated point is learning iOS properly, and both introduce a second source
of truth — a `project.yml` that has to stay in step with the thing it generates.

**Consequence:** `CLAUDE.md`'s hard rule is corrected to the narrower invariant above. A
session that finds a wrong build setting should fix it directly rather than treating the
project file as frozen; a session adding, moving or removing files should never need to
touch it at all.

---

## A test may be edited when a step exists to change what it asserts

**Decided:** 2026-09-06 · **From:** the recurrence engine review

**Chosen:** a plan step may edit an existing test when that test asserts precisely the
behaviour the step exists to replace. The bar is that the test's *intent* survives the edit
untouched — only the setup that pinned the old semantics moves. Any other reason to edit a
test to make it pass is the signal to stop and report, as the plans' escape hatch says.

**Why:** two step specs on the first plan turned out to be wrong, in two different sessions.
The first was a factual error caught by `tilly-build`. The second was a rule written into the
plan by `tilly-plan` — "if any existing test needs editing to stay green, something is wrong,
stop" — which then fired on a step deliberately changing occurrence-windowing semantics. Two
tests were asserting the old behaviour, correctly, having been written before the change was
decided. Under the rule as written the only options were to stop permanently or to ignore the
rule, and neither is right.

**Rejected — keep the absolute rule.** Its appeal is that it can't be rationalised around,
which is exactly what an escape hatch needs. But it makes any step that changes existing
behaviour unexecutable, and a rule that has to be broken to make progress trains the habit of
breaking it.

**Rejected — drop the rule and let the executor use judgement.** Editing tests until they
pass is the single most effective way to convert a red suite into a false green. The
constraint has to stay; it just needs the one legitimate exception named, so that using it is
a deliberate act rather than a rationalisation.

**Consequence:** a step that intends to change existing behaviour should say so and name the
tests it expects to touch. When it doesn't and a test still fails, that remains a stop.

---

## The occurrence window means effective dates

**Decided:** 2026-09-06 · **From:** recurrence engine review

**Chosen:** `occurrences(for:overrides:in:calendar:)` returns every occurrence whose
*effective* date falls in the range — pulling in ones scheduled outside it but moved into
it, and dropping ones scheduled inside it but moved out. `dates(for:in:calendar:)` keeps
windowing on scheduled dates, because a rule on its own has no other date to offer. The two
functions answer different questions: what the rule says, and what actually happens.

Range bounds are compared at day granularity, so "falls in the range" is unambiguous:
both ends inclusive, a bound's time-of-day ignored. A caller passing "now" as the start
gets today's occurrence rather than losing it to the clock.

**Why:** the first implementation windowed on scheduled dates and applied overrides
afterwards, so the range meant one thing and the sort meant another. A bill anchored on 31
January and moved to 2 February disappeared from a February query and surfaced in a January
one, dated 2 February. The timeline is sectioned by date and rests on the most recent actual
charge, so a moved bill would have gone missing from the month it is actually in and
appeared under a month it isn't. Paging month by month compounds it: the same payment read
under the wrong heading, and the correct month silently short.

No padding constant is needed, which is what makes this cheap. An override names the
occurrence it moves, so the set that can enter a window is exactly the overrides whose
`movedDate` lands inside it — and their `scheduledDate`s are known exactly, not guessed.
Each is checked against the rule before being admitted, so a stray override can't conjure an
occurrence that the rule never generated.

**Rejected — keep scheduled-date windowing and document it.** Cheapest change, and it moves
the correction to every call site: timeline, headline number, month total, insights, each
re-deriving the same widening and each able to get it wrong quietly. A question with one
right answer belongs in one place.

**Rejected — a `filterBy: .scheduled | .effective` parameter.** A knob with one correct
setting. Every real caller wants effective dates; the only plausible scheduled-date reader
is the editor previewing what a rule does, which reads a rule with no overrides at all, so
the distinction doesn't arise there.

**Rejected — pad the generation window by a fixed amount** (say a month either side). Wrong
in both directions at once: still misses a longer move, and generates waste in the
overwhelming majority of windows, which contain no moves at all. "How big should the pad be"
has no defensible answer, and that is the signal the approach is wrong rather than merely
imprecise.

**Consequence:** callers must pass every override that could bear on the window, including
ones whose `scheduledDate` lies outside it. Fetching overrides with the same date predicate
as the query would silently drop exactly the ones that move into it — the failure is
invisible, because the result still looks like a plausible month. For v1 an expense's
overrides are few; fetch them without a date filter.

**Consequence:** the engine no longer reports a moved occurrence at its original slot.
Whether the timeline shows a trace there is a design question rather than an engine one, and
`scheduledDate` is carried on every `Occurrence`, so the data is there either way.

---

## Implementation plans are a written artifact, not an implicit step

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** A fifth skill, `tilly-plan` (Opus), sits between `tilly-explore` and
`tilly-build` and writes `docs/plans/<slug>.md` — ordered steps, each with exact file paths,
exact type signatures, named test cases, a verification command, and an explicit out-of-scope
line. `tilly-build` executes one step at a time and stops when a spec is wrong.

**Why:** the chain previously ran brief → explore → build. Explore ends at an approved
*design*; build starts writing code. The decisions in between — file layout, signatures,
build order, what "done" means per piece — had no home, so they were made ad hoc during
implementation by the model with the least context and no way to ask first.

The gap was demonstrated rather than theorised: the first Phase 1 handoff was a
hand-written step spec typed directly into chat. That decomposition was the right work
happening in the wrong place — invisible, unreviewable, and thrown away after one use.

**Secondary benefit:** the plan is a review artifact. Reviewing a plan before code exists is
far cheaper than reviewing a diff.

**Rejected — richer briefs instead of separate plans.** A brief answers *what and why* and
is read by a person deciding whether to do the work. A plan answers *how* and is read by a
model executing it. Merging them makes both worse.

**Rejected — leaving implementation decisions to `tilly-build`.** This is what was already
happening. Sonnet is strong enough to make these calls, but making them in the executing
session means they're never reviewed and never recorded.

**Guardrail:** every plan ends with an escape hatch instructing the executor to stop rather
than improvise when a spec is wrong. Specs detailed enough to remove decisions are detailed
enough to be confidently wrong; without the hatch, over-specification turns a bad guess into
a faithfully executed bad guess.

---

## Core is a Swift package, not a folder in the app target

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** `Core/` is a standalone SPM package, `TillyCore`, which the app target depends
on locally. Engine tests run with `cd Core && swift test`.

Two reasons, both practical:

*Speed.* `swift test` completes in about a second against the host, with no simulator boot.
An `xcodebuild test` cycle is 30-60 seconds. Across the hundreds of red-green iterations
test-driven development actually involves, that gap decides whether TDD is sustainable.

*Enforcement.* "Core must not import SwiftData" becomes a compile error rather than a
convention someone has to remember. The package simply doesn't link it.

**Rejected — a plain folder inside the app target.** Simpler layout on paper, but every
engine test would boot a simulator, and the architectural boundary would rest on discipline
alone.

**Consequence:** the Xcode project isn't needed until UI work begins. Phase 1 runs entirely
from the command line.

---

## Occurrences are computed, never stored

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** The timeline is a pure function — `occurrences(rules, overrides, dateRange) →
[Occurrence]`. Only deviations persist, as `OccurrenceOverride` records keyed on
`(expense, scheduledDate)`.

**Rejected — materialising rows** (Dime's approach: create a real row for each occurrence
as its date passes). Two costs, both visible in Dime's source:

*Drift.* `DataController.updateRecurringTransaction()` walks forward from the previous
occurrence, not a fixed anchor:

```swift
newDate = Calendar.current.date(byAdding: .month, value: coefficient, to: holdingDate)
```

A bill anchored on the 31st goes Jan 31 → Feb 28 → Mar 28 → Apr 28 and never recovers,
because the clamped result becomes the next input.

*Sync duplication.* `LogView` must call `updateRecurringTransactions()` on appear and on
CloudKit sync-success, guarded by an `updatedRecurring` flag and a debounce, because two
devices running the pass both write rows.

Computing from a fixed anchor removes both, and makes retroactive rule edits correct for
free. It also puts the app's hardest logic in a pure function with no UI and no database —
the best possible thing to test-drive.

---

## Past charges are assumed, not confirmed

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** When an occurrence's date passes, it is charged. Rendering distinguishes
upcoming from charged; no control marks anything as paid.

**Rejected — user confirms each occurrence.** Would make the past view a true record
rather than a projection, but turns a visibility tool into a chore app. Skipped
confirmations rot the data until it can't be trusted. Directly against tenet 1.

**Rejected — auto-assume but prompt on variable bills.** Kept the chore, just rarer.
Setting the real amount stays available; it is never demanded.

---

## Categories ship empty

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** No default categories, no starter set, no first-run suggestions. The app may
hint subtly; it never imposes.

**Rejected — ship a suggested starter set** (Dime's approach). A starter set is a guess
about someone's life. The competitor's fixed, uneditable list is the same mistake taken
further, and shows where it leads. Tenet 4.

**Consequence:** the empty state carries real weight — first run is doing the teaching.

---

## Recurrence is every N units from a fixed anchor

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** interval + unit (day/week/month/year) + anchor date. Month-end clamps to the
last valid day *without sticking* — always generated from the anchor's day-of-month.

**Rejected — weekday rules** ("every second Tuesday", "last Friday of the month"). Real for
some payroll-linked costs, but a meaningfully larger engine and UI for cases that aren't
currently needed.

**Rejected — full iCalendar RRULE.** Powerful, reusable, and almost entirely unused here.
Over-engineering for v1.

---

## Timeline runs future-above, past-below, resting on the last actual charge

**Decided:** 2026-09-04 · **From:** project kickoff
**Superseded in part by** "The current month is home; its neighbours are collapsed bars"
(2026-09-07), in its resting-position half — and that entry has itself since been narrowed.
Future above and past below still binds, and is now in "The timeline is one list you scroll".

**Chosen:** Opening the app puts what's next at eye level, with the most recent real charge
as the resting anchor — so you see where you are and what's coming from there.

**Rejected — past above, future below** (bank-statement order). Conventional, but it puts
history at eye level in an app whose entire job is forward visibility.

**Rejected — today pinned mid-screen, scrolling both ways.** More novel and more to build,
and "today" is less meaningful than "the last thing that actually happened".

---

## Licence: GPL-3.0 with an App Store exception

**Decided:** 2026-09-04 · **Supersedes:** "Licence: MIT", same day

**Chosen:** GPL-3.0, plus an additional permission under section 7 for App Store
distribution. `LICENSE` holds the GPL verbatim so licence detection works;
`LICENSE-EXCEPTION.md` holds the permission.

**Why this changed:** the requirement was restated as "build in the open, let people fork
and modify, but keep the app from being copied and sold". That is a description of
copyleft. MIT gives no such protection — it permits a fork to close the source and sell it.

**What GPL actually does**, since this is commonly misread: it does *not* prohibit selling.
Anyone may charge for GPL software. What it prohibits is closed-source distribution — a
commercial fork must ship complete corresponding source under the GPL, so any buyer can
pass it on freely. That removes the commercial moat without banning commerce, and it is the
mechanism behind the protection wanted here.

**Rejected — MIT.** Zero friction, maximum freedom for others, and no protection at all.
Chosen earlier the same day on the mistaken premise that Dime's GPL created some obligation
to avoid; it doesn't, since copyright covers code rather than ideas and Tilly contains no
Dime code.

**Rejected — MPL-2.0.** File-level copyleft with no App Store friction, but too weak here:
someone can combine Tilly's files with proprietary code and ship a closed commercial app,
provided they publish changes to Tilly's files specifically.

**Rejected — non-commercial licences** (PolyForm Noncommercial, CC BY-NC). These do
literally forbid selling, but they are not open source, they block the legitimate forking
that building in public is for, and they carry field-of-use restrictions that sit badly
with the project's goals.

**Cost accepted:** the exception is only effective when granted by *every* copyright
holder. Accepting outside contributions later means re-granting it from each contributor.
Noted in `CLAUDE.md`.

---

## Licence: MIT  ·  SUPERSEDED

**Decided:** 2026-09-04 · **Superseded the same day** by the GPL-3.0 entry above.
**From:** project kickoff

**Chosen:** MIT. Anyone can use, learn from, or build on Tilly with no obligations — the
same openness that made Dime useful to this project in the first place.

**Context:** Dime's GPL-3.0 does not oblige anything here. Copyright covers code, not
ideas, and Tilly contains no Dime code. The licence was a free choice.

**Rejected — GPL-3.0 with an App Store exception.** Briefly chosen earlier the same day
and reversed. The appeal was making "free forever" structural: copyleft means nobody can
take Tilly closed-source or sell it. Three things outweighed it. GPL's terms conflict with
the restrictions app stores place on people who download software — VLC was pulled from
the App Store in 2011 over exactly this — which needs an explicit additional-permission
clause to work around. That clause is only effective when granted by *every* copyright
holder, so accepting any outside contribution later would require re-granting it by each
contributor. And copyleft restricts what other people can do with work that is meant to be
freely learned from.

**Consequence, stated plainly:** tenet 5 is now a commitment rather than a guarantee. MIT
permits someone to fork Tilly, close the source, and sell it. Nothing stops that except
the decision recorded in `PROJECT.md`, which is where it belongs.

**Follow-on:** MIT and GPL-3.0 are incompatible in one direction — GPL code cannot enter an
MIT project without relicensing everything. This makes the never-copy-Dime rule in
`CLAUDE.md` load-bearing rather than merely preferred.

---

## Stock SwiftUI in v1, behind a token layer from day one

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** V1 uses system components. `DesignSystem/Tokens.swift` exists immediately but
initially just aliases system values; views reference tokens, never raw values.

**Rejected — build a design system in v1.** Functionality first. Stock SwiftUI supplies
Liquid Glass, Dynamic Type, dark mode and VoiceOver correctly for free.

**Rejected — raw values now, extract tokens later.** The extraction is the expensive part.
Adding the seam up front costs an afternoon; retrofitting it means editing every view.

---

## Headline is calendar month in v1

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** "Remaining this month". Pay-period and custom timeframes go on the roadmap.

**Rejected — pay-period headline in v1.** Tracking from one payday to the next is a common
mental model, and it's the clearest differentiator from Dime. But it changes what the headline means and
shouldn't gate v1 shipping. Roadmapped for v1.1 rather than dropped.
