# Visarga Sandhi Splitting Deck Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a companion Anki deck that practices the inverse of the visarga-sandhi deck — given a combined form, recall the two words it split from.

**Architecture:** A new `Generators::VisargaSandhiSplit` subclass that is a pure rendering transform over the existing committed `data/visarga_sandhi.json` (no new data file, no engine — visarga is curated, not derived). It mirrors `Generators::VisargaSandhi` but swaps front/back: front is the primary combined Devanagari form, back is the split plus the underlying pre-visarga form, any alternate combined forms, and the rule. It targets a new, separate deck with a distinct GUID key prefix.

**Tech Stack:** Ruby standard library only; minitest for tests. No new dependencies.

## Global Constraints

- Ruby standard library only in `main.rb`/`lib/` — no gems.
- Card HTML must avoid inline `style="..."` attributes — use `<big>`, `<center>`, `<b>`, `<small>` (TSV formatting constraint).
- Generated `sanskrit_*_anki.txt` deck files are committed build artifacts: regenerate and commit the `.txt` in the same commit as any data/generator change.
- New deck name (verbatim): `🕉️ Sanskrit Visarga Sandhi (Splitting)`.
- New GUID key prefix (verbatim): `visarga_sandhi_split:` — MUST differ from the forward deck's `visarga_sandhi:` prefix.
- One card per record, using the primary combined form (`combined[0]`) as the prompt.
- `data/visarga_sandhi.json` currently has 50 records → 50 cards; 7 records have `combined.size > 1`.

---

### Task 1: The split generator + deck constant, test-driven

**Files:**
- Modify: `lib/anki.rb` (add deck constant after `VOWEL_SANDHI_SPLIT_DECK`)
- Create: `lib/generators/visarga_sandhi_split.rb`
- Test: `test/visarga_sandhi_split_deck_test.rb`

**Interfaces:**
- Consumes: `VisargaSandhiDeck.load` → `Array<Hash>` (each record has string keys `type`, `word1_iast`, `word1_devanagari`, `word1_underlying_iast`, `word1_underlying_devanagari`, `word2_iast`, `word2_devanagari`, `combined` (a list of `{"iast" => ..., "devanagari" => ...}`), `rule`, `explanation`). `Generators::Base#initialize(letters, letters_by_id)`.
- Produces: `Generators::VisargaSandhiSplit` with `KEY = "visarga-sandhi-split"`, instance methods `build` → the loaded records and `card(entry)` → `[key, front, back]`; `Anki::VISARGA_SANDHI_SPLIT_DECK` constant.

- [ ] **Step 1: Write the failing test**

Create `test/visarga_sandhi_split_deck_test.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/visarga_sandhi_split"
require_relative "../lib/visarga_sandhi_deck"

# Rendering check on the visarga-sandhi splitting generator. The card DATA is
# already validated by test/visarga_sandhi_deck_test.rb; this only covers the
# inverse rendering transform (front = primary combined form, back = the split +
# underlying form + alternates + rule).
class VisargaSandhiSplitDeckTest < Minitest::Test
  def gen     = @gen     ||= Generators::VisargaSandhiSplit.new([], {})
  def entries = @entries ||= VisargaSandhiDeck.load
  def cards   = @cards   ||= gen.build.map { |e| gen.card(e) }

  def test_one_card_per_record
    assert_equal entries.size, cards.size
  end

  def test_keys_unique_and_prefixed
    keys = cards.map { |k, _f, _b| k }
    assert keys.all? { |k| k.start_with?("visarga_sandhi_split:") }, "every key uses the split prefix"
    assert_equal keys.size, keys.uniq.size, "keys are unique"
  end

  def test_front_prompts_with_primary_combined_form
    gen.build.zip(cards).each do |e, (_key, front, _back)|
      assert front.include?(e["combined"].first["devanagari"]), "front shows the primary combined form"
    end
  end

  def test_back_reveals_split_and_underlying
    gen.build.zip(cards).each do |e, (_key, _front, back)|
      assert back.include?(e["word1_devanagari"]),            "back shows word1"
      assert back.include?(e["word2_devanagari"]),            "back shows word2"
      assert back.include?(e["word1_underlying_devanagari"]), "back shows the underlying form"
    end
  end

  def test_back_shows_alternate_forms_when_present
    multi = gen.build.zip(cards).select { |e, _c| e["combined"].size > 1 }
    refute_empty multi, "fixture should contain multi-form records"
    multi.each do |e, (_key, _front, back)|
      e["combined"].drop(1).each do |alt|
        assert back.include?(alt["devanagari"]), "back shows alternate form #{alt['devanagari']}"
      end
    end
  end

  def test_targets_the_split_deck
    assert_equal "🕉️ Sanskrit Visarga Sandhi (Splitting)", gen.deck
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `ruby test/visarga_sandhi_split_deck_test.rb`
Expected: FAIL — `cannot load such file -- .../lib/generators/visarga_sandhi_split` (file not created yet).

- [ ] **Step 3: Add the deck constant**

In `lib/anki.rb`, immediately after the `VOWEL_SANDHI_SPLIT_DECK` constant, add:

```ruby
  # The inverse of the visarga-sandhi deck: practice splitting a combined form
  # back into its two words (vigraha). Separate deck, like the vowel splitting deck.
  VISARGA_SANDHI_SPLIT_DECK = "🕉️ Sanskrit Visarga Sandhi (Splitting)"
