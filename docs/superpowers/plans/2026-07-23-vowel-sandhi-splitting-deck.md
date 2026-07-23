# Vowel Sandhi Splitting Deck Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a companion Anki deck that practices the inverse of the vowel-sandhi deck — given a combined form, recall the two words it split from.

**Architecture:** A new `Generators::VowelSandhiSplit` subclass that is a pure rendering transform over the existing committed `data/vowel_sandhi.json` (no new data file, no engine change). It mirrors `Generators::VowelSandhi` but swaps front/back: front is the combined Devanagari, back is the split plus the same rule/context teaching info. It targets a new, separate deck and uses a distinct GUID key prefix so it never collides with the forward deck on import.

**Tech Stack:** Ruby standard library only; minitest for tests. No new dependencies.

## Global Constraints

- Ruby standard library only in `main.rb`/`lib/` — no gems (verbatim from repo convention).
- Card HTML must avoid inline `style="..."` attributes — use `<big>`, `<center>`, `<b>`, `<small>` (TSV formatting constraint).
- Generated `sanskrit_*_anki.txt` deck files are committed build artifacts: regenerate and commit the `.txt` in the same commit as any data/generator change.
- New deck name (verbatim): `🕉️ Sanskrit Vowel Sandhi (Splitting)`.
- New GUID key prefix (verbatim): `vowel_sandhi_split:` — MUST differ from the forward deck's `vowel_sandhi:` prefix.
- `data/vowel_sandhi.json` currently has 43 records → 43 cards.

---

### Task 1: The split generator + deck constant, test-driven

**Files:**
- Modify: `lib/anki.rb` (add deck constant after `VISARGA_SANDHI_DECK`, ~line 27)
- Create: `lib/generators/vowel_sandhi_split.rb`
- Test: `test/vowel_sandhi_split_deck_test.rb`

**Interfaces:**
- Consumes: `VowelSandhiDeck.load` → `Array<Hash>` (each record has string keys `word1_iast`, `word2_iast`, `word1_devanagari`, `word2_devanagari`, `combined_iast`, `combined_devanagari`, `type`, `context`, `sandhi_name`, `sandhi_devanagari`, `explanation`). `Generators::Base#initialize(letters, letters_by_id)`.
- Produces: `Generators::VowelSandhiSplit` with `KEY = "vowel-sandhi-split"`, instance methods `build` → the loaded records and `card(entry)` → `[key, front, back]`; `Anki::VOWEL_SANDHI_SPLIT_DECK` constant.

- [ ] **Step 1: Write the failing test**

Create `test/vowel_sandhi_split_deck_test.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/vowel_sandhi_split"
require_relative "../lib/vowel_sandhi_deck"

# Rendering check on the vowel-sandhi splitting generator. The card DATA is
# already validated by test/vowel_sandhi_deck_test.rb; this only covers the
# inverse rendering transform (front = combined form, back = the split + rule).
class VowelSandhiSplitDeckTest < Minitest::Test
  def gen     = @gen     ||= Generators::VowelSandhiSplit.new([], {})
  def entries = @entries ||= VowelSandhiDeck.load
  def cards   = @cards   ||= gen.build.map { |e| gen.card(e) }

  def test_one_card_per_record
    assert_equal entries.size, cards.size
  end

  def test_keys_unique_and_prefixed
    keys = cards.map { |k, _f, _b| k }
    assert keys.all? { |k| k.start_with?("vowel_sandhi_split:") }, "every key uses the split prefix"
    assert_equal keys.size, keys.uniq.size, "keys are unique"
  end

  def test_front_prompts_with_combined_and_back_reveals_split
    gen.build.zip(cards).each do |e, (_key, front, back)|
      assert front.include?(e["combined_devanagari"]), "front shows the combined form"
      assert back.include?(e["word1_devanagari"]),     "back shows word1"
      assert back.include?(e["word2_devanagari"]),     "back shows word2"
      assert back.include?(e["combined_iast"]),        "back shows the combined IAST"
    end
  end

  def test_targets_the_split_deck
    assert_equal "🕉️ Sanskrit Vowel Sandhi (Splitting)", gen.deck
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `ruby test/vowel_sandhi_split_deck_test.rb`
Expected: FAIL — `cannot load such file -- .../lib/generators/vowel_sandhi_split` (file not created yet).

- [ ] **Step 3: Add the deck constant**

In `lib/anki.rb`, after the `VISARGA_SANDHI_DECK` constant (currently ~line 27), add:

```ruby
  # The inverse of the vowel-sandhi deck: practice splitting a combined form
  # back into its two words (vigraha). Separate deck so joining and splitting
  # are studied independently.
  VOWEL_SANDHI_SPLIT_DECK = "🕉️ Sanskrit Vowel Sandhi (Splitting)"
