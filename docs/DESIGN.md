# Design

The visual and interaction rules as they stand. Present tense, rules only. The tenets they serve
are in `PROJECT.md`, the principles behind them in `TASTE.md`, and the evidence in
`INSPIRATION.md`.

---

## Tokens

Every view refers to `Tokens`, never to a raw value, dimensions included; the seam check is in
`.claude/rules/views-and-tokens.md`. In v1 tokens alias system values: system components supply Liquid Glass,
Dynamic Type, dark mode and VoiceOver, and the indirection makes the design pass a one-file change.
Screens add the tokens they need. `DesignSystem/Gallery.swift`, still to come, will render every
token in light, dark and accessibility sizes. The design pass layers on system materials rather
than replacing them.

---

## State grammar

| Axis | States | Channel |
|---|---|---|
| **Time** | upcoming / charged | Weight: secondary vs. full |
| **Certainty** | estimated / known | *Not rendered in v1.* Returns with variable bills |

An upcoming row sits back: name, date, icon and amount all at secondary weight. A charged row
comes forward at full weight. A skipped row withdraws further and strikes its amount through:
listed, visibly known about, visibly not counted.

An occurrence dated today is charged. An occurrence with no amount shows an em dash and adds
nothing to any total.

When certainty returns, it takes its own channel, a mark beside the amount, and never lightness.
Lightness already means upcoming, and an estimated past charge would read as upcoming.

The grammar applies wherever a date or amount appears, the editor included: a future date looks
like the future before you save. There the date button's icon carries it, a calendar with a clock
for a date still to come and a plain calendar otherwise. A lighter button would read as empty.

---

## The shell

The timeline is the app's one screen, laid out like iOS Calendar. Three glass controls float over
it: + at the right end of the pinned header's row, the month button bottom left, and settings bottom
right. Everything else opens as a sheet over the timeline, the editor and settings alike, so the
reader never leaves their place. No tab bar and no pushed pages.

Categories are kept in Settings. There is no list of every expense: the timeline is that list.

---

## The timeline

### The row

Icon well, then name with the date beneath it, then the amount. The well holds the category's
emoji; every expense has one. A bill that ends adds its last month to the date, `Fri 18 · ends
05/27`, and nothing else joins that line.

### Amounts

Every amount carries a minus sign: rows and month totals. Nothing on this screen is money
arriving, so the sign sets the register. A zero is unsigned (`€0`), because nothing is going out.

Amounts round to whole units before anything is totalled, so a total always equals the figures
above it.

### Rules delimit, they don't decorate

No separator between rows; space does that work. A hairline appears only under a pinned month
header. A rule means something is being closed.

### Every charge is its own row

Two charges on one day are two rows, each carrying its own date. No day heading and no day total:
a list of equal rows reads faster than a list that changes shape. Rows descend by date, and a day's
charges by amount, with ties broken by name.

### The month header

The current month's header carries what is still to go, and says so: `−€162 left`. When it runs
out it reads `€0 left`. Every other month carries its plain total with no qualifier. A future
month has nothing charged, and a past month has nothing left.

That header is the headline number, so it doesn't get a second home above the content. Totals
everywhere exclude skipped occurrences. A month name carries its year only when that year isn't
the current one.

### Nothing marks the boundary between upcoming and charged

The last row at secondary weight and the first at full weight are the boundary. No divider. No
`TODAY` badge either: the most recent charge usually isn't today.

### One list, and the future runs on

Months ahead run on above the current one, like Calendar, and history runs on below. Nothing to tap
open, nothing that closes itself. At rest the list sits flush on the current month, however short.

