# Design

The visual and interaction rules as they stand. Present tense, rules only. The tenets they serve
are in `PROJECT.md`, the principles behind them in `TASTE.md`, and the evidence in
`INSPIRATION.md`.

---

## Tokens

Every view refers to `Tokens`, never to a raw value, dimensions included; the seam check is in
`.claude/rules/views-and-tokens.md`. In v1 tokens alias system values: system components supply Liquid Glass,
Dynamic Type, dark mode and VoiceOver, and the indirection makes the design pass a one-file change.
Screens add the tokens they need. The design pass layers on system materials rather than replacing them.

---

## State grammar

| Axis | States | Channel |
|---|---|---|
| **Time** | upcoming / charged | Weight: secondary vs. full |
| **Certainty** | estimated / known | *Not rendered in v1.* Returns with variable bills |

An upcoming row sits back: name, date, icon and amount all at secondary weight. A charged row
comes forward at full weight. A skipped row withdraws further and strikes its amount through:
listed, visibly known about, visibly not counted. Nothing in v1 skips a charge. An occurrence
dated today is charged. One with no amount shows an em dash and adds nothing to any total.

When certainty returns, it takes its own channel, a mark beside the amount, and never lightness.
Lightness already means upcoming, and an estimated past charge would read as upcoming.

The grammar applies wherever a date or amount appears, the editor included: a future date looks
like the future before you save. There the date button's icon carries it, a calendar with a clock
for a date still to come and a plain calendar otherwise. A lighter button would read as empty.

---

## The shell

Laid out like iOS Calendar, with two views, the timeline and categories, opening on the one you left.
A glass pair floats at the right end of the header row: the view button, whose icon names the view
you're in and whose menu lists the views with a checkmark on the current one, and +. The month
button sits bottom left and settings bottom right. Everything else opens as a sheet, the editor and
settings alike, so the reader never leaves their place. No tab bar and no pushed pages. There is no
list of every expense: the timeline is that list. Settings keeps the categories, in your order:
drag to reorder, and tap a category's colour to change it from a menu.

---

## The timeline

### The row

Icon well, then name with the date beneath it, then the amount. The well holds the category's
emoji; every expense has one. A bill that ends adds its last month to the date, `Fri 18 · ends
05/27`, or `ended 08/26` once that payment is today or past. Nothing else joins that line. Every
charge is its own row, carrying its own date: no day heading or day total. Rows descend by date, a
day's charges by amount, ties by name.

### Amounts

Every amount carries a minus sign: rows and month totals. Nothing on this screen is money
arriving, so the sign sets the register. A zero is unsigned (`€0`), because nothing is going out.
Amounts round to whole units before anything is totalled, so a total always equals the figures above.

### Rules delimit, they don't decorate

No separator between rows; space does that work. A hairline appears only under a pinned month
header. A rule means something is being closed. Nothing marks where upcoming meets charged either:
the change of weight is the boundary, and there is no `TODAY` badge, since the latest charge
usually isn't today.

### The month header

The month name, and under it on its own line, secondary, the figure: the current month carries
what is still to go, and says so, `−€162 left`, or `€0 left` once it runs out. Every other month
carries its plain total with no qualifier. That header is the headline number, so it doesn't get a
second home above the content. Totals exclude skipped occurrences. A month name carries its year
only when that year isn't the current one, and in two digits, `September ’27`; VoiceOver hears it
in full.

### One list, and the future runs on, five years or to your last payment

Months ahead run on above the current one, like Calendar, and history runs on below. Nothing to tap
open, nothing that closes itself. At rest the list sits flush on the current month, however short.
When it holds nothing charged, it ends with `This fills in as bills go out.` While any bill runs on,
the list runs five years ahead; once every bill ends it stops at the last payment instead: `Nothing
after May 2027.` An empty month ahead isn't listed, except next.

### History stops where your oldest charge does

The list runs down to the oldest occurrence the rules generate and stops, with one line: `Nothing
before March.` A month between there and today that holds nothing isn't listed at all. No month
ever shows €0 for a month the app knows nothing about. Expenses are entered for their next
occurrence, not their historical start; a deliberately backdated bill is shown.

### Getting back

The month button sits bottom left, always, and names the current month: `September`. Tapping it
brings you back from anywhere, and it stays as it is while you're already there, like Calendar's
Today. VoiceOver reads "Back to September".

Tapping it scrolls back rather than jumping, with a duration that scales with distance, even
mid-flick. It is a system glass button at Calendar's size, weight and place, 28pt in from the
screen's edges, and the last line of history clears it.

### The month you're reading stays named