```

- [ ] **Step 4: Write the generator**

Create `lib/generators/vowel_sandhi_split.rb`:

```ruby
# frozen_string_literal: true

require_relative "base"
require_relative "vowel_sandhi"
require_relative "../vowel_sandhi_deck"

module Generators
  # Inverse of the vowel (svara) sandhi deck: given a combined form, recall the
  # two words it split from (vigraha). Pure rendering transform over the SAME
  # committed data/vowel_sandhi.json the forward deck reads — no new data file,
  # no engine change. It just mirrors the card: the combined Devanagari becomes
  # the prompt and the split + rule become the answer.
  #
  #   Front: the combined form in Devanagari (देवेन्द्र)
  #   Back:  the two words (देव + इन्द्र), the IAST (devendra → deva + indra),
  #          which sandhi fired, the rule explanation, and the CONTEXT.
  # No audio.
  #
  # Keyed with the distinct `vowel_sandhi_split:` prefix so Anki treats these as
  # separate notes from the forward deck (both files use #guid column:1); a shared
  # key would make the two directions overwrite each other on import.
  class VowelSandhiSplit < Base
    KEY         = "vowel-sandhi-split"
    DESCRIPTION = "Vowel (svara) sandhi splitting (combined form -> the two words + rule)"
    OUTPUT_TXT  = "sanskrit_vowel_sandhi_split_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::VOWEL_SANDHI_SPLIT_DECK

    def build = VowelSandhiDeck.load

    def card(entry)
      key     = "vowel_sandhi_split:#{entry['type']}:#{entry['word1_iast']}+#{entry['word2_iast']}"
      context = VowelSandhi::CONTEXTS.fetch(entry["context"].to_sym)
      front   = "<center>#{'<big>' * 3}#{entry['combined_devanagari']}#{'</big>' * 3}</center>"
      back    = "<center>#{'<big>' * 2}<b>#{entry['word1_devanagari']} + #{entry['word2_devanagari']}</b>#{'</big>' * 2}" \
                "<br><big>#{entry['combined_iast']} → #{entry['word1_iast']} + #{entry['word2_iast']}</big>" \
                "<br><br><b>#{entry['sandhi_name']} sandhi (#{entry['sandhi_devanagari']})</b>" \
                "<br>#{entry['explanation']}" \
                "<br><small>(sandhi #{context})</small></center>"
      [key, front, back]
    end
  end
end
```

Note: this reuses `Generators::VowelSandhi::CONTEXTS` (the `external`/`compound`/`internal` → wording map) rather than redefining it, so the context line reads identically to the forward deck.

- [ ] **Step 5: Run test to verify it passes**

Run: `ruby test/vowel_sandhi_split_deck_test.rb`
Expected: PASS — 4 runs, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add lib/anki.rb lib/generators/vowel_sandhi_split.rb test/vowel_sandhi_split_deck_test.rb
git commit -m "Add vowel sandhi splitting generator (inverse deck)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Register the generator and regenerate the deck file

**Files:**
- Modify: `main.rb` (add `require_relative` ~line 28 and array entry ~line 39)
- Create (build artifact): `sanskrit_vowel_sandhi_split_anki.txt`

**Interfaces:**
- Consumes: `Generators::VowelSandhiSplit` from Task 1.
- Produces: `--vowel-sandhi-split` CLI flag and the committed deck file.

- [ ] **Step 1: Add the require**

In `main.rb`, after `require_relative "lib/generators/vowel_sandhi"` (~line 28), add:

```ruby
require_relative "lib/generators/vowel_sandhi_split"
```

- [ ] **Step 2: Register in the GENERATORS array**

In `main.rb`, in the `GENERATORS` array, add `Generators::VowelSandhiSplit` immediately after `Generators::VowelSandhi`:

```ruby
  Generators::VowelSandhi,
  Generators::VowelSandhiSplit,
  Generators::VisargaSandhi
