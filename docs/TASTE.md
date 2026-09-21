# Taste

How Tilly's product and design choices get made, distilled into principles that predict the next
one. Principles here outrank `DESIGN.md` and `DECISIONS.md`, and sit below the tenets.

A principle gets in only with at least two independent decisions or corrections behind it, one
line and one example, and Jake's approval. `tilly-prune` adds, sharpens and removes them; the
commit that changes one carries its evidence. When a proposal leans on a principle, name it by
number.

---

## Truth and trust

**1. The app never claims what it doesn't know.**
A month with nothing in it isn't listed rather than shown as €0. A passed date is "charged",
never "paid".

**2. The reader's place is theirs: nothing under their eyes moves, and nothing resets it.**
The months ahead are all there from the start, so nothing is ever inserted above the row being read.

**3. The list ends where the app's knowledge does, and says so.**
History stops at the oldest charge with a line saying so. The future runs on for as long as a bill does.

**4. Nothing appears, changes or resets for a reason the reader can't see.**
Position isn't reset "on next launch", because nobody can tell a relaunch from a switch.

## Hierarchy and marks

**5. A mark that looks the same everywhere says nothing. Spend a distinction only where it
distinguishes.**
No separator under every row. A hairline appears only under a pinned month header.

**6. A word stays only if it does work no other channel does, and then it stays.**
`−€162 left` keeps "left", and drops "this month" because the month name sits beside it.

**7. The content is the screen. A figure goes on the thing it describes, not in a box above it.**
What's left this month lives in the pinned month header, not in a headline card.

**8. Different kinds of thing never share a look.**
The pinned header is paper and the buttons floating over it are glass, because only they are controls.

## Shipping

**9. Ship a bounded, named limitation rather than hold the feature.**
A relaunch returns you to the top of the month you were reading, not the row, and the decision
says what would lift it.

**10. If a behaviour turns on a number, the design names the number.**
The old return pill appeared 240pt from rest. Written as "away from the month", it was built as a full
screen.

**11. Stock platform first, behind a seam. Layer on the system, don't fight it.**
The month button is the stock glass button, and every value it uses sits behind `Tokens`.