The month header pins to the top while its rows scroll under it, and hands off when the next header
arrives. It shares that row with the glass pair, which floats over its right end. Its ground is
opaque and the same paper as the page, so content passing beneath is hidden rather than tinted, and
it carries that ground at rest too. Glass is for things that float over content.

The row gives the pair 8pt of clear space above and below. It keeps its full size when pinned: condensing
would cost three points of type and make the month you're *in* the same shape as one you could
*open*. The hairline under it appears only while it's pinned.

### Nothing under the reader's eyes moves

The months ahead are all there from the start, so scrolling never inserts anything. When a change
to a bill adds or drops months above, the month being read holds where it is, to the point. Crossing
midnight into a new month moves the header figure and reclassifies passed rows, and nothing else.
Saving or deleting leaves the list where it was, even when the charge lands out of sight. After a
relaunch you return to the month you left, at its top; the current month decides only on first run.

### The app fills the top inset

The area behind the status bar and Dynamic Island carries the page's own background, opaque and full
width. Content scrolls under it and is hidden. It has to hide a month header, not just a row: during a
hand-off the outgoing header sits in that inset, which is why a scrim or a blur won't do.

---

## The category view

One month, one lane per category across its days. Each charge is a dot on its day in its category's
colour: filled once charged, a ring while still to come, a dashed ring at €0. A dot's area follows
its amount on one scale for every month, so paging never resizes anything. A line marks today. Each
lane starts with the category's emoji and ends with its month total. Lanes run in the Settings
order and shrink to fit, 60pt down to 30pt, so the month stays on one screen, then the page scrolls. A category with nothing this month gets no lane but a line under the lanes: `Nothing in
September: 📗 next Nov 3`. On the current month, `Next` lists the three soonest charges, at most
one per category.

The header is the timeline's, with a glass pair of arrows left of the view button and +, paging a
month at a time and stopping, dimmed, at the oldest charge and the timeline's last month.

Dragging across the lanes starts on touch and moves charge to charge, never stopping on an empty
day, with a tick at each. Above the finger a readout names that day's charges and nothing else.
Tapping a dot opens its charge in the editor. Tapping a lane's emoji picks the category out: the
other lanes fade and the header figure becomes its total, until it's tapped again.

Every category has a colour, one of eight, shown here; the timeline's wells stay grey for now.

---

## The editor

### The amount is the screen

The amount is the largest thing on it, and the keypad is up when the editor opens. The name sits
under the amount. Close is top left, and Save is the system's prominent checkmark top right. The
keyboard covers the editor rather than pushing it, except at accessibility sizes, where it scrolls.

### Amount, name and category are required

✓ stays disabled until all three are there, and while a new category is half made. The date
starts as today. The row leads with the emoji and the name, and insights stand on the category.

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
- **Category:** a list of emoji and name in the Settings order, with `New category` last. That opens
  the system emoji keyboard, then asks for the name, with a row of eight colours set to the next one
  not yet used. Emoji and name are required: without the emoji, the button couldn't tell a category
  from none. The emoji sits on the chosen colour.

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

Name and category belong to the whole bill and change without asking, as does the payment count,
which counts the whole bill whichever charge is open and offers no count ending before it. A new
repeat applies from this charge on.

One charge can be €0, for a free month: an ordinary amount, saved for that charge alone without
asking, and drawn as `€0`. A new bill, or a whole bill's amount, still needs more than zero.

### Deleting asks which

The trash button asks, as Calendar: `Delete All Future Charges` keeps the charges before this one,
which is how a subscription ends, and the bill then reads `ends 08/26` like any bill with an end.
`Delete All Charges` takes the past too. A bill's first charge offers only `Delete Gym`.

---

## Copy rules

**No label that restates its control** (tenet 3). **The test cuts both ways:** a word stays when
removing it leaves a slot meaning two things. `−€162 left` keeps "left", and drops "this month"
because the month name sits above it. The month button says only `September`.

**The app never says a bill was paid.** It says *charged*. Tilly knows a date passed, not what left
an account.

**Amounts display in whole units.** Enter 74.10, see 74. Cents may be entered.

---

## Interaction patterns

**Nothing to confirm.** No control anywhere marks a charge as paid. A design that needs one is wrong.

**A setting takes effect when it's set.** No "restart the app to apply". If a setting is too
expensive to apply live, it doesn't ship yet.

---

## Empty states

First run has no expenses and no categories, so it is doing the teaching. The timeline says `Add a
bill or a subscription and it shows up here before it goes out.`, and the first expense makes the
first category. The empty state is the first screen of the product, not a placeholder: clean rather
than unfinished, with the next action obvious.
