# Category editor, prototype and app side by side

Taken 2026-10-27 at `claude/project-thread-v3a3hk` 7479606, iPhone 17 Simulator (iOS 27), against
`docs/prototypes/category-editor.html` (Tune: search `top`, findEdit `press`, cardInfo `cost`,
infoAt `below`). Each `side-by-side-*` has the prototype on the left and the app on the right,
both at point scale (390 and 402 wide). The sample data differs: the prototype has its 14
made-up categories, the app its "Typical year" scenario, so names, counts and figures differ by
design. `app-*-ax` are the app at the accessibility-large text size.

## Differences that remain

- **Picker under the bill card:** the app's grid starts about 10pt lower under the card than the
  prototype's. The editor's own spacing; left alone, as its layout is held by measured rules.
- **Symbols:** the app's catalogue is far larger than the prototype's 28 stand-ins, so the grid
  runs longer and the picked symbol is often below the fold.
- **Sort menu:** the system menu puts each sort's detail under its name; the prototype sets it on
  the right.
- **Monthly / Yearly:** the system segmented control, glass, rather than the prototype's flat one.
- **Header buttons and the sheet's grabber:** the system's glass circles and grabber, as the bill
  editor already has.
- **Pictures from emoji:** sample categories made before symbols (Car, Loans) still draw their
  emoji.
- **Long names at the largest sizes:** past 80% a name breaks mid-word ("Subscriptions" at
  accessibility sizes), as agreed: imperfect over tiny.
- **All bills notes:** a bill whose figure is its own charge shows no note, where the prototype
  showed none either; rhythms the prototype doesn't have (`€45 every 3 months`) are kept.

Fixed in this pass: the Categories page's ground (white → paper), square symbol cells, the Undo
capsule's height (70 above the bottom), and the filled tile in Settings.