```

- [ ] **Step 4: Write the generator**

Create `lib/generators/visarga_sandhi_split.rb`:

```ruby
# frozen_string_literal: true

require_relative "base"
require_relative "../visarga_sandhi_deck"

module Generators
  # Inverse of the visarga sandhi deck: given a combined form, recall the two
  # words it split from (vigraha). Pure rendering transform over the SAME committed
  # data/visarga_sandhi.json the forward deck reads — no new data file, no engine
  # (visarga is curated, not derived). It mirrors the forward card: the combined
  # Devanagari becomes the prompt and the split + rule become the answer.
  #
  #   Front: the primary combined form in Devanagari (नरश् चरति)
  #   Back:  the two words (नरः + चरति), the IAST (naraś carati → naraḥ + carati),
  #          word1's underlying pre-visarga form (नरः ← नरस्), any alternate
  #          accepted forms, which rule fired, and the rule explanation.
  # No audio.
  #
  # A record can list more than one accepted combined form; this deck emits ONE
  # card per record on the primary form (combined[0]) and shows the alternates on
  # the back. Keyed with the distinct `visarga_sandhi_split:` prefix so Anki treats
  # these as separate notes from the forward deck (both use #guid column:1); a
  # shared key would make the two directions overwrite each other on import.
  class VisargaSandhiSplit < Base
    KEY         = "visarga-sandhi-split"
    DESCRIPTION = "Visarga sandhi splitting (combined form -> the two words + rule)"
    OUTPUT_TXT  = "sanskrit_visarga_sandhi_split_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::VISARGA_SANDHI_SPLIT_DECK

    def build = VisargaSandhiDeck.load

    def card(entry)
      key     = "visarga_sandhi_split:#{entry['type']}:#{entry['word1_iast']}+#{entry['word2_iast']}"
      primary = entry["combined"].first
      front   = "<center>#{'<big>' * 3}#{primary['devanagari']}#{'</big>' * 3}</center>"

      back = +"<center>#{'<big>' * 2}<b>#{entry['word1_devanagari']} + #{entry['word2_devanagari']}</b>#{'</big>' * 2}" \
              "<br><big>#{primary['iast']} → #{entry['word1_iast']} + #{entry['word2_iast']}</big>" \
              "<br><small>(#{entry['word1_devanagari']} ← #{entry['word1_underlying_devanagari']})</small>"

      alternates = entry["combined"].drop(1)
      unless alternates.empty?
        back << "<br><small>(also accepted: #{alternates.map { |a| a['devanagari'] }.join(' / ')})</small>"
      end

      back << "<br><br><b>#{entry['rule']}</b>" \
              "<br>#{entry['explanation']}</center>"

      [key, front, back]
    end
  end
end
```

- [ ] **Step 5: Run test to verify it passes**

Run: `ruby test/visarga_sandhi_split_deck_test.rb`
Expected: PASS — 6 runs, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add lib/anki.rb lib/generators/visarga_sandhi_split.rb test/visarga_sandhi_split_deck_test.rb
git commit -m "Add visarga sandhi splitting generator (inverse deck)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Register the generator and regenerate the deck file

**Files:**
- Modify: `main.rb` (add `require_relative` after the visarga require, and an array entry after `Generators::VisargaSandhi`)
- Create (build artifact): `sanskrit_visarga_sandhi_split_anki.txt`

**Interfaces:**
- Consumes: `Generators::VisargaSandhiSplit` from Task 1.
- Produces: `--visarga-sandhi-split` CLI flag and the committed deck file.

- [ ] **Step 1: Add the require**

In `main.rb`, after `require_relative "lib/generators/visarga_sandhi"`, add:

```ruby
require_relative "lib/generators/visarga_sandhi_split"
```

- [ ] **Step 2: Register in the GENERATORS array**

In `main.rb`, in the `GENERATORS` array, add `Generators::VisargaSandhiSplit` immediately after `Generators::VisargaSandhi` (currently the last entry):

```ruby
  Generators::VisargaSandhi,
  Generators::VisargaSandhiSplit
].freeze
```

- [ ] **Step 3: Verify the flag is wired up**

Run: `./main.rb --list`
Expected: output includes a line `--visarga-sandhi-split Visarga sandhi splitting (combined form -> the two words + rule)`.

- [ ] **Step 4: Generate the deck file**

Run: `./main.rb --visarga-sandhi-split`
Expected: `50 cards -> sanskrit_visarga_sandhi_split_anki.txt`, and the final line reports deck `🕉️ Sanskrit Visarga Sandhi (Splitting)`.

- [ ] **Step 5: Sanity-check the generated file**

Run: `head -6 sanskrit_visarga_sandhi_split_anki.txt`
Expected: 6-line header with `#deck:🕉️ Sanskrit Visarga Sandhi (Splitting)`, `#notetype:Basic`, `#guid column:1`.

