# Build notes

Decisions taken while building that differ from the plans in `~/Documents/apps`.
Anything here should eventually be folded back into the plan docs.

This repo was split out of a shared workspace that also held `lockIn`. The
entries below are the ones that bear on Tideline's own code: the app, the
`patterns_*` packages, and the shared `vitals_*` packages. The lockIn-specific
half of the log stayed with lockIn.

**The `vitals_*` packages exist in both repos as copies.** There is no shared
dependency between them, so a fix to `vitals_core` or `vitals_archive` here does
not reach lockIn and has to be carried across by hand. `vitals_archive` is the
one where drift actually costs something, since it defines the backup format
that was meant to be identical across every app in the portfolio.

## Pub workspaces instead of `melos bootstrap`

`00-foundation/PHASE-0-SETUP.md` specifies melos. This repo uses **native Dart
pub workspaces** instead: the root `pubspec.yaml` lists every package under
`workspace:`, each package declares `resolution: workspace`, and one
`flutter pub get` at the root resolves them all against a single lockfile.

Why: pub workspaces are built into the SDK from Dart 3.6, and melos 7 is now a
thin task runner on top of them rather than a dependency manager. Using them
directly removes a global tool from the setup path with no loss.

Melos may still be added later purely as a task runner for `melos analyze` and
`melos test` across packages. It is not needed to build.


## Two contrast defects found in `DESIGN-SYSTEM.md`

Both found by `packages/vitals_ui/test/theme_test.dart`, which measures every
accent rather than trusting the spec. The spec has been corrected.

1. **White text on the coral and violet accents fails WCAG AA.** Section 1 said
   `onAccent` is `#FFFFFF` for those. Measured at 15px w600, which WCAG counts
   as normal text needing 4.5:1: interval red 3.27, magenta 3.25, coral 2.59.
   Ink `#0E1116` wins on twelve of the thirteen accents.
2. **`onAccent` cannot be a per-accent constant.** Stitchbook's berry is dark in
   light mode (needs white, 7.19) and light in dark mode (needs ink, 6.30), so
   the token is per-brightness. `AppAccent.onAccentFor(Brightness)` replaced the
   single `onAccent` field.


## `ThemeExtension` field-name collision

`VitalsThemeData` originally had a field named `type`. `ThemeExtension` declares
`Object get type` and uses it as the key the extension is stored under in
`ThemeData.extensions`, so the field silently overrode it: the extension was
filed under the typography instance, every `VitalsTheme.of(context)` threw, and
the code still analyzed clean. The field is now `typography`, with a regression
test asserting `theme.extensions.keys` contains `VitalsThemeData`.


## UUID v7 ordering is millisecond-granular

`DATA-PORTABILITY.md` rule 1 picks UUID keys, and v7 was chosen for index
locality. The ordering guarantee only holds **across** milliseconds: ids minted
inside the same millisecond carry random sub-millisecond bits and may sort
either way. Nothing may break a tie by id order. Rows needing a definite order
carry an explicit `sortOrder`; rows needing a time carry an explicit timestamp.


## Day keys are computed in UTC

`daysBetween` first used local `DateTime` arithmetic and returned 1 for
28 to 30 March, because that local span is 47 hours. A day key is a calendar
label rather than an instant, so `parseDayKey`, `addDays` and `daysBetween` all
work in UTC. The DST test in `day_key_test.dart` is the regression guard.


## macOS TCC blocked ~/Documents mid-session (2026-08-10)

Access to `~/Documents`, `~/Desktop` and `~/Downloads` vanished mid-build with
`Operation not permitted`, from both the shell and the editor tools, while
`$HOME` and `~/git` stayed fine. Those three are exactly the TCC-protected
folders, so it was a privacy grant rather than file permissions.

Fixed by granting the host terminal (iTerm) access under System Settings ->
Privacy & Security -> Files & Folders. Nothing was lost: the files were already
written and the suite was green before the block. Worth knowing if it recurs,
because the failure looks like disk corruption and is not.


## `vitals_archive` is pure Dart; the SAF wrappers are not in it

`DATA-PORTABILITY.md` lists SAF create/open-document wrappers as part of this
package. Those need Flutter. Keeping the package pure Dart means the whole read
path, the conflict rule, the checksum verification and the import preview are
testable without a device or an emulator, which is most of the risk. The
document-picker layer will sit above it as a thin Flutter shim, and on iOS that
same shim is `UIDocumentPicker` with no change below it.


