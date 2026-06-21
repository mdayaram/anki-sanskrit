# Bhagavad Gita Verse Deck — Design

**Date:** 2026-06-20
**Status:** Approved (ready for implementation planning)

## Goal

Add a new Anki deck of **Bhagavad Gita verses** for reading practice. Each card
shows a verse in Devanagari on the front; the back shows the IAST
transliteration, two English translations (one literal, one devotional), and a
recitation audio clip.

This is the first of two planned sub-projects. A **word deck** (one card per
word/pada, Devanagari front, IAST + gloss back) is deferred to a later spec
because it requires an IAST→Devanagari transliteration module that does not yet
exist. The data fetch for this verse deck deliberately preserves the per-word
data so the word deck needs no re-fetch.

## Source (locked)

The **`gita/gita`** open dataset on GitHub (the data behind bhagavadgita.io),
fetched from `raw.githubusercontent.com/gita/gita/main/data/`:

- **`verse.json`** — per verse: `text` (Devanagari), `transliteration` (IAST),
  `word_meanings` (word-by-word `pada—gloss; …`), `chapter_number`,
  `verse_number`.
- **`translation.json`** — full English (and Hindi) translations keyed by
  `verse_id` + `author_id`/`authorName`. Multiple authors spanning literal →
  devotional.
- **`authors.json`** — author id → name.
- **`chapters.json`** — per-chapter `verses_count` (used to validate coverage).
- **`verse_recitation/<chapter>/<verse>.mp3`** — per-verse recitation audio.
  Verified: real MPEG audio (not Git-LFS pointers), one file per verse, same
  repo/license as the text.

**Translation pairing:**
- **Literal:** Swami Gambirananda (closely follows the Sanskrit, Shankara school).
- **Devotional:** Swami Sivananda (classic, accessible).

Both are swappable by changing two author names in `fetch_gita.rb`.

Arshabodha.org was evaluated (user preference) but offers only audio lectures and
lecture-style chapter PDFs — no scrapable word-by-word glossary — so it is not
used. (A future enhancement could link the relevant Arshabodha chapter PDF/audio
on a card as a "go deeper" reference; out of scope here.)

## Architecture

Mirrors the existing split: one standalone networked fetch script, then a pure
transform generator over local JSON.

### 1. `fetch_gita.rb` (new standalone script, sibling to `scrape_sanskrit.rb`)