```

- [ ] **Step 3: Verify the flag is wired up**

Run: `./main.rb --list`
Expected: output includes a line `--vowel-sandhi-split Vowel (svara) sandhi splitting (combined form -> the two words + rule)`.

- [ ] **Step 4: Generate the deck file**

Run: `./main.rb --vowel-sandhi-split`
Expected: `43 cards -> sanskrit_vowel_sandhi_split_anki.txt`, and the final line reports deck `🕉️ Sanskrit Vowel Sandhi (Splitting)`.

- [ ] **Step 5: Sanity-check the generated file**

Run: `head -6 sanskrit_vowel_sandhi_split_anki.txt`
Expected: 6-line header with `#deck:🕉️ Sanskrit Vowel Sandhi (Splitting)`, `#notetype:Basic`, `#guid column:1`. Spot-check one data row begins with `vowel_sandhi_split:`.

- [ ] **Step 6: Commit**

```bash
git add main.rb sanskrit_vowel_sandhi_split_anki.txt
git commit -m "Register vowel-sandhi-split generator and generate deck

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Document the deck in CLAUDE.md

**Files:**
- Modify: `CLAUDE.md` (append a subsection at the end of "### The vowel sandhi deck")

**Interfaces:**
- Consumes: nothing at runtime — documentation only.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add the subsection**

In `CLAUDE.md`, at the end of the "### The vowel sandhi deck" section (immediately before "### The visarga sandhi deck"), add:

```markdown
**The splitting (inverse) deck.** A companion deck (`🕉️ Sanskrit Vowel Sandhi (Splitting)`, `Anki::VOWEL_SANDHI_SPLIT_DECK`) practises the reverse skill — *vigraha*, splitting a combined form back into its two words. `lib/generators/vowel_sandhi_split.rb` (class `Generators::VowelSandhiSplit`, `--vowel-sandhi-split`) is a pure rendering transform over the **same** `data/vowel_sandhi.json` (no new data file, no engine change): front is the combined Devanagari (देवेन्द्र), back is the split (देव + इन्द्र) plus the same IAST/rule/context info as the forward card, reusing `Generators::VowelSandhi::CONTEXTS`. It is a **separate deck** so the two directions study independently, and its cards are keyed with the distinct `vowel_sandhi_split:` prefix — both decks use `#guid column:1`, so a shared key would make Anki treat the two directions as one note and overwrite on import. This deck is not carded via Anki's native "Basic (and reversed card)" note type because the forward card's back is a rich teaching panel, which would spoil the prompt on a native reverse. `requires_letters? == false`, no audio, no JSON intermediate. Validated by `test/vowel_sandhi_split_deck_test.rb` (the card data itself is already validated by `test/vowel_sandhi_deck_test.rb`).
```

- [ ] **Step 2: Run the full test suite as a final check**

Run: `for f in test/*_test.rb; do ruby "$f" || break; done`
Expected: every file passes (0 failures, 0 errors).

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "Document vowel sandhi splitting deck in CLAUDE.md

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage:**
- New deck constant → Task 1 Step 3. ✓
- New generator reading same data, mirrored card, distinct key prefix → Task 1 Step 4. ✓
- Front = combined Devanagari only; back = split + IAST + rule + context → Task 1 Step 4 + test Step 1. ✓
- Registration in main.rb (require + array) → Task 2 Steps 1–2. ✓
- Light rendering test (count, unique/prefixed keys, front/back content) → Task 1 Step 1. ✓
- Regenerate + commit `.txt` build artifact → Task 2 Steps 4–6. ✓
- CLAUDE.md subsection + native-note-type rationale → Task 3 Step 1. ✓
- Out of scope (visarga, engine/schema changes, audio) → not touched. ✓

**Placeholder scan:** none — all code and commands are concrete.

**Type consistency:** `KEY`/`DESCRIPTION`/`OUTPUT_TXT`, `Anki::VOWEL_SANDHI_SPLIT_DECK`, `vowel_sandhi_split:` prefix, and `VowelSandhi::CONTEXTS` are used identically across tasks and match the record's string keys from `VowelSandhiDeck.load`.
