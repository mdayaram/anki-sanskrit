# Case Analysis Deck Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A new Anki subdeck `🕉️ Sanskrit Declensions::2. Case Analysis`: one card per Rāmāyaṇa sentence, English on the front, and on the back every declined word with its class label (`mAp`) and the reason it takes that case. The त्-ending nouns move to `3.`.

**Architecture:** Same shape as every other curated deck: a committed source of truth `data/case_analysis.json`, a pure loader module `CaseAnalysis` (`lib/case_analysis.rb`), a generator `Generators::CaseAnalysis` (`lib/generators/case_analysis.rb`) registered in `main.rb`, and a data-integrity test that is the only validation (strict `IastDevanagari.valid_pair?`, handout coverage).

**Tech Stack:** Ruby stdlib, minitest. `pdftoppm` (poppler) to render the Goldman scans for transcription.

**Spec:** `docs/superpowers/specs/2026-11-27-case-analysis-deck-design.md`

## Global Constraints

- Ruby standard library only; no new gems.
- Card HTML has no inline `style="..."` (TSV constraint); use `<table>`, `<big>`, `<small>`, `<b>`, `<center>`.
- Case names on the back are **English**; never Sanskrit case names (प्रथमा …). Handout use ids (`2c`, `1d`) are **never rendered**. `use` lives only in the data, for coverage.
- Class label = gender letter (`m f n`, omitted when gender is null) + case abbreviation (`N A I D Ab G L V`) + number letter (`s d p`). E.g. `mAp`, `fAbs`, `Ns`.
- `use: null` rows render "(beyond the handout)" before their reason and must carry a non-empty `reference`.
- Front is English only, nothing marked; bent toward the Sanskrit only for 3b passives, 6b "of X there is", 7d absolutes, and 1e/3g adverbs.
- Composed sentences stay Rāmāyaṇa-themed (its people, places, events); `source: "composed"`.
- Text fields: no ASCII `"`, no tabs, no markup; curly quotes in English.
- Every data change ships with its regenerated `sanskrit_*_anki.txt` in the same commit (CLAUDE.md rule).

## Review Focus

1. **The same form twice in one sentence** (रामः … रामः): the occurrence check must compare counts, not demand exactly one. → test in Task 2.
2. **A compound word as one row** (प्रतिज्ञापालनाय): it is one space-separated token whose label is the case of the whole word; the occurrence check must not try to split it. → fixture in Task 2.
3. **A personal pronoun with no gender** (अहम्): label drops the gender letter, the agreement check skips gender. → tests in Tasks 2 and 3.
4. **An alternative analysis** must render with the *word's* gender/number and the *alternative's* case, e.g. "or nGs —", and an alternative's `use` must belong to its own case. → tests in Tasks 2 and 3.
5. **ASCII `"` in an English sentence** opening a TSV field would corrupt the import. → hygiene test in Task 2.

---

### Task 1: Renumber the त्-ending nouns to subdeck 3

