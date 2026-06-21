# Bhagavad Gita Verse Deck — Regrouping + JKYog Audio

**Date:** 2026-06-20
**Status:** Approved (ready for implementation planning)
**Supersedes:** the audio + card-granularity parts of
`2026-06-20-bhagavad-gita-verse-deck-design.md` (source, translations, pipeline
split, and generator shape are otherwise unchanged).

## Why

Two problems with the shipped verse deck:

1. **Audio is too "sing-songy."** The `gita/gita` `verse_recitation` MP3s are
   melodic chant. The JKYog (Swami Mukundananda) recitation used by
   bhagavadgita.com is clearer and higher quality (320 kbps stereo vs 32 kbps
   mono).
2. **Audio doesn't align to cards.** JKYog provides a *single* clip for verse
   groups that Mukundananda's edition combines (e.g. 1.4–6). The current deck has
   one card per raw verse, so a card for 1.4 would play the whole 4–6 recitation.

Fix: regroup the deck to match bhagavadgita.com's canonical structure (one card
per group) and switch audio to JKYog. The verse **text/translations stay sourced
from the `gita/gita` open dataset** we already have (`data/gita.json`); only the
*grouping* comes from bhagavadgita.com — and it is captured once into a hardcoded
constant, so the fetch never scrapes at runtime.

## Established facts (verified during design)

- JKYog audio base: `https://gita-audio.jkyog.org/audio/sanskrit/gita_audios/`.
  - Single verse: `{chapter:03d}_{verse:03d}.mp3` (e.g. `002_047.mp3`).
  - Grouped verses: one range file `{chapter:03d}_{start:03d}-{end:03d}.mp3`
    (e.g. `001_004-006.mp3`). The host is an S3/CDN that returns **403** (not
    404) for a non-existent key.
- Of our 701 dataset verses, **591** have a single-verse audio file (HTTP 200 on
  the naive name) and **110** are grouped (403), forming **49 groups**.
- The 49 groups were discovered by reading each grouped verse's bhagavadgita.com
  page (canonical URL + audio URL both encode the range) and validated: every
  group's members exactly equal its `start..end` range, the union of all groups
  equals exactly the 110 grouped verses, no gaps or overlaps.
- Single-verse JKYog audio numbering aligns with the `gita/gita` dataset's
  chapter/verse numbering (spot-checked through chapters 13/14/18), so naive
  names are authoritative for the 591 singles.
- bhagavadgita.com is a client-rendered Next.js app whose text comes from the
  key-gated `bhagavad-gita3` RapidAPI — itself the `gita/gita` dataset. So reusing
  `data/gita.json` for text is equivalent to the site's content; no API key is
  needed.

## The hardcoded grouping constant

`GITA_VERSE_GROUPS` — 49 `[chapter, start, end]` triples (verified list):

```
[1,4,6],[1,16,18],[1,21,22],[1,29,31],[1,32,33],[1,34,35],[1,36,37],[1,38,39],
[1,45,46],[2,42,43],[3,1,2],[3,20,21],[4,29,30],[5,8,9],[5,27,28],[6,12,13],
[6,24,25],[6,41,42],[8,1,2],[8,9,10],[8,23,26],[9,7,8],[9,16,17],[10,4,5],
[10,12,13],[10,16,17],[11,10,11],[11,26,27],[11,28,29],[11,41,42],[11,52,53],
[12,3,4],[12,6,7],[12,13,14],[12,18,19],[13,8,12],[14,3,4],[14,11,13],
[14,14,15],[14,22,23],[14,24,25],[15,3,4],[16,1,3],[16,13,15],[16,19,20],
[17,5,6],[17,26,27],[18,15,16],[18,51,53]
```

Any verse not covered by a group is its own single card. The constant drives both
card merging and the audio filename — no literal URL strings are stored; the
JKYog filename derives from the triple by the verified pattern.

## Card model

701 verses → **640 cards** (591 singles + 49 groups).

- **Single** verse 1.7 → key `gita_verse:1.7`, audio `gita_1_7.mp3`.
- **Group** 1.4–6 → key `gita_verse:1.4-6`; Devanagari = verses 4+5+6 stacked;
  transliteration stacked; literal and devotional translations each **joined**
  into one block; audio `gita_1_4-6.mp3`.

Merging all members of a group also launders the dataset's internal split noise
(its per-verse transliteration boundaries bleed across grouped verses); the
combined card is correct regardless.

Card HTML is unchanged in spirit: front = centered/large merged Devanagari
(newlines → `<br>`); back = `IAST` + `Literal — Gambirananda` + `Devotional —
Sivananda` + `[sound:…]`. TSV-safety rules (no inline `style=`, flatten
tabs/newlines) carry over.

## Data flow

`fetch_gita.rb` (standalone, networked — sibling of `scrape_sanskrit.rb`):