Then run: `grep -c "also accepted:" sanskrit_visarga_sandhi_split_anki.txt`
Expected: `7` (the seven multi-form records render an alternates line).

- [ ] **Step 6: Commit**

```bash
git add main.rb sanskrit_visarga_sandhi_split_anki.txt
git commit -m "Register visarga-sandhi-split generator and generate deck

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Document the deck in CLAUDE.md

**Files:**
- Modify: `CLAUDE.md` (append a subsection at the end of "### The visarga sandhi deck")

**Interfaces:**
- Consumes: nothing at runtime — documentation only.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add the subsection**

In `CLAUDE.md`, at the very end of the "### The visarga sandhi deck" section (immediately before the next `###` heading, or at end of file if it is the last section), add:

```markdown
**The splitting (inverse) deck.** A companion deck (`🕉️ Sanskrit Visarga Sandhi (Splitting)`, `Anki::VISARGA_SANDHI_SPLIT_DECK`) practises the reverse skill — *vigraha*, splitting a combined form back into its two words — mirroring the vowel-sandhi splitting deck. `lib/generators/visarga_sandhi_split.rb` (class `Generators::VisargaSandhiSplit`, `--visarga-sandhi-split`) is a pure rendering transform over the **same** `data/visarga_sandhi.json` (no new data file, no engine): front is the primary combined Devanagari form (नरश् चरति), back is the split (नरः + चरति) plus word1's underlying pre-visarga form (नरः ← नरस्), any alternate accepted forms, and the same rule/explanation as the forward card. Because a record can list several accepted combined forms, the deck emits **one card per record** on the primary form (`combined[0]`) — 50 records → 50 cards — with the alternates shown on the back as "also accepted". It is a **separate deck** keyed with the distinct `visarga_sandhi_split:` prefix (both decks use `#guid column:1`, so a shared key would make Anki merge the two directions on import). `requires_letters? == false`, no audio, no JSON intermediate. Validated by `test/visarga_sandhi_split_deck_test.rb` (the card data itself is already validated by `test/visarga_sandhi_deck_test.rb`).
```

- [ ] **Step 2: Run the full test suite as a final check**

Run: `for f in test/*_test.rb; do ruby "$f" || break; done`
Expected: every file passes (0 failures, 0 errors).

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "Document visarga sandhi splitting deck in CLAUDE.md

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage:**
- New deck constant → Task 1 Step 3. ✓
- New generator reading same data, mirrored card, distinct key prefix → Task 1 Step 4. ✓
- One card per record on primary combined form → Task 1 Step 4 (`entry["combined"].first`) + test Step 1. ✓
- Back shows split + underlying form + alternates + rule → Task 1 Step 4 + tests. ✓
- Registration in main.rb (require + array) → Task 2 Steps 1–2. ✓
- Light rendering test (count, unique/prefixed keys, front primary form, back split/underlying/alternates) → Task 1 Step 1. ✓
- Regenerate + commit `.txt` build artifact → Task 2 Steps 4–6. ✓
- CLAUDE.md subsection → Task 3 Step 1. ✓
- Out of scope (consonant sandhi, one-card-per-form, schema/forward changes, audio) → not touched. ✓

**Placeholder scan:** none — all code and commands are concrete.

**Type consistency:** `KEY`/`DESCRIPTION`/`OUTPUT_TXT`, `Anki::VISARGA_SANDHI_SPLIT_DECK`, the `visarga_sandhi_split:` prefix, and the record's string keys (`combined` as a list of `{"iast", "devanagari"}`, `word1_underlying_devanagari`, etc.) are used identically across tasks and match `VisargaSandhiDeck.load`'s output.
