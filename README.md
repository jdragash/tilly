# Tilly

Tilly gives you a bird's-eye view of your recurring expenses — bills, subscriptions,
annual costs — so you know what's coming and when.

It is a personal hobby project, built in the open. It is **free forever**: no paywalls,
no in-app purchases, no locked features. Nothing about it is for sale, now or later.

## What it does

- Set up recurring expenses on any interval — every N days, weeks, months or years
- See them on one timeline: what's coming above, what's already been charged below
- Handle bills whose amount varies, like heating, without pretending you know the number
- Understand where your recurring money actually goes

Charges are assumed, not confirmed. When a bill's date passes, it's charged — there is
nothing to tick off. The app is meant to help you, not to become another thing you
maintain.

## Status

The timeline is built and is the whole app so far. It's one list you scroll: this month
open with what's left to come out, history running continuously behind it as far back as
your oldest charge, and next month already open above. You can look one month further
ahead — it puts itself away when you come back — jump to the current month from anywhere,
and close the app without losing your place.

**You can't add an expense yet.** The editor is the next piece of work; until it exists
the app only shows data it was seeded with. The recurrence engine underneath it is done
and tested.

See [`docs/ROADMAP.md`](docs/ROADMAP.md) for the order things are coming in, and
[`docs/PROJECT.md`](docs/PROJECT.md) for what the app is trying to be.

## Built with

SwiftUI and SwiftData, targeting iOS 26. No third-party dependencies.

The recurrence engine lives in `Core/` as a standalone Swift package with no UI and no
database, so it can be tested in isolation:

```bash
cd Core && swift test
```

## Acknowledgements

Tilly is inspired by [**Dime**](https://github.com/rafsoh/dimeApp) by Rafael Soh — an
excellent open-source expense tracker that gets a great deal right about clarity and
restraint. Studying it shaped much of the thinking here, and
[`docs/INSPIRATION.md`](docs/INSPIRATION.md) records specifically what and why.

Tilly contains no code from Dime. Every line here is original work; Dime's contribution
is in ideas and judgement, which is the best thing open source has to give.

## Licence

GPL-3.0 — see [`LICENSE`](LICENSE) — with an additional permission for App Store
distribution, in [`LICENSE-EXCEPTION.md`](LICENSE-EXCEPTION.md).

Fork it, modify it, learn from it. The copyleft is there so that nobody can take Tilly
closed-source: any distributed version has to come with its source under the same terms.
That's what keeps "free forever" from being merely a promise.
