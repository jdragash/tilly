# Design

The visual and interaction rules as they stand. Present tense, rules only. The tenets they serve
are in `PROJECT.md`, the principles behind them in `TASTE.md`, and the evidence in
`INSPIRATION.md`. Every value reaches a view through `Tokens` (`DECISIONS.md`).

---

## State grammar

| Axis | States | Channel |
|---|---|---|
| **Time** | upcoming / charged | Weight: secondary vs. full |
| **Certainty** | estimated / known | *Not rendered in v1.* Returns with variable bills |

An upcoming row sits back: name, date, icon and amount at secondary weight; a charged row comes
forward at full weight. A skipped row withdraws further and strikes its amount through: listed,
visibly not counted, and marking no calendar. Nothing in v1 skips a charge. A charge dated today is
charged; one with no amount shows an em dash and adds nothing. Certainty, when it returns, gets its
own channel, a mark beside the amount, never lightness. The grammar holds wherever a date or amount
appears: the editor's date button shows a calendar with a clock for a date still to come.

---

## The shell

Laid out like iOS Calendar, with two views, Calendar and Categories, opening on the one you left.
A glass pair floats at the right end of the top row: the view button, whose icon names the view
you're in and whose menu lists the views with a checkmark on the current one, and +. The month
button sits bottom left; All bills and settings share a glass capsule bottom right, in every view.
Everything else is a sheet, so the reader never leaves their place: no tab bar, no pushed pages.
Settings keeps the categories in your order: drag to reorder, tap a colour to change it.

### Amounts

No amount carries a sign: `€950`, and a zero is `€0`. Amounts show in whole units: enter 74.10,
see 74. Cents may be entered, and amounts round before anything is totalled, so a total always
equals the figures above it.

---

## The calendar

### Three levels of one place

Calendar zooms, as iOS Calendar does: the year, a month, and the days, which are the timeline.
Tapping a month in the year opens it. Tapping a day with charges opens the timeline with that day's
first charge just under its month's header, the day's rows marked and fading. A back button top left
goes out a level: `‹ Year` over a month, and over the days the month under the middle of the list,
`‹ October`. A level grows out of what was tapped, a month from its place in the year, and shrinks
back into it, or crossfades under Reduce Motion. The app reopens on the level and month you left,
at the month's top, however long you were gone; the current month decides only on first run.

### The year

The next twelve months from this one, not paged: `Oct – Sep` over the year's total and its usual
month, the median of the twelve months' monthly bills. Each month is labelled with its total, bold
when its extras reach a fifth of the usual month, measured against your own months, never a budget.
A day of monthly bills is a grey dot; an extra is a dot in its category's colour, larger when the
day's extras reach that fifth; a ring marks a monthly bill that starts, changes price or ends,
dashed at €0. Today is red. A key under the months says what each mark means. Someone whose bills
never vary sees a year of grey dots and `Every month is €1,390. A yearly renewal would show in
colour.`

### The month

A grid from the week's first day, capped at `xxxLarge` as Calendar's is. A day shows its costliest
charge's emoji, two overlapped and `+N` beyond, and its total; an upcoming day sits back as an
upcoming row does; neighbouring months' days show only their number. Arrows and a swipe page it,
across the timeline's span. Under its name, the header's figure, or `Nothing this month`.

### All or Extras

An extra is any charge whose bill doesn't charge in every calendar month: yearly, quarterly, every
five weeks. Weekly and fortnightly bills are usual. One All / Extras control, the stock segmented
one, sits under the top row's right end at every level and holds across levels and launches. With
Extras, the year marks only extras (rings stay), the month and the timeline hold only extras, and
figures read `+€351 on top` or `Nothing on top`. Switching holds the month being read where it is.

### Getting back

