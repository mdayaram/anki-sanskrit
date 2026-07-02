# Sandhi deck as source of truth; remove `to_devanagari`

**Date:** 2026-07-02
**Status:** Approved (design)

## Problem

`IastDevanagari.to_devanagari` (IAST → Devanagari) is a one-to-many transliteration: a homorganic nasal cluster can be written with the explicit conjunct (अहङ्कारः) or an anusvara (अहंकारः), both valid for the same IAST. It returns *one* canonical spelling with no way to know it is the intended one. We want to retire it.

An audit shows `to_devanagari` (the method) has exactly one non-disposable runtime caller — the sandhi generator (`lib/generators/sandhi.rb`, three calls). Its only other uses are the transliterator's own unit test (`fwd` helper) and the disposable `bootstrap/build_vedanta.rb`. So decoupling the sandhi deck is the last thing standing between us and deleting `to_devanagari`.

## Core constraint

The combined form's Devanagari (देव + इन्द्र → देवेन्द्र) is a *new* glyph sequence created by a vowel-junction transformation (the mātrā on व changes). It cannot be spliced from the input glyphs — producing it from IAST is exactly what `to_devanagari` does. Therefore removing `to_devanagari` necessarily means the sandhi Devanagari becomes **curated data** rather than auto-generated. This is acceptable: the deck is 38 cards, rarely extended, and `data/sandhi.json` is already committed and 100% valid under `valid_pair?`.

## Decisions

- **Architecture (B1):** `data/sandhi.json` flips from a *derived output* (regenerated from the `PAIRS` constant each run) to the **hand-maintained source of truth**. The generator becomes a pure reader (like Vedanta/Gita). The sandhi engine + `valid_pair?` move into a validating test.
- **Scope:** decouple sandhi **and** delete `to_devanagari` in this effort, including removing its unit tests (converting useful coverage to the reverse direction) and deleting the disposable `bootstrap/build_vedanta.rb`.

Alternatives considered and rejected:
- **A — curate Devanagari inline in the `PAIRS` constant** (keep the computational generator). Smaller change but keeps the deck's shape divergent from the other two data decks and bloats the constant.
- **C — engine emits Devanagari directly.** Reinvents `to_devanagari`'s mātrā/junction logic inside the engine. High complexity, no payoff.

## Components

1. **`lib/sandhi_deck.rb` (new)** — loader module mirroring `Vedanta.load`:
   `SandhiDeck.load(path = Paths.data("sandhi.json"))`, `abort`ing if the file is missing, returning the parsed array. Named `SandhiDeck` because `Sandhi` is the engine module.

2. **`lib/generators/sandhi.rb`** — remove `require`s of the engine and `iast_devanagari`; add `require_relative "../sandhi_deck"`. Remove the `PAIRS` constant and `OUTPUT_JSON` (so `Base#run` no longer overwrites the source). `build` becomes `SandhiDeck.load`. Keep `CONTEXTS`, `card`, `deck`, `requires_letters?`. Rewrite the header comment (it currently documents PAIRS/engine/`to_devanagari`).

3. **`lib/iast_devanagari.rb`** — delete the `to_devanagari` method and the now-unused `IAST_TOKENS` constant. Everything `to_iast`/`valid_pair?` needs stays: `VOWELS`/`CONSONANTS` (feed the reverse maps), `VIRAMA`/`ANUSVARA`/`VISARGA`/`AVAGRAHA`, the `DEV_*` reverse maps, `ANUSVARA_STOP_NASAL`. Rewrite the header — the module is now a Devanagari→IAST reader + pair validator only.

4. **`test/sandhi_deck_test.rb` (new)** — data-integrity test inheriting the engine's guarantees. For every entry in `data/sandhi.json`:
   - `Sandhi.join(word1_iast, word2_iast, type.to_sym)` reproduces the stored `combined_iast`, `sandhi_name`, `sandhi_devanagari`, `explanation`; a mislabeled type still raises (as `build` did today).
   - `IastDevanagari.valid_pair?` holds for `word1`, `word2`, and `combined` (IAST vs Devanagari).
   - Context invariants: every `ayadi` entry is `internal`; every `avagraha` entry is `external`.

5. **`test/sandhi_generator_test.rb`** — keep the reader-facing assertions (deck, `requires_letters?`, no audio, card front/back formatting, key format, `build` returns the entries). Move `test_all_pairs_have_valid_sandhi` (engine validation) and `test_context_matches_the_sandhi_kind` (context invariants) to #4.

6. **`test/iast_devanagari_test.rb`** — remove the `fwd` helper and forward-direction tests; convert the useful ones into reverse (`to_iast`) coverage (vowels, mātrās, clusters, visarga, word-final virama, real headwords); keep the homorganic `to_iast` and `valid_pair?` tests; replace `test_round_trip` (used `fwd`) with reverse coverage.

7. **`bootstrap/build_vedanta.rb`** — delete (its one-time job of building `vedanta.json` via `to_devanagari` is complete and committed; it references a method that will no longer exist). `bootstrap/qa_vedanta.rb` stays (uses `to_iast`).

8. **`CLAUDE.md`** — update three spots: the transliterator section (reverse + validate only; `to_devanagari` removed), the sandhi section (source of truth + pure reader + engine-in-test), and the Vedanta bootstrap note (Devanagari built once via the now-removed `to_devanagari`; `vedanta.json` is hand-maintained, validated by `test/vedanta_data_test.rb`).

## What stays unchanged

- `lib/sandhi.rb` (engine) and `test/sandhi_test.rb` — the engine still exists and is unit-tested; it is now the *validator* of the committed data rather than a generation-time step.
- `data/sandhi.json` **content** — already correct and valid; only its role changes (output → source).
- `main.rb` — the `Sandhi` generator stays registered; `KEY`/`DESCRIPTION`/`OUTPUT_TXT`/`requires_letters?` are unchanged.

## Data flow

Before: `PAIRS` (IAST) → engine + `to_devanagari` → in-memory entries → `data/sandhi.json` (written) + import `.txt`.

After: `data/sandhi.json` (source) → `SandhiDeck.load` → `card` → import `.txt`. The engine re-derives and `valid_pair?` re-checks every entry in the test suite, not at generation time.

## Testing strategy

TDD throughout. Each production change is driven by a failing test first:
- The new `sandhi_deck_test.rb` validation (fails until it exists / until `SandhiDeck.load` exists).
- Generator reader behavior (build loads from JSON; no `OUTPUT_JSON` write-back).
- `to_iast` reverse coverage that replaces the deleted forward tests.
- Deleting `to_devanagari`: the surviving suite must be green with no reference to it (`grep` gate).

Full suite (`for f in test/*_test.rb; do ruby "$f"; done`, as CI runs) must pass, and a final `grep -rn to_devanagari lib test` returns nothing.

## Consequence (accepted)

Adding a sandhi card becomes "hand-write a JSON entry" instead of "append an IAST tuple." The validating test (#4) catches any wrong derived field or invalid Devanagari, so mistakes fail loudly.
