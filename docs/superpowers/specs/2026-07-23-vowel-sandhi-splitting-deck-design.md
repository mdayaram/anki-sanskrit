# Vowel Sandhi Splitting Deck

## Goal

Add a companion Anki deck that practices the **inverse** of the existing vowel
(svara) sandhi deck: given a combined form, recall the two words it was built
from (sandhi-splitting / *vigraha*). The forward deck teaches joining
(देव + इन्द्र → देवेन्द्र); this deck teaches splitting (देवेन्द्र → देव + इन्द्र).

## Why not Anki's native reversed-card note type

Anki's "Basic (and reversed card)" note type auto-generates a Front→Back and a
Back→Front card from one note, which would avoid a second file. It is rejected
here: the forward deck's `Back` field is a rich teaching panel (combined form +
IAST + which sandhi fired + rule explanation + context), not a bare answer. A
native reverse card would show all of that as the *prompt*, spoiling the
exercise. Splitting wants a clean prompt (just the combined form) with the split
and rule as the answer — a different field layout, so a purpose-built deck is
the right tool.

Sandhi-splitting is formally many-to-one (a combined vowel can arise from several
junctions), but with real words in context the intended split is usually unique,
so each card simply teaches the one split its source record encodes. No
on-card caveat is shown — the ambiguity is self-evident to anyone studying sandhi.

## Scope

Vowel sandhi only. A visarga-sandhi splitting deck could follow the same pattern
later but is out of scope here.

## Design

A new generator that is a pure rendering transform over the **same** committed
source of truth, `data/vowel_sandhi.json`. No new data file, no engine changes.

### New deck constant

`lib/anki.rb`: add `Anki::VOWEL_SANDHI_SPLIT_DECK = "🕉️ Sanskrit Vowel Sandhi (Splitting)"`,
a separate deck so the joining and splitting directions are studied independently.

### New generator — `lib/generators/vowel_sandhi_split.rb`

Class `Generators::VowelSandhiSplit < Base`, mirroring `Generators::VowelSandhi`:

- `KEY = "vowel-sandhi-split"`
- `DESCRIPTION = "Vowel (svara) sandhi splitting (combined form -> the two words + rule)"`
- `OUTPUT_TXT = "sanskrit_vowel_sandhi_split_anki.txt"`
- No `OUTPUT_JSON` (reads the existing data file).
- `self.requires_letters? == false`
- `deck` overridden to `Anki::VOWEL_SANDHI_SPLIT_DECK`
- `build = VowelSandhiDeck.load` (same loader, same `data/vowel_sandhi.json`)

### Card layout (mirror of the forward card)

- **Key/GUID:** `vowel_sandhi_split:<type>:<word1_iast>+<word2_iast>`. The prefix
  **must** differ from the forward deck's `vowel_sandhi:` prefix. Both files use
  `#guid column:1`, so a shared key would make Anki treat the two directions as
  the same note and overwrite one on import.
- **Front:** combined Devanagari only, big + centered — e.g. देवेन्द्र
  (`<center>` + three nested `<big>` + `combined_devanagari`), matching the
  forward deck's Devanagari-only front.
- **Back:**
  - `word1_devanagari` + `word2_devanagari` (big, bold) — the answer split
  - `combined_iast → word1_iast + word2_iast` (IAST)
  - `<b>#{sandhi_name} sandhi (#{sandhi_devanagari})</b>`
  - `explanation`
  - `<small>(sandhi #{context})</small>` — reusing the same `CONTEXTS` map/wording
    as the forward generator.

### Registration

Add `require_relative "lib/generators/vowel_sandhi_split"` and insert
`Generators::VowelSandhiSplit` into the `GENERATORS` array in `main.rb` directly
after `Generators::VowelSandhi`. The `--vowel-sandhi-split` flag, `--all`,
`--list`, and the (empty) audio flow then follow automatically with no other
`main.rb` change.

## Testing

`test/vowel_sandhi_split_deck_test.rb` (minitest). The card *data* is already
validated by `test/vowel_sandhi_deck_test.rb` (derivation + Devanagari↔IAST
pairs), so this test only covers the new rendering transform:

- one card per record in `data/vowel_sandhi.json`
- every key starts with `vowel_sandhi_split:` and all keys are unique
- front and back are non-empty and front contains `combined_devanagari`
- back contains both `word1_devanagari` and `word2_devanagari`

## Build artifact & docs (per CLAUDE.md)

- Regenerate the deck: `./main.rb --vowel-sandhi-split`, committing
  `sanskrit_vowel_sandhi_split_anki.txt` alongside the code in the same commit.
- Add a short "vowel sandhi splitting deck" subsection to CLAUDE.md under the
  existing vowel-sandhi section, noting it is the inverse deck, reads the same
  data file, and uses the distinct `vowel_sandhi_split:` key prefix.

## Out of scope

- Visarga (and future consonant) sandhi splitting decks.
- Any change to the vowel-sandhi engine, data schema, or forward deck.
- Audio.