1. Download `gita/gita` `verse.json`, `translation.json`, `chapters.json`.
2. `GitaDataset.build` → 701 per-verse records (unchanged), each with Devanagari,
   transliteration, `word_meanings`, and the two chosen translations.
3. `GitaGroups.build(per_verse_records)` → 640 group-level card records using
   `GITA_VERSE_GROUPS`.
4. Download one JKYog MP3 per card to `data/gita_audio/<audio_file>`
   (deterministic URL: `naive_url` for singles, `range_url` for groups; skip
   files already present).
5. Write group-level `data/gita.json`.

`lib/generators/gita_verses.rb` is a pure transform over the group-level
`data/gita.json` (read via `Gita.load`), unchanged except that it reads the
already-merged fields.

### data/gita.json record (group-level)

```json
{
  "chapter": 1,
  "verse_label": "4-6",
  "verses": [4, 5, 6],
  "devanagari": "…verse 4…\n\n…verse 5…\n\n…verse 6…",
  "transliteration": "…4…\n…5…\n…6…",
  "translations": { "literal": "…4 5 6 joined…", "devotional": "…4 5 6 joined…" },
  "word_meanings": ["…v4…", "…v5…", "…v6…"],
  "audio_file": "gita_1_4-6.mp3"
}
```

`word_meanings` stays a per-verse array (aligned with `verses`) so a future word
deck still has it without re-fetching.

## Components

- **`lib/jkyog_audio.rb`** (new, pure): `BASE`; `naive_url(chapter, verse)` →
  `…/{ch:03d}_{v:03d}.mp3`; `range_url(chapter, start, end)` →
  `…/{ch:03d}_{s:03d}-{e:03d}.mp3`.
- **`lib/gita_groups.rb`** (new, pure): `GITA_VERSE_GROUPS` constant +
  `build(per_verse_records)` → group-level card records (merging Devanagari,
  transliteration, translations; collecting `word_meanings`; computing
  `verse_label` and local `audio_file`).
- **`lib/gita_dataset.rb`** — unchanged (701 per-verse records). Its `audio_file`
  output is no longer consumed (audio is decided at the group level); leave as-is
  to avoid churn, or drop that key — implementation detail for the plan.
- **`fetch_gita.rb`** — rework: add the grouping step and JKYog audio download;
  remove the old `gita/gita verse_recitation` download.
- **`lib/generators/gita_verses.rb`** — reads merged fields; key uses
  `verse_label`.
- **`lib/gita.rb`** — unchanged.

## Local audio naming

`gita_<chapter>_<verse_label>.mp3` — `gita_1_7.mp3` (single), `gita_1_4-6.mp3`
(group). One file per card; ~640 files. Old per-verse `gita_<ch>_<v>.mp3` files
are obsolete — clear `data/gita_audio/` before re-fetching so the higher-quality
JKYog audio is actually downloaded (the skip-existing guard would otherwise keep
the old files).

## Testing

- `lib/jkyog_audio.rb`: unit-test `naive_url`/`range_url` padding and the range
  form.
- `lib/gita_groups.rb`: unit-test `build` with a small fixture — a single verse
  passes through unchanged; a 3-verse group merges Devanagari/transliteration/
  translations, collects `word_meanings` as an array, sets `verse_label`
  ("4-6"), `verses` ([4,5,6]), and `audio_file` (`gita_1_4-6.mp3`); also assert
  the group count and that a known group (e.g. `[13,8,12]`) yields a 5-verse
  card. Validate `GITA_VERSE_GROUPS` has 49 entries covering 110 verses with no
  overlaps.
- `lib/generators/gita_verses.rb`: card front/back from a group fixture — key
  `gita_verse:1.4-6`, no raw newlines, `[sound:gita_1_4-6.mp3]`, both
  translations present.
- `fetch_gita.rb`: integration verification by running it — assert ~640 records
  in `data/gita.json`, ~640 MP3s in `data/gita_audio/`, a grouped file
  (`gita_1_4-6.mp3`) present and a real 320 kbps MPEG (not an LFS/error blob),
  and no per-card audio-download failures.
- Regenerate and spot-check `sanskrit_gita_verses_anki.txt`: ~640 rows, 3 columns
  each, deck header `🕉️ Bhagavad Gita`, a grouped row shows stacked Devanagari
  and the range `[sound:…]`.

## Edge cases

- Group with >2 verses (e.g. `[13,8,12]` = 5 verses; `[8,23,26]` = 4) — merge all.
- A naive single audio that unexpectedly 404/403s during fetch → report as a
  failure (don't write a partial card); should not happen given verification.
- Translation prose containing tabs/newlines — flattened/`<br>`-converted as today.

## Out of scope

- Word deck (future; `word_meanings` preserved per verse).
- Any change to the alphabet decks or shared deck/audio plumbing already added
  (`Anki.write_deck deck:`, `Media.copy_audio source_dir:`, `requires_letters?`).
