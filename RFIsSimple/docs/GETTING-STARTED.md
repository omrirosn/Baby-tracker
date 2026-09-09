# Getting started

Everything from "there is code in a branch" to "the app runs on my phone and
something is checking it". Follow it in order the first time.

Nothing here has ever been compiled — it was written in a Linux container with
no Swift toolchain. Step 3 is where that gets resolved, and it is normal for it
to take a couple of rounds.

---

## Part 1 — Give it its own repo

Do this once. The code was written into a branch of the `Baby-tracker` repo,
which is not where a new product should live.

The rearranging is already done. The `rf-is-simple-root` branch of
`Baby-tracker` holds this project with the app at the top level — all four
commits, their history intact, `RFIsSimple.xcodeproj` at the root where Xcode
expects it. All that is left is to move it to a repo of its own.

### 1.1 Create the empty repo

On GitHub: **New repository** → name it `rf-is-simple` → **Private** →
**do not** tick "Add a README", ".gitignore" or "licence". It must be
completely empty, or the push in the next step will be rejected.

This is the one step that cannot be automated from here: the GitHub app
attached to a Claude Code session can read and write repositories it has been
granted, but is not permitted to create new ones — it returns
`403 Resource not accessible by integration`.

### 1.2 Move it across

```bash
git clone -b rf-is-simple-root \
    https://github.com/omrirosn/Baby-tracker.git rf-is-simple
cd rf-is-simple
git branch -m main
git remote set-url origin https://github.com/omrirosn/rf-is-simple.git
git push -u origin main
```

That is the whole migration. No subtree commands, no temporary directories.

### 1.3 Check it looks right

```bash
ls
# .gitignore  README.md  RFIsSimple/  RFIsSimple.xcodeproj/
# RFIsSimpleTests/  RFIsSimpleUITests/  Scripts/  docs/  project.yml

git log --oneline
# 4 commits, oldest "Add RF is Simple Phase 1..."
```

### 1.4 Clean up

On GitHub, delete both branches from `Baby-tracker`:
`claude/rf-simple-app-architecture-kdfu49` and `rf-is-simple-root`. The baby
tracker should not be carrying an RF app around.

---

## Part 2 — Open it

**Xcode 16 or later is required.** The project uses two things that older
Xcode does not understand: synchronized file groups (folders that add
themselves to the target, so nobody has to maintain a file list) and Swift
Testing.

```bash
open RFIsSimple.xcodeproj
```

Two settings need your details before it will run on a device — the simulator
does not care:

1. Select the **RFIsSimple** target → **Signing & Capabilities** → set your
   Team.
2. Change the bundle identifier from `com.rfissimple.RFIsSimple` to whatever
   you will actually ship under.

---

## Part 3 — The first build

```
⌘B
```

**Expect errors.** The code has never met a compiler. What to expect, roughly
in order of likelihood:

| Symptom | Almost certainly |
| --- | --- |
| "Cannot find X in scope" | A typo, or two files disagreeing on a name |
| "Type of expression is ambiguous" | A SwiftUI view body that needs its types spelled out |
| An SF Symbol renders as a blank box | A symbol name that does not exist on iOS 17 |
| "Extra argument in call" | An initialiser whose parameters I got out of order |

Work through them top to bottom — one missing name often causes twenty
downstream errors, and fixing it clears the lot.

**If there are more than a handful, stop and send them to me.** Paste the first
20 lines of the issue navigator and I will fix them. That is faster than you
doing it by hand, and it is my mistake to clean up.

---

## Part 4 — Run the tests

```
⌘U
```

This is the real checkpoint, and it matters more than the app launching.

You should see roughly **420 tests**, in nine suites. The one to watch is
`OracleConformanceTests`: 313 cases comparing every calculator against a
separate Python implementation of the same physics. If those pass, the maths in
this app is very probably right.

**If a calculation test fails, do not "fix" it by changing the expected
number.** Send me the failure. One of two things is true — the Swift is wrong,
or the reference model is wrong — and which one it is matters.

From the command line, if you prefer:

```bash
xcodebuild test -scheme RFIsSimple \
    -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Part 5 — Run it and look at it

```
⌘R
```

Then go through this list, because none of it can be verified by a test:

- [ ] All four tabs open: Home, Calculators, Reference, Saved.
- [ ] Open **Reflection Converter**. Enter VSWR `2`. You should see return loss
      **9.542 dB**, reflected power **11.11%**, mismatch loss **0.512 dB**.
- [ ] Enter VSWR `1`. Return loss should read **—** with "Infinite — a perfect
      match reflects nothing", not `inf` and not a huge number.
- [ ] Open **Power Converter**, enter `0` with dBm selected. It should say
      **1 mW**. Switch the unit selector to W — the field should become
      `0.001`, not stay at `0`.
- [ ] Search Home for `friis`. Both **Free-Space Path Loss** and **Cascaded
      Gain & Noise Figure** should appear, each labelled with its category.
- [ ] Settings (gear on Home) → Appearance → **Dark**. Walk through a few
      screens. Nothing should become unreadable.
- [ ] Settings app → Accessibility → Display & Text Size → Larger Text, drag
      it to the maximum. Return to the app. Text should wrap, not clip; the
      input rows should stack into two lines.
- [ ] Turn on Airplane Mode. Everything should still work — there is no
      network code in the app at all.
- [ ] Check the formula cards render `λ`, `Γ` and `log₁₀` properly rather than
      as empty boxes.

Anything that looks wrong here is worth telling me about, especially a number.

---

## Part 6 — The QA harness

```bash
./Scripts/qa/run-qa.sh
```

or with a specific simulator:

```bash
./Scripts/qa/run-qa.sh "iPhone 16 Pro"
```

This takes a few minutes and does four things:

1. Checks the Python reference model against 17 published values.
2. Confirms the checked-in test vectors match what that model generates.
3. Builds and runs every test, including the UI sweep.
4. Collects the lot into `.qa/`.

The UI sweep opens **every** calculator and **every** reference page in the
simulator, runs Apple's accessibility audit on each, and photographs them in
four conditions: default size, XXXL text, accessibility-XXXL text, and Dark
Mode. Those screenshots end up inside `.qa/tests.xcresult`.

Read `.qa/problems.txt` first — it is the errors and failures pulled out of the
build log.

---

## Part 7 — The QA agent

See the next section. It is a different kind of thing from everything above,
which is why it gets its own explanation.

---

## What is actually where

```
rf-is-simple/
├── RFIsSimple.xcodeproj      the project — open this
├── RFIsSimple/               the app
│   ├── App/                  entry point, tab bar, routing, theme
│   ├── Core/                 the maths — no SwiftUI anywhere in here
│   ├── Content/              all 12 calculators' metadata, all 37 reference pages
│   ├── Components/           reusable rows and cards
│   ├── Features/             one folder per tab
│   └── Models/               categories, search, saved state
├── RFIsSimpleTests/          420-ish tests, including the 313 oracle vectors
├── RFIsSimpleUITests/        the simulator sweep
├── Scripts/qa/               the reference model and the QA runner
├── .claude/agents/rf-qa.md   the QA agent
└── docs/
    ├── GETTING-STARTED.md    this file
    ├── DECISIONS.md          what was decided, and why
    └── QA-AGENT.md           how the QA layers fit together
```