The month button names the current month, `September`, and stays in its level. Over the days it
scrolls back, with a duration that scales with distance, even mid-flick; over a month it pages back
to this one; over the year, which already starts now, it isn't there. It stays as it is while you're
already there, like Calendar's Today. VoiceOver reads "Back to September". It is a system glass
button at Calendar's size, weight and place, 28pt in from the screen's edges, and the last line of
history clears it.

---

## The timeline

The calendar's closest level. Icon well, then name with the date beneath it, then the amount. The
well holds the category's emoji. A bill that ends adds its last month to the date, `Fri 18 · ends
05/27`, or `ended 08/26` once that payment is today or past. Nothing else joins that line. Every
charge is its own row, carrying its own date: no day heading or day total. Rows descend by date, a
day's charges by amount, ties by name. No separator between rows, and no `TODAY` badge: space and
the change of weight do that work.

### The month header

The month name, and under it on its own line, secondary, the figure: the current month carries
what is still to go, and says so, `€162 left`, or `€0 left` once it runs out. Every other month
carries its plain total with no qualifier. That header is the headline number, so it doesn't get a
second home above the content. A month name carries its year only when that year isn't the current
one, and in two digits, `September ’27`; VoiceOver hears it in full.

The header pins while its rows scroll under it, beneath the top row of back button and glass pair,
and hands off when the next arrives. Its ground is opaque, the page's own paper, so content passing
beneath is hidden rather than tinted; glass is for things that float over content. It keeps its full
size when pinned: condensing would make the month you're *in* the same shape as one you could
*open*. A hairline appears under it only while pinned, because a rule means something is being
closed. Behind the status bar the page's own background runs opaque and full width, so a header
handing off beneath it is hidden: a scrim or a blur won't do.

### One list, from your oldest charge to five years on

Months ahead run on above the current one, like Calendar, all there from the start, and history runs
on below. Nothing to tap open, nothing that closes itself. At rest the list sits flush on the
current month, however short. When it holds nothing charged, it ends with `This fills in as bills go
out.` While any bill runs on, the list runs five years ahead; once every bill ends it stops at the
last payment: `Nothing after May 2027.` Below, it stops at the oldest occurrence: `Nothing before
March.` An empty month isn't listed, except this one and next, so no month ever shows €0 for a month
the app knows nothing about. Expenses are entered for their next occurrence; a deliberately
backdated bill is shown.

### Nothing under the reader's eyes moves

Scrolling never inserts anything. When a change to a bill, or All / Extras, adds or drops months,
the month being read holds where it is, to the point. Crossing midnight into a new month moves the
header figure and reclassifies passed rows, and nothing else. Saving or deleting leaves the list
where it was.

---

## The category view

One month, one lane per category across its days, in the Settings order. Each charge is a dot on its
day in its category's colour: filled once charged, a ring while still to come, a dashed ring at €0.
A dot's area follows its amount on one scale for every month, so paging never resizes anything. A
line marks today. Each lane starts with the category's emoji and ends with its month total. Lanes
shrink to fit, 60pt down to 30pt, then the page scrolls. A category with nothing this month gets a
line under the lanes, `Nothing in September: 📗 next Nov 3`; on the current month, `Next` lists the
three soonest charges, at most one per category. The header is the timeline's, with a glass pair of
arrows left of the view button and +, paging a month at a time across the timeline's span and
stopping, dimmed, at either end.

Dragging across the lanes starts on touch and moves charge to charge, never stopping on an empty
day, with a tick at each. A readout names that day's charges and nothing else, in the header's row,
whose name and controls step aside while the finger is down; a name shortens before an amount does.
Tapping a dot opens its charge in the editor. Tapping a lane's emoji picks the category out: the
other lanes fade and the header figure becomes its total, until it's tapped again. Every category's
colour, one of eight, shows here and on the year; the timeline's wells stay grey.

---

## All bills

A sheet from the list button: every bill once, however many charges it has. Monthly / Yearly at the
top, kept across launches; Monthly is a bill's year over twelve, so a yearly bill reads as its share
of a month. The title, `All bills` or the picked category, sits over `€1,563 a month`; chips pick
out one category. Each category is a card with its total, costliest first, and its bills costliest
first: the name, a line saying what's actually charged when the figure isn't (`€640 yearly`) and
what's ahead (`€25 until Nov 10`, `from Oct 18`, `ends 12/26`), and the figure. No bill counts.
Ended bills wait behind `2 ended bills` under the cards, each with what it cost in all. Tapping a
bill opens its next charge in the editor, an ended one its last.

---

## The editor

### The amount is the screen

The amount is the largest thing on it, the keypad is up when the editor opens, and the name sits
under it. Close is top left; Save is the system's prominent checkmark top right, disabled until
amount, name and category are all there, and while a new category is half made. The date starts as
today. The keyboard covers the editor rather than pushing it, except at accessibility sizes, where
it scrolls.

### Three buttons: date, category, repeat

Equal thirds under the name, stacking full width at accessibility sizes. The icon says what kind of
thing, the label its value, and when orderly and fitting every word conflict, the words get shorter:

- **Date:** a calendar and `Oct 31`, with a clock for a date still to come, and never a year.
- **Category:** the category's emoji alone, or a tag until one is chosen.
- **Repeat:** a loop and `Monthly` or `3 months`, or a one-way arrow and `09/27` once the bill ends.

### Pickers open where the keypad was

Each button opens its picker in place of the keypad, at its height, so the amount and name never
move, and nothing stacks a second sheet over the editor.

- **Date:** a calendar and nothing else.
- **Repeat:** one wheel, `Every 1 month`, with an end column resting on `no end` and rolling into
  payment counts, the only way to set an end; then `Last payment Sep 30, 2027` shows under it.
- **Category:** emoji and name in the Settings order, `New category` last. That opens the system
  emoji keyboard, then asks for the name, with eight colours set to the next one unused; the emoji
  sits on the chosen colour. Emoji and name are required: without the emoji, the button couldn't
  tell a category from none.

### Opening a charge edits it

Tapping a row opens the editor for that charge, filled in, keypad up. The date is the charge's own,
where it landed if it was moved; a moved charge shows only there, with no trace at the old date. ✓
waits for a change, and a red trash button sits left of it.

### This charge, or future charges

Edit first, then choose, as Calendar. On ✓, when the amount or date changed and a charge follows,
a menu from ✓ asks `Save for this charge only` or `Save for future charges`. Future means this
charge and every one after, except a later charge changed on its own, which keeps its change while
its date still exists. Nothing before the open charge changes; from a bill's first charge, future
is all of it.

Name, category and the payment count belong to the whole bill and change without asking; the count
counts the whole bill and offers none ending before the open charge. A new repeat applies from this
charge on. One charge can be €0, for a free month, saved for that charge alone without asking; a
new bill, or a whole bill, needs more.

### Deleting asks which

The trash button asks, as Calendar: `Delete All Future Charges` keeps the charges before this one,
which is how a subscription ends, and the bill then reads `ends 08/26` like any bill with an end.
`Delete All Charges` takes the past too. A bill's first charge offers only `Delete Gym`.

---

## Copy and interaction

**No label restates its control** (tenet 3), and a word stays when removing it would leave a slot
meaning two things (TASTE 6). The month button says only `September`. **The app never says a bill
was paid.** It says *charged*: Tilly knows a date passed, not what left an account.

**Nothing to confirm, nothing to restart** (tenet 1). No control marks a charge as paid; a design
that needs one is wrong. A setting takes effect when it's set, and one too expensive to apply live
doesn't ship yet.

---

## Empty states

First run has no expenses and no categories, so it is doing the teaching. The calendar says
`Nothing recurring yet` over `Add a bill or a subscription and it shows up here before it goes
out.`, and the first expense makes the first category. The empty state is the first screen of the
product, not a placeholder: clean rather than unfinished, with the next action obvious.
