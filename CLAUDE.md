# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bundle install                          # install nokogiri
bundle exec ruby scrape_sanskrit.rb     # step 1: fetch site + download mp3s -> data/
bundle exec ruby generate_anki.rb       # step 2: write sanskrit_anki.txt + copy audio to Anki
```

There are no tests, linter, or build step. `generate_anki.rb` prompts interactively before copying audio.

## Architecture

Two-stage pipeline producing an Anki import file for the Sanskrit alphabet:

1. **`scrape_sanskrit.rb`** scrapes <https://enjoylearningsanskrit.com/sanskrit-alphabet-tutor/> and downloads mp3s from `sanskritserver.kautukam.com`, writing `data/letters.json` + `data/audio/*.mp3`.
2. **`generate_anki.rb`** reads `data/letters.json`, emits `sanskrit_anki.txt` (tab-separated, with Anki import headers like `#separator:Tab`, `#deck:`, `#guid column:1`), and copies mp3s into `ANKI_MEDIA_DIR`.

### The letter-ID spine

`scrape_sanskrit.rb` is built around `ALL_LETTERS` — an ordered list of internal IDs (`a`, `aa`, `RRi`, `kSha`, …). Four constants are keyed by that same ID: `DEVANAGARI`, `ROMAN` (IAST transliteration), `AUDIO_FILES` (remote filename), and runtime-derived `properties` / `tips`. Adding or renaming a letter means touching every map in lockstep.

`build_properties` derives grammatical metadata (Vowel/Consonant, Short/Long, Voiced/Aspirated, place of articulation) from the source page's CSS classes (`clm1`–`clm4`, `nasel`, `semi`, `sibi`, `clm8`, `short`/`long`/`guna`/`vriddhi`/`anusvara`/`visarga`) and the parent element's `id` (`place1`–`place5`, `vowels1`/`vowels2`/`amaha`). Any HTML structure change upstream will silently produce empty property lists — `extract_properties` reports counts so watch the "Found properties for N/M" line.

### Audio filename quirk

Local audio filenames mirror the **server's** filenames, not the internal IDs (e.g. `Da` → `d2a.mp3`, `ka` → `k1a.mp3`). This is intentional: macOS's case-insensitive default filesystem would otherwise collapse `Da.mp3` and `da.mp3` into one file. The Anki `[sound:...]` tag in generated cards therefore references the server filename via `letter["audio_file"]`.

### TSV formatting constraint

`generate_anki.rb` builds card HTML without inline `style="..."` attributes — semicolons inside styles collide with parsers reading the TSV as semicolon-separated. Use `<big>`, `<center>`, `<b>`, `<ul>` instead. `clean_tips_html` rewrites the source page's `coloredletter1`/`coloredletter2`/`tipsmallfont` spans to `<b>`/`<i>`/`<small>` and strips remaining spans.

### Hardcoded paths

`ANKI_MEDIA_DIR` in `generate_anki.rb:23` is hardcoded to `/Users/noj/Library/Application Support/Anki2/User 1/collection.media`. Change it if running on a different machine or Anki profile.
