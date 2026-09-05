# RF is Simple — Phase 1

A fast, offline RF engineering reference and calculation utility for iOS.

> The formula, the calculation, and the one thing you should not miss.

This is the Phase 1 deliverable from the initial product specification (draft
v0.1): a navigable, data-driven SwiftUI prototype with three calculators fully
implemented and the rest of the product's shape in place.

## Status

**The code has not been compiled.** It was written in a Linux container with no
Swift toolchain and no Xcode, so the first build has to happen on a Mac. What
*was* verified is listed below; treat the first `⌘B` as the real test.

| Phase 1 acceptance criterion | State |
| --- | --- |
| Builds in the current Xcode | **Unverified** — needs a Mac. Xcode 16+ required (the project uses synchronized file groups and Swift Testing). |
| Runs on iPhone in portrait | **Unverified.** Portrait is locked in the build settings. |
| All four tabs functional | Implemented. |
| Search returns calculators, reference items and aliases | Implemented, covered by `SearchIndexTests`. |
| Calculators correct, invalid input handled safely | All twelve implemented; every expected value in the tests was cross-checked against an independent calculation. |
| Light, Dark and large Dynamic Type usable | Built for it — semantic colours throughout, input rows relayout at accessibility sizes. Needs a visual pass. |
| Works in airplane mode | **Verified structurally**: the app makes no network calls. |
| No account, backend, analytics, ads or third-party dependency | **Verified**: the only imports anywhere are `Foundation`, `SwiftUI`, `UIKit`, `Observation` and `Testing`. |

## Getting started

```sh
open RFIsSimple.xcodeproj      # Xcode 16 or later
# ⌘R to run, ⌘U to test
```

Or from the command line:

```sh
xcodebuild -scheme RFIsSimple -destination 'platform=iOS Simulator,name=iPhone 15' test
```

If the project file is ever damaged by a merge, `project.yml` regenerates it:

```sh
brew install xcodegen && xcodegen generate
```

## What works

All twelve calculators from §5 of the spec are implemented:

| Calculator | Behaviour |
| --- | --- |
| **Power Converter** | dBm, dBW, W, mW, µW. 0 W reports that it has no decibel value instead of showing `-inf`. |
| **Voltage / Power / Impedance** | RMS volts ↔ watts at 50 Ω, 75 Ω or any positive impedance. Peak-to-peak and dBµV included. |
| **Frequency / Period / Wavelength** | Solve from any of the three, with an optional velocity factor. Quarter wavelength included; the propagation velocity used is always shown. |
| **Free-Space Path Loss** | From frequency and distance, with the wavelength and the λ/4π limit below which the model stops applying. |
| **Link Budget** | Transmit side, path and receive side, ending in the margin above sensitivity. |
| **Thermal Noise** | kTB in a bandwidth, the −174 dBm/Hz density, and the receiver floor when a noise figure is given. |
| **Receiver Sensitivity** | From bandwidth, noise figure and required SNR, with the equivalent noise temperature. |
| **Reflection Converter** | Solve from VSWR, return loss, \|Γ\|, reflected power or mismatch loss. Infinite quantities are shown as a dash with the reason. |
| **Cascaded Gain & Noise Figure** | A reorderable, deletable list of stages, with each stage's share of the excess noise. |
| **EIRP / ERP** | Transmit power, feed loss and antenna gain in dBi or dBd. |
| **Effective Antenna Aperture** | From frequency and gain, in m² and cm², with the equivalent dish diameter. |
| **Far-Field Distance** | Reactive, Fraunhofer and λ/2π boundaries, and the conservative distance to measure at. |

Alongside them are **37 reference pages** across all seven categories, each
following the §7 template, and a search index covering titles, aliases,
abbreviations and formula text.

## Layout

```
RFIsSimple/
  App/          App entry, four-tab shell, routing, theme
  Core/
    Calculations/  Pure functions — PowerConversion, WaveCalculator, ReflectionCalculator
    Units/         PhysicalUnit protocol, the four dimensions, MeasuredInput
    Formatting/    Locale-aware parsing, engineering-notation formatting
    Validation/    CalculationError, ValidationIssue
  Features/     Home, Calculators, Reference, Saved, Settings
  Models/       Categories, descriptors, articles, search, preferences
  Content/      The calculator catalogue and the reference library
  Components/   Reusable rows, cards, input rows, the calculator page template
  Resources/    Asset catalogue
RFIsSimpleTests/  Swift Testing suites
```

`Core` has no SwiftUI import anywhere — the calculation engine is separable
from the interface, as §13 asks.

## Two decisions worth knowing about

**Content is compiler-checked, not runtime-checked.** `CalculatorID` and
`ReferenceArticleID` are enums, and their content comes from exhaustive
`switch` statements. A missing page or a dangling cross-link is a compile
error, not a blank screen. Adding a calculator to the enum forces you to write
its descriptor and decide what its detail view does.

**Units are physical, not textual.** Every field holds a value plus a unit and
converts through an SI base unit. Changing the unit selector preserves the
physical quantity and rewrites the number, so switching GHz → MHz turns `1`
into `1000` rather than silently meaning something else.

## Tests

`⌘U` runs eight suites:

- the three calculators — normal cases, boundaries, invalid input, and
  cross-checks between every way of expressing the same mismatch;
- unit conversion and automatic scaling;
- number parsing and formatting, including locale decimal separators and
  rejection of `inf`, `nan` and hex literals;
- search, including the aliases the spec calls out by name;
- preferences, favourites and recents;
- content integrity — page lengths, alias hygiene, and the rule that every
  alias must actually find its own page.

The global reference values from §14 are all asserted: 0 dBm = 1 mW,
30 dBm = 1 W, λ = 0.2998 m at 1 GHz, −174 dBm/Hz at 290 K, and VSWR 1 ⇒ Γ = 0
with infinite return loss.

## Next

See [`docs/DECISIONS.md`](docs/DECISIONS.md) for the answers taken to the open
questions in §19, and for what Phase 2 should pick up.