**Files:**
- Modify: `lib/anki.rb:70` (`T_NOUNS_DECK` → `"#{DECLENSIONS_PARENT}::3. त्-Ending Nouns"`)
- Modify: `lib/generators/t_nouns.rb` (`OUTPUT_TXT = "sanskrit_declensions_3_t_nouns_anki.txt"`; comment's `2. त्-Ending Nouns` → `3.`)
- Rename: `sanskrit_declensions_2_t_nouns_anki.txt` → `sanskrit_declensions_3_t_nouns_anki.txt` (`git mv`, then regenerate)
- Modify: `test/declensions_test.rb:14`, `test/anki_test.rb` (expectations)
- Modify: `CLAUDE.md` (Deck layout block, filename examples, declensions table row, "Next paradigms … join as `3. …`, `4. …`" → "`4. …`, `5. …`")

- [ ] **Step 1:** Change `test/declensions_test.rb:14` to expect `"#{Anki::DECLENSIONS_PARENT}::3. त्-Ending Nouns"`.
- [ ] **Step 2:** Run `ruby test/declensions_test.rb` — expect FAIL on the deck name.
- [ ] **Step 3:** Update the constant and `OUTPUT_TXT`; `git mv` the txt.
- [ ] **Step 4:** Run `./main.rb --t-nouns`, then `for f in test/*_test.rb; do ruby $f || exit 1; done` — all PASS; the txt's `Deck` column reads `…::3. त्-Ending Nouns::…`.
- [ ] **Step 5:** Update CLAUDE.md; also add the `2. Case Analysis` line to the Deck layout block now (`::1. Cases  ::2. Case Analysis  ::3. त्-Ending Nouns::{…}`).
- [ ] **Step 6:** Commit: `Renumber त्-ending nouns to declensions subdeck 3`.

### Task 2: Loader, schema and data validator (with a seed sentence)

**Files:**
- Create: `lib/case_analysis.rb`
- Create: `data/case_analysis.json` (seed: the Laxmana sentence from the spec's conversation, analysed in full, plus one sentence with a repeated form and one with a 1st-person pronoun — enough to exercise every check)
- Create: `test/case_analysis_data_test.rb`

**Interfaces:**
- Produces:
  - `CaseAnalysis.load(path = Paths.data("case_analysis.json")) -> Hash` (aborts if missing, like `CaseFunctions.load`)
  - `CaseAnalysis::CASE_ABBREVIATIONS = { "nominative" => "N", "accusative" => "A", "instrumental" => "I", "dative" => "D", "ablative" => "Ab", "genitive" => "G", "locative" => "L", "vocative" => "V" }`
  - `CaseAnalysis::NUMBER_LETTERS = { "singular" => "s", "dual" => "d", "plural" => "p" }`
  - `CaseAnalysis.label(gender, kase, number) -> String` — `label("m","accusative","plural") == "mAp"`, `label(nil,"nominative","singular") == "Ns"`
- Record schema: exactly the spec's (`id, source, english, devanagari, iast, words[]`; word: `english, devanagari, iast, stem_devanagari, stem_iast, gender, number, case, use, why, agrees_with, reference, alternatives[{case,use,why}]`). Word rows are in **English sentence order**.

- [ ] **Step 1: Write the failing tests** in `test/case_analysis_data_test.rb` (reuse `CaseFunctions.load` for the case ids and handout uses):
  - `test_label_notation` — the two `label` examples above, plus `label("f","ablative","singular") == "fAbs"`.
  - `test_records_have_every_field` / `test_ids_unique`.
  - `test_case_and_use_agree` — `case` ∈ case ids; `use` nil or a handout use whose `case` equals the row's; same for each alternative; `gender` ∈ `m f n nil`; `number` ∈ the three.
  - `test_beyond_handout_rows_cite_a_reference` — `use.nil?` ⇒ `reference` non-empty.
  - `test_sentences_read_as_their_iast` — strict `valid_pair?` on sentence, each form, each stem; message includes `to_iast` output.
  - `test_each_form_occurs_in_its_sentence` — for each distinct form, `sentence.split.count(form) >= rows_with_that_form` in both scripts (Review Focus 1).
  - `test_agreeing_words_match_their_head` — `agrees_with` names a form of another row in the same sentence with the same case, number, `use`, and gender when both non-nil (Review Focus 3).
  - `test_text_hygiene` — no `"`, `\t`, `<`, `>` in `english`, `why`, alternative `why`, `reference`.
- [ ] **Step 2:** Run `ruby test/case_analysis_data_test.rb` — FAIL (`cannot load such file -- case_analysis`).
- [ ] **Step 3:** Implement `lib/case_analysis.rb` and write the seed `data/case_analysis.json`.
- [ ] **Step 4:** Run the test — PASS.
- [ ] **Step 5:** Commit: `Add case analysis data, loader and validator`.

### Task 3: Generator, registration and docs

**Files:**
- Create: `lib/generators/case_analysis.rb`
- Create: `test/case_analysis_test.rb`
- Modify: `lib/anki.rb` (`CASE_ANALYSIS_DECK = "#{DECLENSIONS_PARENT}::2. Case Analysis"`), `test/anki_test.rb:48` (add it to the declensions deck list)
- Modify: `main.rb` (add `Generators::CaseAnalysis` between `CaseNames` and `TNouns`)
- Modify: `CLAUDE.md` (declensions table row: `…::2. Case Analysis` | `Anki::CASE_ANALYSIS_DECK` | `--case-analysis` | `case_analysis:` | N; a short paragraph on the deck: schema, label notation, "no use ids rendered", beyond-the-handout rows, agreeing words)

**Interfaces:**
- Consumes: `CaseAnalysis.load`, `CaseAnalysis.label` (Task 2).
- Produces: `Generators::CaseAnalysis < Base` with `KEY = "case-analysis"`, `OUTPUT_TXT = "sanskrit_declensions_2_case_analysis_anki.txt"`, `requires_letters? == false`, `deck == Anki::CASE_ANALYSIS_DECK`, `build -> sentences array`, `card(s) -> ["case_analysis:#{s['id']}", front, back]`. Refer to the loader as `::CaseAnalysis`.

Back layout: `<center>` Devanagari sentence (`<big>`) + IAST `<br>`, then a `<table>` with one `<tr>` per word: English · Devanagari form · `<b>label</b>` · reason, where reason is `why`, prefixed `(beyond the handout) ` when `use` is nil, followed for each alternative by `<br>or <b>#{label(gender, alt case, number)}</b> — #{alt why}`.

- [ ] **Step 1: Write the failing tests** in `test/case_analysis_test.rb`, rendering the real data:
  - `test_deck_key_and_file` — deck, key prefix, `OUTPUT_TXT`.
  - `test_front_is_english_only` — front contains `english`, no Devanagari (`/[ऀ-ॿ]/`), no label from any of its words.
  - `test_back_shows_every_word_label_and_reason` — each form, `label`, and `why` appear.
  - `test_back_hides_handout_numbers_and_sanskrit_case_names` — no `/\b[1-8][a-j]\b/`, none of the eight Sanskrit case names from `case_functions.json`.
  - `test_alternative_uses_its_own_case` — the "promise" row's back contains `or <b>` + label with the alternative's case (Review Focus 4).
  - `test_beyond_handout_note` — a `use: nil` row renders `(beyond the handout)` (add one to the seed data if Task 2's seed has none).
- [ ] **Step 2:** Run `ruby test/case_analysis_test.rb` — FAIL.
- [ ] **Step 3:** Implement the generator, constant and `main.rb` registration.
- [ ] **Step 4:** Run `./main.rb --case-analysis` and every test file — all PASS (including `deck_filenames_test.rb`).
- [ ] **Step 5:** Update CLAUDE.md.
- [ ] **Step 6:** Commit with the generated txt: `Add Case Analysis deck generator`.

### Task 4: Goldman sentences

**Files:**
- Modify: `data/case_analysis.json`, regenerated `sanskrit_declensions_2_case_analysis_anki.txt`

- [ ] **Step 1:** Download the Goldman reading scans for Lessons 4–10 (`…/SanskritMaterial/Reading/Ramayana{1..7}-Lesson-{4..10}.pdf`) into a fresh scratchpad directory; render with `pdftoppm -r 200 -png`; re-read doubtful lines from 400 dpi crops. Reuse the full sentences behind the existing Lesson 4–7 examples in `data/case_functions.json`.
- [ ] **Step 2:** Add ~30–40 records: `source: "Goldman reading, Lesson N"` (`(adapted)` when simplified), sandhi broken, natural English (bent only per Global Constraints), every declined word analysed. For any handout-external use, set `use: null`, write the reason from research and set `reference` (e.g. `"Whitney §275"`, `"Apte, Guide to Sanskrit Composition §…"`, `"Kale, Higher Sanskrit Grammar §…"`), checking the section actually says it.
- [ ] **Step 3:** Run `ruby test/case_analysis_data_test.rb` — PASS (fix any `valid_pair?` failure by re-reading the scan, never by bending the IAST).
- [ ] **Step 4:** `./main.rb --case-analysis`; commit data + txt: `Add Goldman reading sentences to case analysis deck`.

### Task 5: Composed sentences and full handout coverage

**Files:**
- Modify: `test/case_analysis_data_test.rb`, `data/case_analysis.json`, regenerated txt

- [ ] **Step 1: Write the failing test** `test_every_handout_use_is_covered` — the set of non-nil primary `use` values across all words equals all 40 handout use ids from `case_functions.json`; failure message lists the missing ids.
- [ ] **Step 2:** Run it — FAIL, listing what Goldman didn't reach.
- [ ] **Step 3:** Compose Rāmāyaṇa-themed sentences (`source: "composed"`) for each missing use, one sentence may cover several; analyse every declined word in each.
- [ ] **Step 4:** Run every test — PASS.
- [ ] **Step 5:** `./main.rb --case-analysis`; update the card count in CLAUDE.md's declensions table; commit data + test + txt + CLAUDE.md: `Cover every handout case use in case analysis deck`.
