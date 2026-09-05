# The QA agent

An agent that finds defects in RF is Simple, and the harness that makes it
possible for an agent to find them at all.

## The problem it solves

An agent given only "test the app" will run `xcodebuild test`, see green, and
report success. That is worth almost nothing, because the tests were written by
the same author as the code. If the author misremembered a formula, the test
enshrines the mistake.

For this app in particular, the failure that matters is **a wrong number that
nobody notices**. A crash gets reported by a user within a day. A cascaded
noise figure that is 0.4 dB optimistic gets designed into hardware.

So the harness is built to give the agent three independent things to compare
against: a second implementation of the maths, Apple's own accessibility audit,
and screenshots it can actually look at.

## Four layers

```
┌──────────────────────────────────────────────────────────────────────┐
│ Layer 4  Judgement          the agent reads screenshots, checks       │
│                             content claims, probes boundaries         │
├──────────────────────────────────────────────────────────────────────┤
│ Layer 3  UI sweep           XCUITest walks every screen, runs the     │
│                             accessibility audit, captures light /     │
│                             dark / XXXL / accessibility-XXXL          │
├──────────────────────────────────────────────────────────────────────┤
│ Layer 2  Numerical oracle   313 vectors from an independent Python    │
│                             implementation, checked in Swift          │
├──────────────────────────────────────────────────────────────────────┤
│ Layer 1  Unit tests         hand-written, spec §14 reference values   │
└──────────────────────────────────────────────────────────────────────┘
```

Each layer catches what the one below it cannot.

### Layer 1 — unit tests

`RFIsSimpleTests/`, already in the repo. Normal cases, boundaries, invalid
input, and the global reference values the specification names in §14.

**Catches:** obvious regressions.
**Misses:** anything the author got wrong twice, in the code and in the test.

### Layer 2 — the numerical oracle

`Scripts/qa/reference_model.py` implements all twelve calculators again, in
Python, deliberately formulated *differently* from the Swift:

| Calculator | Swift | Python reference |
| --- | --- | --- |
| Power | through a unit protocol with a base unit | `10**(x/10)` directly |
| Path loss | `20·log10(4πd/λ)` in SI | `20log10(d_km) + 20log10(f_MHz) + 32.4478` |
| Reflection | the VSWR ⇄ Γ identity | reflected *power* ratios |
| Cascade | one pass with a running product | explicit per-stage accumulation |
| Noise | assembled in decibels | kTB in watts, then converted |
| Wave | λ = v/f directly | via the period |

Two implementations agreeing to nine significant digits, having been written
from different starting formulations, is strong evidence both are right. The
generator emits `RFIsSimpleTests/OracleVectors.swift`, and
`OracleConformanceTests` runs all 313 cases inside the normal test suite — so
this check runs on every `⌘U`, not only when someone remembers.

The Python model self-checks first, against seventeen values taken from
published tables:

```bash
python3 Scripts/qa/reference_model.py --check
```

**Catches:** a formula wrong in the app, a unit conversion off by a factor, a
boundary handled inconsistently.
**Misses:** both implementations wrong the same way — which is why the
self-check against published values exists, and why the agent is told to derive
a disagreement a third way before believing either side.

### Layer 3 — the UI sweep

`RFIsSimpleUITests/` drives the real app in the simulator:

- `AppSweepUITests` opens **every** calculator and **every** reference page by
  walking the lists, runs `performAccessibilityAudit()` on each, and attaches a
  screenshot. The audit is Apple's own: contrast, clipped text, hit-region size,
  element detection, missing descriptions.
- `AppearanceAndTypeUITests` captures the densest four screens at default size,
  XXXL, accessibility-XXXL, and in Dark Mode — driving Dark Mode through the
  app's own setting, so the setting is exercised too.
- Search is checked for the specific behaviour the spec calls out: "friis"
  must return both free-space path loss and cascaded noise figure.

**Catches:** unlabelled controls, clipping at large type, contrast failures,
navigation that dead-ends, a screen that crashes on open.
**Misses:** anything that looks fine and is wrong. Which is layer 4.

### Layer 4 — the agent

`.claude/agents/rf-qa.md`. The agent reads the artefacts, **looks at the
screenshots**, and does what the scripts cannot:

- notices that a result is well-formatted and wrong;
- checks the numbers asserted in the reference pages against its own knowledge;
- probes boundaries the vectors do not cover;
- reads the specification and `docs/DECISIONS.md` and reports drift;
- decides which side of a disagreement is actually wrong.

It is told, explicitly, that "all tests passed" is not a QA report.

## Running it

```bash
./Scripts/qa/run-qa.sh                 # default simulator
./Scripts/qa/run-qa.sh "iPhone 16 Pro"
```

Everything lands in `.qa/` (git-ignored). Then:

```
> Use the rf-qa agent to QA the app
```

The agent runs the script if needed, reads the artefacts, exports and inspects
the screenshots, and writes `.qa/REPORT.md`.

### Making the agent available

`.claude/agents/rf-qa.md` is picked up automatically by Claude Code when the
repo is the working directory — no installation step. Confirm with `/agents`.

To run it on a schedule or in CI, the same script works headlessly; add a
workflow that runs `run-qa.sh` on a macOS runner and uploads `.qa/` as an
artifact.

## Keeping the oracle honest

The vectors are generated, not hand-maintained. After changing a calculator:

```bash
python3 Scripts/qa/reference_model.py --check          # must pass first
python3 Scripts/qa/reference_model.py --emit-swift > RFIsSimpleTests/OracleVectors.swift
```

`run-qa.sh` warns when the checked-in vectors differ from what the generator
produces, so a stale file cannot quietly weaken the check.

**The rule that makes this work: never edit the Python to match the Swift
without first deriving the correct answer independently.** The moment the
reference model is "fixed" by copying the app's behaviour, it stops being a
check and becomes an echo.

## What this does not cover

Stated plainly, so nobody assumes otherwise:

- **Real devices.** Everything runs in the simulator. Font rendering, haptics
  and performance on old hardware are not tested.
- **VoiceOver as a user experiences it.** The audit checks that elements have
  descriptions; it does not check that the resulting narration makes sense.
  Someone should navigate the app with VoiceOver on, once, before release.
- **Engineering review of the reference content.** The agent can check numbers;
  it cannot decide whether a page teaches the right thing. That needs an RF
  engineer, once, per `docs/DECISIONS.md`.
- **The specification's own correctness.** If §5.7 asks for the wrong formula,
  every layer here will happily confirm the app implements it.

## Extending it

- **A new calculator:** add it to `reference_model.py`, add vectors in
  `build_vectors()`, add a `case` in `OracleConformanceTests.compute`, and
  regenerate. The UI sweep picks it up automatically because it walks the list.
- **A new invariant:** if it can be expressed as a property over many inputs,
  it belongs in the oracle. If it can only be seen, it belongs in the sweep as
  a screenshot the agent is told to look at.
