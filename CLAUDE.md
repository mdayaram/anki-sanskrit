# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bundle install                        # install nokogiri (only needed for the scrape step)
bundle exec ruby scrape_sanskrit.rb   # step 1: fetch site + download mp3s -> data/
ruby fetch_gita.rb                    # step 1b: fetch Bhagavad Gita verses + recitation mp3s -> data/
./main.rb --all                       # step 2: generate every category's import file
./main.rb --basic --combinations      # generate a subset (flags combine)
./main.rb --list                      # list categories
./main.rb --help
```

Unit tests for the pure transforms and shared primitives live in `test/` (minitest, a Ruby default gem); run a file with `ruby test/<name>_test.rb`. There is no linter or build step. `main.rb` uses only the Ruby standard library; only `scrape_sanskrit.rb` needs `nokogiri` (`fetch_gita.rb` uses `open-uri`, also stdlib). Categories that emit `[sound:...]` tags (`--basic` and `--gita-verses`) prompt interactively before copying audio. The alphabet categories depend on `data/letters.json` (from `scrape_sanskrit.rb`); `--gita-verses` depends instead on `data/gita.json` (from `fetch_gita.rb`) and declares `requires_letters? == false`, so a Gita-only run needs no alphabet scrape.

## Architecture

Pipeline producing Anki import files for the Sanskrit alphabet. `scrape_sanskrit.rb` is the only step that touches the network; every category generator is a pure transform over `data/letters.json`.

1. **`scrape_sanskrit.rb`** scrapes <https://enjoylearningsanskrit.com/sanskrit-alphabet-tutor/> and downloads mp3s from `sanskritserver.kautukam.com`, writing `data/letters.json` + `data/audio/*.mp3`. It stays a standalone script — not a `main.rb` subcommand — since it is the only networked step.
2. **`main.rb`** is the single entry point for generation. It parses `--<category>` flags (or `--all`), loads `data/letters.json` once, runs each selected generator, then runs the audio-copy step if any generator referenced audio. Generators live in `lib/generators/` and share helpers in `lib/`.

### Module layout

- **`lib/paths.rb`** — filesystem locations (project root, `data/`, `data/audio/`, `letters.json`) plus `Paths.output`/`Paths.data` resolvers. `lib/` sits directly under the project root, so the root is `..` from these files.
- **`lib/letters.rb`** — `Letters.load` (reads `data/letters.json`, `abort`s with the "run scrape first" message if missing) and `Letters.by_id` (the same letters keyed by internal id). The single reader of the source data.
- **`lib/anki.rb`** — shared card primitives and the deck name constant `Anki::DECK` (`🕉️ Sanskrit Alphabet`). `Anki.glyph_front(text)` builds the centered five-deep nested-`<big>` glyph; `Anki.write_deck(path, rows)` writes the identical 6-line header + tab-separated rows (flattening stray tabs in fields to spaces); `Anki.write_json` writes the pretty-printed JSON intermediate.
- **`lib/media.rb`** — the Anki media-folder discovery and audio-copy flow (see "Anki media folder discovery" below). `Media.copy_audio(filenames)` is a no-op when the list is empty.
- **`lib/generators/base.rb`** — `Generators::Base`, the common run loop. A subclass declares constants (`KEY`, `DESCRIPTION`, `OUTPUT_TXT`, optional `OUTPUT_JSON`) and implements `build` (the entry array, also written to the JSON intermediate when `OUTPUT_JSON` is set), `card(entry)` (returns `[key, front, back]`), and optionally `audio_files(data)`. `run` writes the files and returns a summary hash for `main.rb`'s consolidated report.
- **`lib/generators/{basic,combinations,conjuncts,anusvara}.rb`** — one class per category, each holding its own domain constants. All four target the **same deck**, so importing every file merges into one deck.

Adding a category means writing one `lib/generators/<name>.rb` subclass and registering its class in the `GENERATORS` array in `main.rb`; the `--<KEY>` flag, `--all`, `--list`, and (if it emits `[sound:...]`) the audio prompt all follow automatically.

### Audio copy is data-driven

`main.rb` does not hardcode which category has audio. Each generator's `run` reports the audio filenames its cards referenced via `audio_files` (the basic alphabet returns every letter's `audio_file`; the others return `[]`). `main.rb` unions these across the run and, if non-empty, invokes `Media.copy_audio`. So if a future category gains `[sound:...]` cards, the copy prompt appears with no change to `main.rb`.

### Anusvāra cards are keyed to the following consonant

Anusvāra (ं) is realised as the nasal homorganic with the **following** sound, not the syllable it is written on, so `lib/generators/anusvara.rb` makes one card per following consonant rather than per syllable. The driving constant `ANUSVARA_RULES` groups the 33 consonants by articulation class: before a stop the mark becomes that varga's nasal (guttural→ṅ, palatal→ñ, retroflex→ṇ, dental→n, labial→m, via `:nasal_id`); before a semivowel/sibilant/`ह` there is no stop nasal so it stays a nasalised vowel (`:nasalized`). Each group carries a worked example (e.g. शंकर śaṃkara → śaṅkara). Rules were checked against Wikipedia "Anusvara" and ashtangayoga.info. The script also emits a few standalone vowel+mark recognition cards from `INDEPENDENT_MARKS` — only the three forms (ओं, आः, इं) the corpus count found attested; the rest of the independent vowel×{anusvāra,visarga} grid never occurs, so it was dropped from the combinations deck. Visarga (ः) sandhi is more complex (conditioned by the preceding vowel too) and is **not** yet carded.

### Conjuncts are computed via the virama

`lib/generators/conjuncts.rb` builds each ligature the same deterministic way as the combinations: a conjunct's Devanagari is its component consonants joined by the virama `्` (U+094D), and its IAST is each component's `roman` with the trailing inherent `a` dropped from every component *except the last* (`pa` + `ra` → `p` + `ra` = `pra`). The driving constant is `CONJUNCTS` — an ordered list of `[component_ids, frequency]` pairs where each ID is a `letters.json` consonant key. Frequencies are Ulrich Stiehl's Mahābhārata corpus rates (per-half-verse occurrence, so they don't sum to 100%); the list is the >1% subset, sorted high→low. `kSha`/`jJNa` are deliberately excluded because they already exist in `letters.json`. The component→ligature composition was validated row-for-row against the 360-conjunct table on Wikipedia's "Devanagari conjuncts" page (all 89 matched exactly), so if you add a conjunct, supply its `component_ids` and the virama join handles the glyph.

### The letter-ID spine

`scrape_sanskrit.rb` is built around `ALL_LETTERS` — an ordered list of internal IDs (`a`, `aa`, `RRi`, `kSha`, …). Four constants are keyed by that same ID: `DEVANAGARI`, `ROMAN` (IAST transliteration), `AUDIO_FILES` (remote filename), and runtime-derived `properties` / `tips`. Adding or renaming a letter means touching every map in lockstep.

`build_properties` derives grammatical metadata (Vowel/Consonant, Short/Long, Voiced/Aspirated, place of articulation) from the source page's CSS classes (`clm1`–`clm4`, `nasel`, `semi`, `sibi`, `clm8`, `short`/`long`/`guna`/`vriddhi`/`anusvara`/`visarga`) and the parent element's `id` (`place1`–`place5`, `vowels1`/`vowels2`/`amaha`). Any HTML structure change upstream will silently produce empty property lists — `extract_properties` reports counts so watch the "Found properties for N/M" line.

### Combinations are computed, not scraped

`lib/generators/combinations.rb` synthesizes consonant×vowel syllables purely from Unicode — no source page involved. A combined glyph is `consonant["devanagari"] + matra` (matras live in `VOWEL_MATRAS`, keyed by vowel ID), and its IAST is the consonant's `roman` with its trailing `a` replaced by the vowel's `roman`. The inherent `a` vowel is deliberately omitted because bare consonants already carry it and live in the basic deck. The `aM`/`aH` "vowels" are kept — they attach the anusvara/visarga sign to the inherent `a` (कं, कः); standalone vowel+mark forms instead live in `lib/generators/anusvara.rb`.

Watch the back-of-card breakdown logic in `components_devanagari`: the `aM`/`aH` marks are rendered on the dotted circle U+25CC (`◌ं`, `◌ः`) because the `letters.json` forms (अं/अः) carry a spurious leading `a` that would mislead.

Consonant×vowel combinations are pruned by corpus frequency: `COMBINATION_FREQUENCY` holds the Mahābhārata count of every consonant→vowel akṣara (same corpus/method as the conjuncts), and `build_combinations` drops any syllable below `MIN_FREQUENCY` (default 1, i.e. never attested). This cuts 112 of the 490 grid cells — almost entirely the vocalic vowels ḷ (`LLi`) and ṝ (`RRI`) and the nasals ṅ (`GNa`)/ñ (`JNa`), which never independently carry a vowel — leaving 378. Each surviving combo records its `mahabharata_count` in `combinations.json`. Raise `MIN_FREQUENCY` to prune rare syllables too. The vowel×{anusvara,visarga} set is **not** frequency-filtered.

### The Bhagavad Gita verse deck

A second deck (`🕉️ Bhagavad Gita`, the constant `Anki::GITA_DECK`) separate from the alphabet. `fetch_gita.rb` is a standalone networked script (sibling of `scrape_sanskrit.rb`) that downloads the [`gita/gita`](https://github.com/gita/gita) open dataset — `verse.json` (Devanagari `text`, IAST `transliteration`, word-by-word `word_meanings`), `translation.json` (multi-author English/Hindi), `chapters.json`. `GitaDataset.build` (`lib/gita_dataset.rb`) is the pure join/filter that selects the two configured English translations (literal = Swami Gambirananda, devotional = Swami Sivananda — change the constants at the top of `fetch_gita.rb` to swap; the script aborts if a chosen author is missing for any verse). The dataset has 701 verses (one more than the canonical 700 — an edition artifact).

Verses are then merged into **bhagavadgita.com's canonical groups** by `GitaGroups.build` (`lib/gita_groups.rb`), driven by the hardcoded `GITA_VERSE_GROUPS` — 49 `[chapter, start, end]` ranges (e.g. `[1,4,6]`) that Swami Mukundananda's edition combines, covering exactly the 110 grouped verses with no gaps/overlaps. 701 verses → **640 cards** (591 singles + 49 groups). `data/gita.json` is therefore **group-level**: each record has `chapter`, `verse_label` (`"4-6"`/`"7"`), `verses[]`, merged `devanagari`/`transliteration`/`translations`, per-verse `word_meanings[]` (kept for a future word deck), and `audio_file`. `data/gita.json` is committed like the other `data/*.json`.

Audio is the **JKYog (Swami Mukundananda) recitation** (`https://gita-audio.jkyog.org/audio/sanskrit/gita_audios/`, 320 kbps — clearer than the gita/gita `verse_recitation` files). Each card maps to one clip by a deterministic URL — `JkyogAudio.naive_url(ch,v)` (`002_047.mp3`) for singles, `JkyogAudio.range_url(ch,s,e)` (`001_004-006.mp3`) for groups (`lib/jkyog_audio.rb`) — so `fetch_gita.rb` never scrapes. MP3s download to `data/gita_audio/gita_<cc>_<vv>.mp3`, zero-padded for sane filename sorting (e.g. `gita_01_07.mp3`, `gita_01_04-06.mp3`); the local name is set by `GitaGroups` (`format("gita_%02d_%02d.mp3", …)`), distinct from the remote JKYog name. Gitignored; skipped if already present — clear the folder to re-download after a source change.

`lib/generators/gita_verses.rb` (`--gita-verses`) is a pure transform over the group-level `data/gita.json` (read via `Gita.load`, `lib/gita.rb`): key `gita_verse:<ch>.<verse_label>`, front is the merged Devanagari shloka(s), back is IAST + literal + devotional + `[sound:...]`. It overrides `deck`, `audio_dir` (→ `data/gita_audio`), and `requires_letters?` (→ false). It writes no JSON intermediate — `data/gita.json` already is one. Multi-deck/multi-audio-folder support that this added to shared code: `Anki.write_deck` takes a `deck:` kwarg, `Generators::Base` exposes `deck`/`audio_dir`/`self.requires_letters?`, `Media.copy_audio` takes a `source_dir:` kwarg, and `main.rb` loads `letters.json` only when a selected generator needs it and copies audio grouped by each generator's `audio_dir`. The generator builds card HTML by converting source newlines to `<br>` (multi-line verses/prose) — `write_deck` also flattens stray tabs/newlines defensively.

### Audio filename quirk

Local audio filenames mirror the **server's** filenames, not the internal IDs (e.g. `Da` → `d2a.mp3`, `ka` → `k1a.mp3`). This is intentional: macOS's case-insensitive default filesystem would otherwise collapse `Da.mp3` and `da.mp3` into one file. The Anki `[sound:...]` tag in generated cards therefore references the server filename via `letter["audio_file"]`.

### TSV formatting constraint

Generators build card HTML without inline `style="..."` attributes — semicolons inside styles collide with parsers reading the TSV as semicolon-separated. Use `<big>`, `<center>`, `<b>`, `<ul>` instead. `Anki.write_deck` additionally flattens any stray tab inside a field to a space so it cannot break the column split. `clean_tips_html` (private to `lib/generators/basic.rb`) rewrites the source page's `coloredletter1`/`coloredletter2`/`tipsmallfont` spans to `<b>`/`<i>`/`<small>` and strips remaining spans.

### Anki media folder discovery

`lib/media.rb`'s `find_media_dirs` probes the standard Anki base folders per platform — macOS `~/Library/Application Support/Anki2`, Windows `%APPDATA%\Anki2`, Linux `$XDG_DATA_HOME`/`~/.local/share/Anki2`, and Flatpak `~/.var/app/net.ankiweb.Anki/data/Anki2` — and globs each for `*/collection.media`, so any profile is found. `choose_media_dir` prefers Anki's default `User 1` profile when several exist. The `ANKI_MEDIA_DIR` env var overrides everything with an explicit `collection.media` path. Locations are per the [Anki manual](https://docs.ankiweb.net/files.html); update `find_media_dirs` if Anki changes them.
