# Observations

Jake's running checklist from using the app. Add freely, newest at the bottom, with the next
number. An item keeps its number for good, so it can be referred to: when it's fixed, tick it and
move it to Done in the same change.

6. [ ] When every charge this month is done, the timeline still shows the plain Today line above
   them, which looks awkward. Design a fuller, positive ending instead, like "All done this month".
9. [ ] Opening the bill editor's sheet feels laggy, as if the frame rate were wrong, and the app in
   general doesn't feel as smooth as real apps. Is the test build different? (2026-10-28)
   *2026-11-08: the sheet no longer redraws the pictures behind it, but it still feels slow on the
   phone, and quick pinching between levels does too. Next: profile on the phone in Instruments.*

## Done

1. [x] Past charges don't treat all bills alike. A bill with an end date shows its charges in the
   past, but a recurring bill added later doesn't show charges for dates before it was added.
   Which is right: what a bill *would* have charged, only what it charged since it was entered, or
   whatever its start date says?
   *Decided 2026-10-25: its first charge decides; the editor's date says `First charge`.*
2. [x] Edit and remove categories (next high priority). Today a category can only be created.
3. [x] Fine-tune creating a category.
4. [x] Suggest a category's symbol while typing its name. Start with a keyword-to-symbol list plus
   on-device word similarity (`NLEmbedding`); Apple's on-device model as an optional extra.
5. [x] Let the edit/create sheet drag down from anywhere on it, not just the top handle.
7. [x] The bottom-left button jumps to the current month. Now that there's a Today line, it should
   jump to today instead, scrolling so the Today line sits in the middle of the screen.
8. [x] Need ability to pinch to zoom in and out between year view, month view, and timeline view.
   Today you need to have an entry to enter timeline view from month view, which makes no sense.
10. [x] Tapping Today overshoots and springs back to the day: not smooth, feels janky.
11. [x] More settings to try other kinds of transition for opening the sheet, and for going to
    Today.
12. [x] Make the pinch follow the fingers, as first prototyped: the trigger version works, but this
    is worth finishing.