## ZipDecoder does not throw on arbitrary bytes

It returns an empty archive. Caught by the "random bytes are not mistaken for a
backup" test: the file was correctly refused, but with `missingFile` and the
message "this backup has no manifest". For a user who picked a photo by
mistake, that reads as data loss rather than as the wrong file. `ArchiveReader`
now treats a zip containing zero files as malformed.


## Conflict resolution has a deterministic tiebreak

Last-writer-wins on `updatedAt`, tombstone wins a tie. A true tie between two
live rows with the same `updatedAt` breaks on `installId`, so two devices
merging the same pair in opposite order converge on the same answer rather than
ping-ponging forever. This matters only for merge-mode import and a future
`POST /sync`, neither of which ships in v1, but the rule has to be decided
before rows are written or the data cannot support it later.


## drift_dev is pinned below 2.34.1, and the reason is the workspace

From 2.34.1, `drift_dev` requires `analyzer ^13.0.0`. The Flutter SDK pins
`flutter_test -> test_api 0.7.11`, which caps `test` at a version needing
`analyzer <13`. A pub workspace has **one shared resolution**, so one package's
build-time dependency can break every other package's tests.

`drift_dev: '>=2.33.0 <2.34.1'` is the last version on the compatible side.
Revisit when Flutter's bundled `flutter_test` moves to analyzer 13; the runtime
`drift` dependency is unconstrained and stays current.


## `Meta` is not a usable drift table name

A table class called `Meta` fails codegen with "the referenced element, Meta, is
not understood by drift" - it collides with the annotation class in
`package:meta`. Renamed to `AppMeta` with `@DataClassName('AppMetaRow')`; the
SQL table is still `meta`, so the archive format is unaffected.

Also: in a drift table file the `library;` directive must come **before** the
imports, or the analyzer rejects the file with a message that does not mention
directive order.


## Three more name collisions worth knowing

- drift generates a data class per table, so `Treats` yields `Treat`, which
  collides with the engine's domain type. Every table with a domain twin now
  carries `@DataClassName('...Row')`. A persistence row is not a domain object
  and should not have been sharing a name anyway.
- drift exports `VerificationResult`. `vitals_archive`'s type is now
  `ImportVerification`, which is more specific regardless.
- drift exports `isNull` and `isNotNull` as query builders, which shadow the
  matchers in every test importing both. Test files use
  `import 'package:drift/drift.dart' hide isNull, isNotNull;`.


## Theme changes animate, which hides token bugs in tests

`MaterialApp` animates a `ThemeData` change, and `TallyTokens.lerp` swaps
wholesale at the halfway point rather than blending. A widget test that reads a
colour straight after `pumpWidget` therefore reads the *previous* theme's token
and every theme looks identical. `pumpAndSettle` first. Worth knowing because
the symptom - "all three themes render the same colour" - looks exactly like the
hardcoded-colour bug the test was written to catch.


## Goldens need a real font loaded or they are unreadable

`flutter test` ships a placeholder font that draws every glyph as a filled box.
That is fine for catching a moved pixel and useless for judging copy, which is
what these images are for. `golden_test.dart` loads a system TTF in `setUpAll`
and falls back silently when it is absent, so CI on another machine still gets a
valid baseline.

Emoji and Material icons still render as boxes, because the substituted font has
neither. Not worth chasing: both render correctly on a device.


## Patterns: the engine, and three decisions that had to be taken in the model (2026-08-19)

First code for app 14, and it is `packages/patterns_core` - pure Dart, no
Flutter, no plugins, the same shape as `tally_engine`. The app got rescoped two
days ago from a product that states patterns in sentences to a personal tool
that **records and displays and never concludes**, so the engine had to grow in
the opposite direction from the plan: less inference, more honesty about what a
day actually contained.

**Three things went in now because they cannot be retrofitted.**

**Many readings per day, collapsed at read time.** Appetite at 11:00 and again
at 22:00 are two facts, not a correction, so `Observation` is one row per
reading and the collapsing lives in `summariseDays`. The rule belongs to the
marker rather than to the chart, which is the part worth writing down: a dose
wants its total, bloating wants its peak, a rating wants its median. No single
default is right for two of those, and the alternative - one value per day -
would have thrown away the 22:00 reading before anyone noticed it mattered.
Because the rule is applied at read time, changing a marker from *typical* to
*peak* re-reads history rather than rewriting it.

