---
paths:
  - "Tilly/**"
  - "TillyTests/**"
---

# Driving the Simulator and the test run

Tooling that cost time, on the iPhone 17 simulator, iOS 27.

## Tests

- **`xcodebuild … test` shuts the booted simulator down.** Boot it again before driving the app.
- **A failing Swift Testing run in `xcodebuild` looks like a hang:** it then runs `simctl
  diagnose` for up to 600s. Pass `-resultBundlePath` and read it instead of waiting:
  `xcrun xcresulttool get test-results summary --path <bundle> --compact`.

## Logs

- **`simctl launch --console-pty` has hung with no output** from the agent's shell, with and
  without `script`, and `--stdout=` wrote nothing. A temporary `NSLog` read back with
  `simctl spawn booted log show --last 1m --predicate 'eventMessage CONTAINS "…"'` worked.

## Settings and state

- **`simctl spawn booted defaults write com.jdragash.Tilly …` doesn't reach the app**, and editing
  the container's plist is overwritten by cfprefsd. Write through cfprefsd to the container's
  path, with the app terminated: `simctl spawn booted defaults write "$(xcrun simctl
  get_app_container booted com.jdragash.Tilly data)/Library/Preferences/com.jdragash.Tilly" key
  value`. Keys: `tillyDeveloperScenario`, `viewMode`.
- **Sample scenarios reseed on every launch**, so "survives relaunch" can't be seen in one. Cover
  it with a test that reopens an on-disk store.

## Keyboards

- **Measuring the editor needs the on-screen keyboard.** With the hardware keyboard connected, no
  keyboard shows and the amount centres in the full height. Jake leaves it off on purpose.
- The emoji keyboard shows a one-time skin-tone tip on first use, over the grid.

## Gestures and screenshots

- Hold a drag for a screenshot: a background `sleep 4; xcrun simctl io booted screenshot …`
  alongside a `touch_path` whose last points hold 1000ms each.
