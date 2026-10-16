# Card polish

## Problem

The card editor (v0.6.0) works, but on a phone it feels flat next to its prototype, and a few parts
of it misbehave in the hand. From Jake's first use on device, 2026-10-16:

- **Motion has no life.** Picking a pocket, the slips settling, the pocket lifting and the card
  filing all run on eased curves with no overshoot. Nothing gives when tapped: the prototype's
  pocket and emoji answer a press, the app's don't.
- **The filing ends on the wrong side of the lip.** The card shrinks over the pocket and fades on
  top of it. In the prototype it ends inside, as a small card behind the lip.
- **The pockets sit in a container fixed to the bottom of the sheet**, with a scroll edge, and a
  gap above them when there are few. They should start right under the card and scroll beneath it.
- **The name field moves as you use it.** Tapping it resizes things around it, and when typing
  starts, the text jumps as the border goes.
- **Backspace in the name can erase the whole name and highlight it.** Cause unknown; autocorrect's
  revert is the first suspect.
- **The amount is too big.** `85.55` already shrinks to fit. The prototype tightens the amount's
  letter spacing (−0.026em), and the build doesn't.
- **The date and repeat are hard to hit.** Each line is about 16pt tall, and the ring round an open
  one nearly touches the other line.
- **The currency follows the device region**, so a phone set to a euro region writes `85,55 €`,
  where the prototype showed `€85.55`. Jake prefers the symbol first, and asked whether after is
  standard. It is, in much of Europe.

## Which tenets are at stake

Tenet 2 (hierarchy): the card is the screen, and it shouldn't shift under the thumb. TASTE 2 (the
reader's place is theirs) and 12 (every control answers at once) apply directly. The rest is feel,
which the tenets don't speak to.

## Why now

The card has just landed and is in use. The roadmap held "pockets under the card" until the card and
pockets were in use, and they now are. Polishing before All bills is rethought in the same language
means the pocket and card motion is settled once, then reused there.

## What "better" looks like

1. Tapping a pocket, a part of the card or ✓ answers at once with a visible give, and lands with
   overshoot, as the tilly-video does.
2. On ✓ the card drops into its pocket, the pocket gives as it lands, and the bill's slip rises
   behind the lip. Nothing is left floating over the lip.
3. Few pockets start right under the card; many scroll beneath it, and the card stays put. No
   container edge shows.
4. Neither the name's text nor anything around it moves when the field is tapped or typed in.
   Backspace deletes one character.
5. `€85.55` (or `85,55 €`) fits at full size, and only long amounts shrink.
6. The date and repeat have at least a 44pt tap target, without bigger type.

## Prior attempts

- **The card editor itself** (`docs/briefs/edit-revisit/brief.md`, merged in `4030eae`, v0.6.0).
  Its plan specified eases and durations from the prototype (`Motion.pick` 0.3s ease-in-out,
  `Motion.file` 0.24s with the curve `(.3, .6, .35, 1)`). They match on paper and read flat on
  device. The plan named `matchedGeometryEffect` for filing; the build shrinks the card as one
  picture instead, because matching frames re-lays it out at pocket size.
- **Pockets under the card** was deferred in `ROADMAP.md` until the card was in use, "because the
  scroll and the card's place have to be built together". `DECISIONS.md` ("Adding a bill is a card
  you complete…") says to revisit when that happens.
- **The motion reference already exists.** The tilly-video's card composition
  (`~/code-projects/tilly-video/cards/index.html`) animates this exact flow. A tap dips the pocket
  to 0.93 and springs back (`elastic.out(1, 0.45)`, 0.4s). ✓ pops from 0.88 (`back.out(2.5)`). The
  card drops into the pocket heavy and quickening (`power2.in`/`power3.in`, a −5° turn). The pocket
  squashes (0.88 tall, 1.07 wide, from its base) and springs back (`elastic.out(1.1, 0.35)`), and
  the bill's slip pops up 8pt and bounces down. Jake picked this as the feel.
- **The amount's stillness** was hard won in the old editor (`.claude/rules/editor.md`): the card
  "never moves" held under every panel and keyboard in v0.6.0, measured. Pockets under the card must
  keep that.

## Constraints

- SwiftUI's springs (`.spring(duration:bounce:)`, `keyframeAnimator`) stand in for GSAP's elastic
  and back curves. They won't match the video's numbers one for one; the video is matched by eye on
  device.
- Haptics (`sensoryFeedback`) are available here and weren't in the prototype or the video.
- Every motion stays interruptible (TASTE 12), including a tap mid-filing, which closes the sheet.
- Reduce Motion keeps its fade.
- Tokens only: every duration, spring and scale is a token.
- Pockets under the card change the sheet's layout: the card floats over a scrolling list for the
  category panel only. The keypad, calendar and wheel still take the keypad's place. The keyboard
  rules in `.claude/rules/editor.md` and `swiftui-scrolling.md` apply.

## We'll know it worked when

Jake uses it on his phone and doesn't call it flat. That isn't measurable, so the motion values get
settled in a prototype pass first. The rest is checkable: no part of the card moves between the
keypad, keyboard, calendar, wheel and pockets (measured at the card's top edge); `85.55` renders at
full size; the date and repeat hit areas measure 44pt; backspace removes one character.

## In and out

**In:** motion and press feedback across the card and pockets, filing that ends inside the pocket,
pockets under the card, the name field, the amount's size and spacing, the date and repeat targets,
haptics, and the currency placement decision.

**Out:** rethinking All bills in the pocket language (its own brief), the Tilly, Drawn look, the
calendar and category view, undo, and new category management.

## Open questions

1. **Currency:** keep following the region (`85,55 €` where that's local), or always put the symbol
   first (`€85,55`)? Claude recommends the region, so Tilly matches every other app on the phone.
2. **Where do the motion values get settled?** In the existing card prototype, tuned until Jake signs
   off, then built? Or straight in the app, using the video's values as the first guess?
3. **Pockets under the card, at rest:** when the category panel opens, does the card stay full size
   with the pockets scrolling under it, or shrink to give them room?
4. **Haptics:** a light tap on picking a pocket and a firmer one when the card lands. Wanted, and
   anywhere else?

## Sources

- Jake's device notes in conversation, 2026-10-16; memory `editor-card-device-notes`
- `docs/PROJECT.md`, `docs/TASTE.md` (2, 11, 12), `docs/ROADMAP.md` (Expense editor, Pockets under
  the card, the other screens in the card's language), `docs/DECISIONS.md` ("Adding a bill is a
  card you complete…")
- `docs/briefs/edit-revisit/brief.md`, `docs/prototypes/edit-revisit-card.html`
- `~/code-projects/tilly-video/cards/index.html` (`dropIn`, `pop`, the filing timeline)
- `git log`: `d5c671f`..`c2bb596` (the card's six steps), `4030eae` (the merge)
- `.claude/rules/editor.md`, `Tilly/Editor/EditorCard.swift`, `PocketGrid.swift`, `ExpenseEditor.swift`

## Updates

**2026-10-16.** Jake left the four open questions to Claude's recommendation:
1. Currency follows the device region.
2. The motion is tuned in a prototype first: `docs/prototypes/card-polish.html`, with the as-built and
   video motion as presets and every spring on a control, in SwiftUI's own parameters.
3. The card stays full size over the pockets, the first row right under it.
4. Haptics: light on picking a pocket and on ✓, medium when the card lands.