**An unlogged day is an object, not a missing map key.** `DaySummary` exists for
every day in the range with a null value, so a chart draws an empty square and
nothing anywhere can interpolate across it. This is also why the line ban got
relaxed rather than kept: the real target was interpolation, and bars, dots and
a line that *breaks at gaps* never invent a day. `DisplayStyle` is now a
per-marker setting with a `backgroundBand` style, which is the one overlay the
app allows - a band has no scale of its own, so it cannot be stretched to agree
with the series in front of it. Two y axes in one frame stay banned.

**"None of these" is not "nothing".** `TagsValue` with an empty set is a
recorded answer and `DaySummary.explicitNone` keeps it distinct from an unlogged
day. Without that distinction every future number is computed only over the days
someone felt well enough to log, which is the exact bias that makes
self-tracking lie to the person doing it.

Two bans are mechanised rather than written down. `cycle_test.dart` greps the
package for `predict|fertile|ovulat|nextPeriod` and fails on a hit: cycle day is
derived by counting from a recorded start and an unanchored stretch past 60 days
returns null rather than "day 97". `seed_test.dart` does the same for
`streak|goalValue|targetValue|direction`, because this app holds weight,
appetite, mood and body photos, and a target field is how that set quietly
becomes a compliance app. Both tests are aimed at a reasonable-sounding change
two years from now, not at today.

Seeds are 17 ordinary markers built through the same constructor the editor
uses - no built-in flag, no privileged path - and mood among them is a plain
1-10 rather than the two-axis pad. The pad's argument was real (on one scale
*anxious* and *numb* are both a 2) but the named-feeling tags carry that split
for a fraction of the interaction cost, and a second axis can be added later as
an ordinary marker without invalidating one entry.

57 tests, analyzer clean. Next is persistence: drift schema, long table, and the
backup, before any UI - the clock on useful reports starts when logging starts,
not when the app is finished.

## Patterns: storage, and a backup that carries the photos (2026-08-19, later)

`packages/patterns_data`: drift schema v1, two repositories, and export/restore.
The engine still knows nothing about any of it, which is what keeps it running
on the Dart VM in tests.

**Six tables and one of them is the whole design.** `observations` is long, not
wide - one row per reading, `metric_id` plus a `value_json` column. Wide would
make every new marker a migration, and user-created markers are the reason the
app exists. The value is stored as the JSON its kind serialises to, with **no
numeric copy alongside it**: a second source of truth for the same number is how
a value and its projection drift apart, and reports load a date range and do the
maths in Dart anyway. At one person's volume that is a few thousand rows a year.

**Aggregation is stored, never applied at write time.** The marker row carries
`aggregation` (`sum` for a dose, `peak` for bloating, `typical` for a rating) and
`summariseDays` applies it on read. Switching bloating from peak to typical
re-reads history instead of rewriting it, which is the difference between a
setting and a one-way door.

**Seed ids had to become uuids.** The first pass used slugs - `mood`, `creatine`
- and drift refused them, correctly: rule 1 says every portable row carries a
36-character uuid, because two devices minting the same id cannot ever be
merged. They are now hand-written constants in `seedIds` / `seedOptionIds`,
greppable, with the slug as the map key. Deriving them from a hash would have
been cleverer and unreadable at the moment someone needs to check whether two
installs agree.

**Deleting a marker leaves its readings alone.** A tap must not take a year of
numbers with it, and an orphaned reading is recoverable where a deleted one is
not. The editor offers archiving first, and archived markers still come back
from `all()` because reports draw the months they were live.

**Photos are inside the archive.** The shipped-product plan kept them out to
keep the file small, which is right for a stranger with a 2GB library and wrong
here: this is a personal backup, the photos are data, and a backup that silently
omits half of what you would cry over is not a backup. `RestoreReport` counts
what did not come back by file name, because discovering it in March is the
failure this is guarding against. A photo row whose file is missing is still
restored - the day keeps its evidence that a photo existed, and the caption
survives.

Photos are written **after** the transaction commits. A half-written file on
disk is recoverable and the next export reports it; a half-written database is
not.

The tamper test needed rewriting almost immediately. Flipping a random byte in
the zip passed alone and failed in the suite, because whether it lands somewhere
that matters depends on the compressed stream. It now decodes the archive, edits
one row, re-encodes with the original checksums, and expects a refusal - which
is also what a truncated sync or a helpful cloud "repair" actually looks like.

One additive change to a shared package: `ArchiveContents` now carries media
bytes as well as media paths, so a restore can write photos back. `tally_data`
and `vitals_archive` suites both stay green.

