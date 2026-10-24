# Observations

Jake's running list from using the app: things that feel off, need tuning, or want their logic
thought through. Messy on purpose. Add freely; tick an item off in the same change that settles it,
and delete ticked items once they've shipped.

## Logic to work through

- [ ] **Past charges don't treat all bills alike.** A bill with an end date shows its charges in
  the past, but a recurring bill added later doesn't show charges for dates before it was added.
  Which is right? Should the past show what a bill *would* have charged, only what it charged
  since it was entered, or should a bill's start date decide?

## Categories

- [ ] **Edit and remove categories.** Next high priority. Today a category can only be created:
  there's no way to rename it, change its symbol or delete it.
- [ ] **Fine-tune creating a category.** The create flow needs a polish pass.
- [ ] **Suggest a symbol while typing a category's name.** Start with a hand-made keyword-to-symbol
  list plus on-device word similarity (`NLEmbedding`) for names the list misses: no AI model,
  instant, works on every phone. Apple's on-device model (Foundation Models) could be an optional
  extra on phones that support it.

## Tune-ups

## Ideas
