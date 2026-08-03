# Visarga Sandhi Splitting Deck

## Goal

Add a companion Anki deck that practices the **inverse** of the visarga sandhi
deck: given a combined form, recall the two words it was built from
(sandhi-splitting / *vigraha*). The forward deck teaches how a final visarga
transforms (नरः चरति → नरश् चरति); this deck teaches the reverse
(नरश् चरति → नरः + चरति). It is the visarga analog of the already-shipped
vowel-sandhi splitting deck and reuses that deck's decisions.

## Why not Anki's native reversed-card note type

Same reason as the vowel splitting deck: the forward card's `Back` field is a
rich teaching panel (combined form(s) + IAST + rule + explanation), not a bare
answer, so a native "Basic (and reversed card)" reverse would show all of that
as the prompt and spoil the exercise. A purpose-built deck with a clean prompt
(just the combined form) is the right tool.

## Scope

Visarga sandhi only. Consonant (vyañjana) sandhi is not yet carded in either
direction and is out of scope here.

## Design

A new generator that is a pure rendering transform over the **same** committed
source of truth, `data/visarga_sandhi.json` (50 records). No new data file, and
there is no visarga engine to change (visarga outcomes are curated, not derived).

### Carryover decisions (from the vowel splitting deck)

- Separate deck so the two directions study independently.
- Distinct GUID key prefix so Anki never merges the two directions on import.
- Front is the combined Devanagari only (no IAST hint).
- No on-card ambiguity note — splitting being many-to-one is self-evident, and
  real words in context usually pin the split.

### Visarga-specific decision: multiple accepted combined forms

7 of the 50 records list more than one accepted combined form (e.g.
`naraḥ + carati` → both नरश् चरति and नरः चरति). This deck emits **one card per
record**, using the **primary** form (`combined[0]`) as the prompt; any alternate
forms are shown on the back as "also accepted". Result: 50 records → **50 cards**,
1:1 with the forward deck. (Rejected alternative: one card per combined form, 57
cards — more prompts but the same split answer repeated across cards.)

### New deck constant

`lib/anki.rb`: add
`Anki::VISARGA_SANDHI_SPLIT_DECK = "🕉️ Sanskrit Visarga Sandhi (Splitting)"`,
after `VOWEL_SANDHI_SPLIT_DECK`.

### New generator — `lib/generators/visarga_sandhi_split.rb`

Class `Generators::VisargaSandhiSplit < Base`, mirroring
`Generators::VisargaSandhi`:

- `KEY = "visarga-sandhi-split"`
- `DESCRIPTION = "Visarga sandhi splitting (combined form -> the two words + rule)"`
- `OUTPUT_TXT = "sanskrit_visarga_sandhi_split_anki.txt"`
- No `OUTPUT_JSON` (reads the existing data file).
- `self.requires_letters? == false`
- `deck` overridden to `Anki::VISARGA_SANDHI_SPLIT_DECK`
- `build = VisargaSandhiDeck.load`

### Card layout (mirror of the forward card, front/back swapped)

Each record has string keys: `type`, `word1_iast`, `word1_devanagari`,
`word1_underlying_iast`, `word1_underlying_devanagari`, `word2_iast`,
`word2_devanagari`, `combined` (a list of `{iast, devanagari}`), `rule`,
`explanation`.

- **Key/GUID:** `visarga_sandhi_split:<type>:<word1_iast>+<word2_iast>`. The
  prefix MUST differ from the forward deck's `visarga_sandhi:` prefix (both files
  use `#guid column:1`). Unique per record.
- **Front:** the primary combined form in Devanagari only — big + centered:
  `<center>` + three nested `<big>` + `combined[0]["devanagari"]`.
- **Back:**
  - `<b>#{word1_devanagari} + #{word2_devanagari}</b>` (big) — the split answer
  - `#{combined[0]["iast"]} → #{word1_iast} + #{word2_iast}` (IAST)
  - `<small>(#{word1_devanagari} ← #{word1_underlying_devanagari})</small>` — the
    underlying pre-visarga form of word1, moved to the answer side so it does not
    leak on the prompt
  - alternates line, only when `combined.size > 1`:
    `<small>(also accepted: #{alternates joined by " / "})</small>` where
    alternates are `combined[1..]` Devanagari forms
  - `<b>#{rule}</b>`
  - `#{explanation}`

## Registration

Add `require_relative "lib/generators/visarga_sandhi_split"` and insert
`Generators::VisargaSandhiSplit` into the `GENERATORS` array in `main.rb`
directly after `Generators::VisargaSandhi`. The `--visarga-sandhi-split` flag,
`--all`, `--list`, and the (empty) audio flow follow automatically.

## Testing

`test/visarga_sandhi_split_deck_test.rb` (minitest). The card *data* is already
validated by `test/visarga_sandhi_deck_test.rb` (Devanagari↔IAST pairs, underlying
forms end in s/r); this test only covers the new rendering transform:

- one card per record (50)
- every key starts with `visarga_sandhi_split:` and all keys are unique
- front contains `combined[0]["devanagari"]`
- back contains `word1_devanagari`, `word2_devanagari`, and
  `word1_underlying_devanagari`
- for every record with `combined.size > 1`, the back contains each alternate
  form's Devanagari
- the generator targets `🕉️ Sanskrit Visarga Sandhi (Splitting)`

## Build artifact & docs (per CLAUDE.md)

- Regenerate the deck: `./main.rb --visarga-sandhi-split`, committing
  `sanskrit_visarga_sandhi_split_anki.txt` alongside the code in the same commit.
- Add a short "splitting (inverse) deck" subsection to CLAUDE.md at the end of the
  "### The visarga sandhi deck" section, noting it is the inverse deck, reads the
  same data file, uses the distinct `visarga_sandhi_split:` key prefix, emits one
  card per record on the primary combined form, and shows the underlying form and
  alternates on the back.

## Out of scope

- Consonant (vyañjana) sandhi splitting.
- One-card-per-combined-form generation (rejected above).
- Any change to the visarga data schema or the forward deck.
- Audio.
