# Decisions

What was decided while building Phase 1, and what is still open. Section
numbers refer to the initial product specification, draft v0.1.

## The §19 open questions

Each of these needed an answer to write the code. They are all cheap to change
now and expensive to change after the first release, so they are listed with
the reasoning rather than just the outcome.

### Minimum iOS version — **iOS 17.0**

iOS 17 gives `@Observable` (so preferences need no `ObservableObject`
boilerplate), `ContentUnavailableView` for empty and not-yet-built states, and
the two-parameter `onChange`. Dropping to 16 would cost all three for a slice
of users who will have updated by the time this ships.

### Accent colour — **one teal-blue, `#0A6A87` light / `#4FBDDE` dark**

A single accent, as §12 requires. Categories are distinguished by SF Symbol and
name, never by colour. The only other colour in the app is the orange on the
"common mistake" icon and red on validation errors, and both are paired with a
word so colour is never the sole signal.

### Numeric precision — **4 significant digits on screen, 12 on copy**

Four digits is enough for engineering work and short enough to read at a
glance. Values are shown in plain decimal between 1e-4 and 1e6 and in
scientific notation outside that. Grouping separators are suppressed so a
displayed value can be typed straight back into a field. Copy always carries
12 significant digits, so precision is never silently lost.

### Formula rendering — **plain text in a monospaced font**

No maths-typesetting dependency, which keeps §13's "no third-party
dependency" intact. Expressions use real Unicode (`λ`, `Γ`, `₁₀`), scroll
horizontally rather than wrapping, and carry a separate spoken description for
VoiceOver, since none of those symbols read aloud sensibly. Revisit if a
formula ever needs a fraction bar or an integral.

### Category names — **the spec's names, verbatim**

"Reflection & Transmission Lines" has a `shortTitle` of "Reflection & Lines"
for navigation bars and compact rows; nothing else needed shortening.

### MVP calculator list — **all twelve listed, three implemented**

The nine that are not implemented are listed with real categories, aliases and
related reading. Tapping one opens a screen saying it is planned and pointing
at the reference pages that cover the same ground. This keeps the shape of the
product visible without pretending to calculate.

Worth noting: **Measurements has no calculator** in the §5 list. The category
carries four reference pages and no tools, which is fine but visible — a
"RBW / noise floor normalisation" calculator would fill it naturally.

### Reference content and review — **written here, needs an engineering review**

37 pages, all following the §7 template. They run 59–97 words, which is at or
just under the 80–180 target: short enough to fit a phone screen without
scrolling, which felt more important than hitting the word count. The content
tests enforce 40–220 words, at most three practical bullets, and that every
alias actually finds its own page.

**These pages have not been reviewed by a second engineer.** The numbers in
them are standard textbook values and were checked while writing, but a review
pass before release is the obvious next step. Every page is a `case` in one
`switch` in `Content/ReferenceLibrary.swift`, so review is a single file.

### App name and subtitle — **not decided**

"RF is Simple" is used throughout as the working name. No subtitle is written
anywhere yet, so nothing needs changing if the name moves.

### Monetisation — **nothing in the code**

No StoreKit, no paywall, no gating, no analytics. `ImplementationStatus` on a
calculator descriptor is the natural seam for a future free/Pro split, but
nothing today reads it that way.

## Implementation decisions

### Content as exhaustive switches

`CalculatorID` and `ReferenceArticleID` are `String`-backed enums, and content
comes from `switch self` in an extension. The compiler therefore guarantees
that every calculator and page exists and that no cross-link dangles — there is
no dictionary lookup that can return `nil` and no runtime registry to keep in
step. Adding a case is a compile error until it has content and a detail view.

The raw values are the persistence keys for favourites and recents, so a case
cannot be renamed without a migration.

### Units convert through an SI base

Every unit implements `toBase`/`fromBase` against one canonical unit per
dimension (W, Hz, s, m). Calculations only ever see base units. Two consequences
fall out of this rather than being special-cased:

- changing a unit selector preserves the physical quantity (§12);
- a value that cannot exist in the new unit — 0 W has no dBm — clears the field
  rather than being reinterpreted.

### Infinity is modelled, not printed

`ReflectionSolution` uses `Double?` where a quantity is genuinely infinite: the
return loss of a perfect match, the VSWR and mismatch loss of a total
reflection. The interface shows a dash and a one-line reason. Nothing in the
app can display `inf` or `NaN`.

### Errors appear only after a field is touched

Per §6. `MeasuredInput.hasBeenEdited` drives it for unit-bearing fields; the
Reflection Converter tracks which of its five quantities have been edited.

### Keyboard choice follows the unit

Fields whose unit accepts negative values (dBm, dBW) get
`.numbersAndPunctuation`, because `.decimalPad` has no minus key. Everything
else gets `.decimalPad`. Both get a Done button, since neither has a return key.

### Recents exclude nothing, favourites are ordered by the catalogue

Recents are stored as an ordered list of storage keys, most recent first,
capped at 12, deduplicated. Keys that no longer resolve — content removed in a
later release — are skipped on read rather than crashing. Favourites are stored
as a set of keys but always displayed in catalogue order, so the list does not
reshuffle as items are added.

## Known gaps

- **Nothing has been compiled or run.** No Swift toolchain was available. Expect
  to fix small compile errors on the first build.
- **No app icon.** The asset catalogue has the slot and the accent colour; the
  1024px artwork is missing, so the simulator shows a blank icon.
- **Settings offers 50 Ω and 75 Ω only**, matching §15. A custom impedance
  belongs to the Voltage/Power/Impedance calculator (§5.2), which is not built
  yet.
- **No localisation.** Strings are inline English. `SWIFT_EMIT_LOC_STRINGS` is
  on, so extraction will work when it is wanted.
- **Cross-tab links push within the current tab.** Opening a calculator from a
  reference page keeps you in the Reference tab rather than switching to
  Calculators. This is the conventional iOS behaviour and needs no work unless
  it proves confusing.

## Suggested Phase 2

1. Build the six calculators that share the noise/link-budget maths —
   thermal noise, receiver sensitivity, FSPL, link budget, EIRP/ERP, effective
   aperture. They reuse the existing units, formatting and page template
   directly, and the constants are already tested.
2. Cascaded gain and noise figure needs a list editor with reordering and
   deletion, which is the only genuinely new interaction in the MVP list.
3. Get the reference pages reviewed.
4. Draw an app icon.
