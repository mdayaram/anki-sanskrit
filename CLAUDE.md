# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bundle install                                  # install nokogiri
bundle exec ruby scrape_sanskrit.rb             # step 1: fetch site + download mp3s -> data/
bundle exec ruby generate_anki.rb               # step 2: write sanskrit_anki.txt + copy audio to Anki
bundle exec ruby generate_combinations_anki.rb  # optional: write sanskrit_combinations_anki.txt
bundle exec ruby generate_conjuncts_anki.rb     # optional: write sanskrit_conjuncts_anki.txt
```

There are no tests, linter, or build step. `generate_anki.rb` prompts interactively before copying audio. Both generators depend on `data/letters.json` existing first, so `scrape_sanskrit.rb` must run before either.

## Architecture

Pipeline producing Anki import files for the Sanskrit alphabet. `scrape_sanskrit.rb` is the only step that touches the network; both generators are pure transforms over `data/letters.json`.

1. **`scrape_sanskrit.rb`** scrapes <https://enjoylearningsanskrit.com/sanskrit-alphabet-tutor/> and downloads mp3s from `sanskritserver.kautukam.com`, writing `data/letters.json` + `data/audio/*.mp3`.
2. **`generate_anki.rb`** reads `data/letters.json`, emits `sanskrit_anki.txt` (tab-separated, with Anki import headers like `#separator:Tab`, `#deck:`, `#guid column:1`), and copies mp3s into `ANKI_MEDIA_DIR`.
3. **`generate_combinations_anki.rb`** reads `data/letters.json` and writes `data/combinations.json`, `data/anusvara_visarga.json`, and `sanskrit_combinations_anki.txt`. Cards target the **same deck** (`🕉️ Sanskrit Alphabet`) as the basic alphabet, so importing both files merges them into one deck.
4. **`generate_conjuncts_anki.rb`** reads `data/letters.json` and writes `data/conjuncts.json` + `sanskrit_conjuncts_anki.txt`. Covers the most common consonant-cluster ligatures (saṃyuktākṣara); cards target the same `🕉️ Sanskrit Alphabet` deck as the others.

### Conjuncts are computed via the virama

`generate_conjuncts_anki.rb` builds each ligature the same deterministic way as the combinations: a conjunct's Devanagari is its component consonants joined by the virama `्` (U+094D), and its IAST is each component's `roman` with the trailing inherent `a` dropped from every component *except the last* (`pa` + `ra` → `p` + `ra` = `pra`). The driving constant is `CONJUNCTS` — an ordered list of `[component_ids, frequency]` pairs where each ID is a `letters.json` consonant key. Frequencies are Ulrich Stiehl's Mahābhārata corpus rates (per-half-verse occurrence, so they don't sum to 100%); the list is the >1% subset, sorted high→low. `kSha`/`jJNa` are deliberately excluded because they already exist in `letters.json`. The component→ligature composition was validated row-for-row against the 360-conjunct table on Wikipedia's "Devanagari conjuncts" page (all 89 matched exactly), so if you add a conjunct, supply its `component_ids` and the virama join handles the glyph.

### The letter-ID spine

`scrape_sanskrit.rb` is built around `ALL_LETTERS` — an ordered list of internal IDs (`a`, `aa`, `RRi`, `kSha`, …). Four constants are keyed by that same ID: `DEVANAGARI`, `ROMAN` (IAST transliteration), `AUDIO_FILES` (remote filename), and runtime-derived `properties` / `tips`. Adding or renaming a letter means touching every map in lockstep.

`build_properties` derives grammatical metadata (Vowel/Consonant, Short/Long, Voiced/Aspirated, place of articulation) from the source page's CSS classes (`clm1`–`clm4`, `nasel`, `semi`, `sibi`, `clm8`, `short`/`long`/`guna`/`vriddhi`/`anusvara`/`visarga`) and the parent element's `id` (`place1`–`place5`, `vowels1`/`vowels2`/`amaha`). Any HTML structure change upstream will silently produce empty property lists — `extract_properties` reports counts so watch the "Found properties for N/M" line.

### Combinations are computed, not scraped

`generate_combinations_anki.rb` synthesizes consonant×vowel syllables and vowel×{anusvara,visarga} forms purely from Unicode — no source page involved. A combined glyph is `consonant["devanagari"] + matra` (matras live in `VOWEL_MATRAS`, keyed by vowel ID), and its IAST is the consonant's `roman` with its trailing `a` replaced by the vowel's `roman`. The inherent `a` vowel is deliberately omitted because bare consonants already carry it and live in the basic deck. `aM`/`aH` are excluded from the anusvara/visarga set since `letters.json` already holds अं/अः.

Watch the back-of-card breakdown logic in `components_devanagari`: standalone anusvara/visarga marks are rendered on the dotted circle U+25CC (`◌ं`, `◌ः`) because the `letters.json` forms (अं/अः) carry a spurious leading `a` that would mislead.

### Audio filename quirk

Local audio filenames mirror the **server's** filenames, not the internal IDs (e.g. `Da` → `d2a.mp3`, `ka` → `k1a.mp3`). This is intentional: macOS's case-insensitive default filesystem would otherwise collapse `Da.mp3` and `da.mp3` into one file. The Anki `[sound:...]` tag in generated cards therefore references the server filename via `letter["audio_file"]`.

### TSV formatting constraint

`generate_anki.rb` builds card HTML without inline `style="..."` attributes — semicolons inside styles collide with parsers reading the TSV as semicolon-separated. Use `<big>`, `<center>`, `<b>`, `<ul>` instead. `clean_tips_html` rewrites the source page's `coloredletter1`/`coloredletter2`/`tipsmallfont` spans to `<b>`/`<i>`/`<small>` and strips remaining spans.

### Hardcoded paths

`ANKI_MEDIA_DIR` in `generate_anki.rb:23` is hardcoded to `/Users/noj/Library/Application Support/Anki2/User 1/collection.media`. Change it if running on a different machine or Anki profile.