- Downloads `verse.json`, `translation.json`, `authors.json`, `chapters.json`.
- Joins them and **filters translations to the two chosen English authors**.
- Downloads the 700 recitation MP3s to **`data/gita_audio/gita_<ch>_<v>.mp3`**
  (flat names, unique for Anki's flat media folder). Skips files already on disk
  (resumable; ~84 MB total). Polite sequential download like `scrape_sanskrit.rb`.
- Writes a slim **`data/gita.json`**: one record per verse:
  ```json
  {
    "chapter": 1,
    "verse": 1,
    "devanagari": "धृतराष्ट्र उवाच\n…।।1.1।।",
    "transliteration": "dhṛitarāśhtra uvācha\n…",
    "word_meanings": "dhṛitarāśhtraḥ uvācha—Dhritarashtra said; …",
    "translations": { "literal": "…", "devotional": "…" },
    "audio_file": "gita_1_1.mp3"
  }
  ```
  `word_meanings` is preserved (unused by the verse deck) so the future word deck
  needs no re-fetch.
- **Validation:** assert all 18 chapters present, per-chapter verse count matches
  `chapters.json`, every verse has both translations non-empty and an audio file
  on disk. Report counts (e.g. "Fetched 700/700 verses, 700/700 audio").
- Stays a standalone script (not a `main.rb` subcommand) — it is the only
  networked step for this deck, consistent with `scrape_sanskrit.rb`.

### 2. `lib/generators/gita_verses.rb` (new `Generators::Base` subclass)

Pure transform over `data/gita.json`.

- `KEY = "gita-verses"`, `DESCRIPTION = "Bhagavad Gita verses"`,
  `OUTPUT_TXT = "sanskrit_gita_verses_anki.txt"`,
  `OUTPUT_JSON = "gita_verses.json"`.
- `build` — loads `data/gita.json` (via a small loader; aborts with a clear
  "run fetch_gita.rb first" message if missing, mirroring `Letters.load`).
  Returns the verse records.
- `card(entry)` — returns `[key, front, back]`:
  - **key:** `gita_verse:<ch>.<v>` (stable guid → re-import updates, no dupes).
  - **front:** Devanagari `devanagari`, `\n`→`<br>`, wrapped
    `<center><big>…</big></center>` (a single `<big>`, not the alphabet's five —
    verses are long).
  - **back:** labeled blocks, no inline `style=` (TSV-safe), prose `\n`→`<br>`:
    ```
    <b>IAST:</b><br>…transliteration…<br><br>
    <b>Literal — Gambirananda:</b><br>…<br><br>
    <b>Devotional — Sivananda:</b><br>…<br><br>
    [sound:gita_1_1.mp3]
    ```
- `audio_files(data)` — returns every verse's `audio_file`. This makes
  `main.rb`'s existing data-driven copy step pick up the audio and show the
  interactive Anki-media copy prompt automatically.
- `requires_letters?` — overridden to `false` (see shared-code change 3).

Registered in `main.rb`'s `GENERATORS` array → `--gita-verses`, `--all`,
`--list` all light up automatically.

## Card format summary

- **Deck:** `🕉️ Bhagavad Gita` (separate from `🕉️ Sanskrit Alphabet`).
- **Front:** Devanagari shloka (speaker line + verse + `।।ch.v।।` marker, kept
  as-is for authenticity).
- **Back:** IAST → literal translation → devotional translation → recitation
  `[sound:…]`.
- ~700 cards, one per verse.

## Changes to shared code (small, justified)

1. **`Anki.write_deck` gains a `deck:` keyword param** (default `Anki::DECK`) and
   a new **`Anki::GITA_DECK = "🕉️ Bhagavad Gita"`** constant. The verse generator
   passes its deck. `run` in `base.rb` passes the generator's deck through (add a
   `deck` accessor defaulting to `Anki::DECK`; the verse generator overrides it).
2. **`write_deck` also flattens `\n`→space** as a defensive guard (the generator
   converts to `<br>` deliberately first; this prevents any stray newline in
   translation prose from breaking a TSV row). Currently only `\t` is flattened.
3. **`requires_letters?` class method on `Base`** (default `true`; Gita overrides
   to `false`). `main.rb` loads/requires `data/letters.json` only when a selected
   generator needs it, so a Gita-only run does not force the alphabet scrape.

## main.rb integration

- Add `require_relative "lib/generators/gita_verses"` and register the class.
- Guard the `Letters.load` call: load only if any selected generator
  `requires_letters?`; otherwise skip (pass `nil`/empty to generators that don't
  need it). Generators that don't use letters ignore the args.
- The final "Cards land in deck: …" message should reflect the deck(s) actually
  used (collect distinct deck names from the run) rather than hardcoding
  `Anki::DECK`.

## Validation & testing

- `fetch_gita.rb`: count assertions above; fail loudly on missing data.
- After generation: spot-check several cards — no raw `\n` in any field, columns
  split correctly, `[sound:…]` references a file present in `data/gita_audio/`,
  Devanagari/IAST/translations populated.
- Confirm a Gita-only run (`./main.rb --gita-verses`) works without
  `data/letters.json` present.
- Confirm importing the file into Anki creates the `🕉️ Bhagavad Gita` deck and
  audio plays after the media-copy step.

## Edge cases

- Multi-line `text` and trailing `।।ch.v।।` markers — kept as-is.
- Translation prose containing tabs/newlines — flattened/converted before write.
- A verse missing in `translation.json` for a chosen author — fetch script fails
  validation rather than emitting a half-empty card.
- Numbered verse ranges (the Gita has a few merged verses, e.g. "21–22"): handle
  whatever `verse_number`/recitation files the dataset uses; validate counts
  against `chapters.json` to catch mismatches.

## Out of scope (future sub-projects)

- **Word deck** — one card per pada, Devanagari front. Needs an IAST→Devanagari
  transliteration module (normalize the dataset's ITRANS-ish scheme → standard
  IAST → Devanagari via the project's existing matra/virama composition; validate
  by substring-matching generated words against the Devanagari verse). Separate
  spec.
- Per-chapter Anki tags, Arshabodha "go deeper" reference links.