When the current month's expanded section holds nothing charged, it ends with `This fills in as
bills go out.`

### The future runs five years ahead, or to your last payment

While any bill runs on, the list runs five years ahead and stops there, nothing drawn above: dozens
of flings away, and close enough that a launch doesn't wait for it. Once every bill ends it stops at
the last payment instead: `Nothing after May 2027.` An empty month ahead isn't listed, except next.

### History stops where your oldest charge does

The list runs down to the oldest occurrence the rules generate and stops, with one line: `Nothing
before March.` A month between there and today that holds nothing isn't listed at all. No month
ever shows €0 for a month the app knows nothing about.

Expenses are entered for their next occurrence, not their historical start. Backdating stays
possible, and a deliberately backdated bill is shown.

### No reserved space

No slot is held open for features that don't exist yet, such as look-ahead nudges. An empty box
above the content is the competitor's defining mistake.

### A moved occurrence appears at its new date only

No ghost row at the original date, and no "moved from the 1st". Whether an edit applies to this
occurrence or the series is asked at the moment of editing.

### Getting back

The month button sits bottom left, always, and names the current month: `September`. Tapping it
brings you back to the current month from anywhere. It stays exactly as it is while you're already
there, like Calendar's Today: a control that appears or changes on its own does so for a reason the
reader can't see. VoiceOver reads "Back to September".

Tapping it scrolls back rather than jumping, with a duration that scales with distance, even
mid-flick. It is a system glass button at Calendar's size, weight and place, 28pt in from the screen's edges. The list carries a bottom inset of the
button's height plus its margin, so the last line of history clears it.

### The month you're reading stays named

The month header pins to the top while its rows scroll under it, and hands off when the next header
arrives. It shares that row with +, which floats over its right end, so the total sits beside the
month name rather than at the edge: `September −€53 left`. Its ground is opaque and the same paper
as the page, so content passing beneath is hidden rather than tinted, and it carries that ground at
rest too. Glass is for things that float over content; a full-bleed sticky header doesn't float.

The row gives + 8pt of clear space above and below. It keeps its full size when pinned. Condensing would save a point, cost three points of type, and
make the month you're *in* the same shape as a month you could *open*. The hairline under it appears
only while it's pinned.

### Nothing under the reader's eyes moves

Nothing is ever inserted above the reader: the months ahead are all there from the start. Crossing
midnight into a new month moves the header figure and reclassifies passed rows, and nothing else.

### Your place survives

You return to the month you left, at its top, however long you were gone and whether or not the
process survived. The current month decides where you land only on first run.

### The app fills the top inset

The area behind the status bar and Dynamic Island carries the page's own background, opaque and full
width. Content scrolls under it and is hidden. It has to hide a month header, not just a row: during a
hand-off the outgoing header sits in that inset. iOS 26's scroll edge effect had no visible effect
here, and a scrim or progressive blur leaks exactly where that header sits.

Mockups leave the inset empty rather than painting a clock into it.

---

## The editor

### The amount is the screen

The amount is the largest thing on it, and the keypad is up when the editor opens. The name sits
under the amount. Close is top left, and Save is the system's prominent checkmark top right.

The keyboard covers the editor rather than pushing it, except at accessibility sizes, where it scrolls.

### Amount, name and category are required

Save stays disabled until all three are there, and while a new category is half made. The date
starts as today. The row leads with the
emoji and the name, and insights stand on the category.

### Three buttons: date, category, repeat

Equal thirds under the name. The icon says what kind of thing, the label says its value:

- a calendar and `Oct 31`, with a clock on the calendar for a date still to come; never a year
- the category's emoji alone, or a tag until one is chosen
- a loop and `Monthly` or `3 months`, or a one-way arrow and `09/27` once the bill ends

When orderly and fitting every word conflict, the words get shorter. At accessibility text sizes
the three stack, full width, in the same order.

### Pickers open where the keypad was

Choosing a date, a repeat or a category replaces the keypad in place, at the keypad's height, so
the amount and name never move. Nothing stacks a second sheet over the editor.

- **Date:** a calendar and nothing else.
- **Repeat:** one wheel, `Every 1 month`, with an end column that rests on `no end` and rolls into
  payment counts. Once there's an end, `Last payment Sep 30, 2027` shows under it. A count is the
  only way to set an end.
- **Category:** a list of emoji and name, with `New category` last. That opens the system emoji
  keyboard, then asks for the name. Both are required: without the emoji, the button couldn't tell
  a category from none.

---

## Copy rules

**No label that restates its control** (tenet 3). **The test cuts both ways:** a word stays when
removing it leaves a slot meaning two things. `−€162 left` keeps "left", and drops "this month"
because the month name sits beside it. The month button says only `September`.

**The app never says a bill was paid.** It says *charged*. Tilly knows a date passed, not what left
an account.

**Amounts display in whole units.** Enter 74.10, see 74. Cents may be entered.

---

## Interaction patterns

### "This occurrence" vs. "all future"

When editing something that recurs, the scope being changed is unmistakable *at the moment of
choosing*, not inferable afterwards. One occurrence writes an override. The series edits the rule and
corrects the whole timeline.

### Nothing to confirm

No control anywhere marks a charge as paid. A design that needs one is wrong.

### A setting takes effect when it's set

No "restart the app to apply". If a setting is too expensive to apply live, it doesn't ship yet.

---

## Empty states

First run has no expenses and no categories, so it is doing the teaching. The timeline says `Add a
bill or a subscription and it shows up here before it goes out.`, and the first expense makes the
first category. The empty state is the first screen of the product, not a placeholder: clean rather
than unfinished, with the next action obvious.
