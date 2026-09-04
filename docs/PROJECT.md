# Tilly — what it is and why

The source of truth for what this app is trying to be. Stable by design: sequence lives
in `ROADMAP.md`, visual and interaction rules in `DESIGN.md`, and the record of choices
already made in `DECISIONS.md`.

## The problem

You don't know when your recurring expenses are coming or how much they'll take. They
arrive as surprises — an annual insurance renewal, a subscription you forgot, a heating
bill that doubled in January. Banking apps show you what already happened. Budgeting apps
ask you to categorise the past. Neither tells you what's about to hit.

## Jobs to be done

1. **Give me forward visibility** so I'm in control of what my recurring expenses look
   like — day to day, week to week, month to month, year to year.
2. **Show me what's actually recurring** so I can manage cashflow and see my own habits
   clearly.
3. **Stay minimal with maximum output** — flexible to how I actually live, not a tool I
   have to work around.

## Who it's for

One person, specifically. This is a personal app built for a single user, and that focus
is a feature — it's what keeps the scope honest and the decisions concrete. If it turns out to work for other people, good; it will not be
compromised in advance to court them.

## Tenets

These are checkable rules, not slogans. `tilly-ship` audits against them.

### 1. A system that helps, not one you maintain

No ticking things off. No confirming what already happened. When a bill's date passes,
it's charged. The app's job is to know things for you, not to ask you to tell it what it
could have worked out.

*Test:* does this feature create an ongoing obligation for the user? If yes, it's wrong.

### 2. Minimal for hierarchy's sake, not minimalism's

Not empty for the aesthetic. Every element earns its place by making the most important
thing on that screen more obvious. The amount is big because the amount matters. The
category is small because it's context.

*Test:* can you name what this screen's most important element is, and does the design
make that unmistakable in under a second?

### 3. Self-evident over labelled

If a control's meaning is obvious from context, it carries no label. A field on a screen
you reached by tapping "+" doesn't need to say "Price". A date picker doesn't need to say
"Payment Date". Labels that restate the obvious add visual noise and push the real
content down.

*Test:* remove the label. Is anything genuinely unclear? If not, it stays removed.

### 4. Never prescriptive beyond the functional minimum

Ask only for what the app needs in order to work. Everything else is the user's call.

**Categories ship empty.** Not a starter set, not suggestions on first run. The user's
categories are theirs — they might be conventional, they might be private shorthand that
means nothing to anyone else. Deciding for them is deciding wrong.

*Test:* is this input required for the feature to function? If not, it's optional, and
its shape is the user's to choose.

### 5. Free forever

No paywalls, no in-app purchases, no locked features, no premium tier. Every part of the
app works for everyone who has it.

*Test:* would this feature work differently for someone who hadn't paid? Then it doesn't
ship.

## In scope for v1

Recurring expenses and the timeline that shows them. Creating and editing recurrence
rules, handling occurrences that deviate from their rule, user-created categories, and
enough insight to see where the money goes.

## Out of scope, deliberately

Each of these was considered and deferred with a reason. See `ROADMAP.md` for when, and
`DECISIONS.md` for the full reasoning.

- **Savings buckets and goals** — a second app-shaped idea. The schema and navigation
  leave room for it; building both at once would double the model before either is proven.
- **Bank connections and automatic import** — Tilly is about rules you declare, not
  transactions it discovers. Manual entry is a few minutes once.
- **One-off expenses** — Tilly is about what recurs. A single purchase belongs elsewhere.
- **Income and budgets** — Dime does this well; it's a different job from the one here.
- **Multi-currency** — one currency, taken from the device locale.