patterns_core 58 tests, patterns_data 29, analyzer clean across the workspace.
Next: the logging UI, then this goes on the phone. Reports come after data
exists, not before.

## Patterns: the app runs, and the home screen refuses to grade you (2026-08-19, last)

`apps/patterns` exists, builds a debug apk, and does the only thing that matters
this early: it records. Six widget tests, analyzer clean.

**Home is a list, not a grid.** The rescope moved the day grid out of the home
slot and put the marker list there - what I track, a tick where today has a
reading, a dash where it does not, and a count only when a day holds more than
one. Two of the widget tests exist to keep it that way: one asserts the tick and
dash render, and one asserts the screen contains no `%`, no streak wording and
no `0/` fraction anywhere. That second test looks paranoid and is not: every
tracker that ends up shaming its user got there one reasonable widget at a time,
and this app holds weight, appetite, mood and body photos.

**One marker per sheet, two taps.** No runner walking through eight questions,
because the app never decides what a day needs - the list is the menu and
anything can be left alone. The rating sheet opens **in the middle of the
scale**, not at the bottom: a slider parked on 1 suggests an answer, and the
first drag then reads as an improvement on nothing.

**"Nista od ovoga" is a button, not an empty form.** It writes an empty tag set,
which is a recorded answer. The alternative is a day that looks identical to one
never filled in, and everything computed later would then only see the days I
felt well enough to log.

**Day detail is where the *why* lives.** Tap through from home and get every
reading with its local time, the diary in full, and retro-filled entries marked
as such. This screen is why reports can stay clean: nothing has to be crammed
into a row of squares.

One additive change to the shared design system: a fourteenth accent,
`patternsCobalt` `#5B8DEF`. The icon's pale blue-lavender was the obvious pick
and fails 4.5:1 against ink, so it went a shade deeper - an accent that cannot
carry button text is decoration. `theme_test.dart` re-measures it with the other
thirteen and the count assertion moved to 14.

Not built yet, in the order they will be missed: photo capture (the marker and
its storage exist, only the shutter is missing), the metric editor, the evening
reminder, and the report builder. Reports come last on purpose - they need
months of readings, and the clock on those starts the day this goes on the
phone.

## Patterns: photos, and the two clocks in a widget test (2026-08-19, last of the day)

Capture works end to end. `PhotoRepository` in `patterns_data`, `PhotoStore` in
the app, a strip of thumbnails on the day screen, a viewer with a caption field,
and a free-photo button that belongs to the day rather than to any marker.
13 app tests, 34 in `patterns_data`, analyzer clean, apk builds.

**Storage is decided at capture and cannot be deferred.** 1440px long edge at
q80, plus a 160px thumbnail, and the original is never kept. A raw phone photo
is around 4MB and daily for a year is 1.5GB, which is an app people uninstall to
reclaim space - and quality never stored cannot be recovered, while a library
the user already holds cannot be shrunk later without a migration over all of
it. A test decodes what was written and asserts both edges, so a well-meaning
"keep the original too" has to argue with it.

**No count cap. A size budget, and the app never deletes a photo on its own.**
`bytesOnDisk` walks the directory rather than summing the table, so a file left
behind by an interrupted delete is visible instead of invisible.

**A photo belongs to a marker or to the day.** Marker photos also write an
observation pointing at the photo row - in that order, so a crash between the
two leaves an orphaned photo, which is visible and recoverable, rather than an
observation pointing at nothing, which is neither. Free photos ("ovo je poslije
treninga") write no observation at all.

A missing file renders as its caption on a grey tile rather than a broken image
icon. That state is real after a restore where the photos did not come back, and
it should look like an explanation rather than a bug.

**The day cost that mattered: `testWidgets` runs a fake clock, and real file IO
never completes against one.** Two tests sat there until the ten-minute timeout
killed them. `runAsync` is the escape hatch, but pumping inside it is forbidden,
so a capture - pick, resize, two file writes, two inserts - has to *alternate*:
`runAsync` for the real IO, then `pump` to deliver the continuation back into
the fake zone, several times over. One round is not enough and looks exactly
like a hang. Written into the test file as a comment, because the next photo
test will hit it too.

The resize itself is behind `PhotoStore.useIsolate`, true on device and false in
tests: spawning an isolate from `flutter test` is slow enough to read as a hang
as well, and the thing under test is the resize, not where it ran.

Next: the metric editor, so new markers stop needing a code change.

