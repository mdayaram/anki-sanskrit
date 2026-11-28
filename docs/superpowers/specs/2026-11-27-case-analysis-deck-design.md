# Case Analysis deck — design

## Intent

Practise the skill of looking at a Rāmāyaṇa sentence and deciding, word by word, which case each declined word takes and *why* — the reasoning the user found useful when working through "O Laxmana! Rama goes on foot to the forest from Ayodhya with Sita to fulfill the promise of his father." (vocative 8a, nominative 1a, instrumental 3a/3c, accusative 2c, ablative 5a, accusative 2a vs. dative 4c + genitive 6e, genitive 6a).

The user sees this deck as the **precursor to the noun-paradigm decks**: first recognise case functions in context, then produce the forms. It follows the user's standing preference for decks that practise applying grammar rather than drilling terminology (memory `decks-favor-practice`), and their course goal of reading the Rāmāyaṇa (memory `course-goal-ramayana`).

## Goals

- One card per sentence. **Front:** an English sentence from the Rāmāyaṇa story, nothing marked. **Back:** the Sanskrit sentence, then every declined word with its English case name, its handout use number (1a … 8a, as in `data/case_functions.json` `uses`), and a one-line "why".
- Sentences are **a mix (user's choice)**: mostly real lines from Goldman's *Devavāṇīpraveśikā* Rāmāyaṇa readings (the class's text), translated to English; plus composed sentences to reach handout uses the readings don't. **Composed sentences must stay Rāmāyaṇa-themed** (its characters, places, events) — user's explicit instruction.
- Every handout use (all 40, 1a–8a) is covered by at least one sentence, enforced by a test.
- The deck becomes subdeck **2** of the Declensions family; the त्-ending nouns move to **3** (user's call).

## Non-goals

- No per-word cards (considered and rejected — see Approaches).
- No audio. No changes to the existing 71 one-target examples in `data/case_functions.json` (kept as-is, per the "keep unused curated data" preference).
- No derivation engine for forms or cases — curated, like the sandhi decks.

## Anti-goals

- A sentence whose English front gives the answer away (e.g. glossing "with Sītā (instrumental)").
- Composed sentences that read as generic textbook filler instead of the Rāmāyaṇa.
- Analyses that claim a single answer where two are defensible (the "promise" case): the back must show both.

## Approaches considered

1. **One card per sentence, whole-sentence analysis** — *picked by the user.* Matches the request and trains taking a whole sentence apart, the skill real reading needs. Trade-off: Anki grades the whole card, so one wrong word out of six is a judgement call.
2. **One card per word** (the sentence with one word bolded → its case + why). Finer-grained scheduling, but 5–8 near-duplicate cards per sentence and never practises the whole-sentence skill. Rejected.

Data location: a new file `data/case_analysis.json` rather than extending `case_functions.json` `examples` (whose schema is one target per sentence).

## Decided details

**Which words are analysed (my call, stated to and not rejected by the user):** every word that takes a case ending — nouns, pronouns, adjectives (adjectives agree with their noun, 1d etc.). Verbs and indeclinables (सह, च, इति, …) get no row; where one governs a case (सह → 3c, विना → 3d, नमः → 4e), the governed word's "why" names it.

**Front:** plain English, nothing marked — spotting the declined words is part of the exercise. **Natural English, bent toward the Sanskrit only when needed (user's call)** — i.e. only where natural English would hide the construction that decides the case, so the card has one fair answer: a passive with an instrumental agent ("By Rāma the demon was killed", 3b), "to have" (6b: "Of Rāma there is a wife"), the locative absolute (7d: "Rāma having gone, …"), and adverbs that could be 1e or 3g. Everywhere else, normal English.

**Agreeing words (my call):** an adjective, adjectival pronoun, participle or appositive outside the nominative takes **its head noun's case and use**, and its "why" says so ("agrees with वनम्"). The record carries `agrees_with` (the head's Devanagari form) so the test can check case/gender/number agree with that head. In the nominative, the handout's own 1c (apposition) / 1d (agreeing adjective) are used instead.

**Uses beyond the handout (user's call):** real lines are kept even when a word's case is used in a way the handout's 40 uses don't list — accusative of duration (चतुर्दश वर्षाणि "for fourteen years"), partitive genitive (नराणां श्रेष्ठः), the case a particular verb governs (genitive with स्मृ "remember"), etc. Such a word has `"use": null`, renders as "beyond the handout", and its `why` **explains from research why this case expresses it** (Whitney's *Sanskrit Grammar* §§ on case uses, Apte's *Guide to Sanskrit Composition*, Kale's *Higher Sanskrit Grammar*), citing the source in a `reference` field. These are expected to be a small minority of rows.

**Back:**
1. The Sanskrit sentence: Devanagari, then IAST, with sandhi broken (रामः वनं गच्छति), matching the existing examples' convention so every word validates strictly.
2. A table, one row per declined word, **in English sentence order** so it reads parallel to the front: English word(s) · Sanskrit form · **class label** · the reason. **Handout use numbers (2c, 1d …) are never rendered (user's call)** — the learner won't have the handout open, so the number is wasted space; the reason itself carries the teaching. `use` stays in the data only to drive the coverage test.
3. Where a word has a defensible alternative analysis, the row shows it too ("or G — the object of the “-ing” word “fulfilling”").

**Class label notation (user's call):** each word is labelled the way the class does — lowercase gender + Capital case + lowercase number, e.g. `mAp` = masculine Accusative plural. Case abbreviations: **N, A, I, D, Ab, G, L, V** (Ablative is `Ab` to keep it distinct from Accusative `A`); genders `m f n`; numbers `s d p`. The label is followed directly by the reason (`mAp — where he is going`); a `use: null` row adds a short “(beyond the handout)” note before its reason. Case names in explanations are **English**, never Sanskrit (प्रथमा etc. stay on the Cases deck only). *My call:* first/second-person pronouns (अहम्, त्वम् — no grammatical gender) drop the gender letter (`Ns`). The label is computed from `gender`/`case`/`number` by the generator, not stored.

**Deck/file naming:**
- New: `Anki::CASE_ANALYSIS_DECK = "#{DECLENSIONS_PARENT}::2. Case Analysis"`, file `sanskrit_declensions_2_case_analysis_anki.txt`, flag `--case-analysis`, card key `case_analysis:<id>`, class `Generators::CaseAnalysis` in `lib/generators/case_analysis.rb`, loader `CaseAnalysis.load` in `lib/case_analysis.rb` (name the loader module to avoid clashing with the generator class, as `::Numbers` does).
- Renumber: `T_NOUNS_DECK` → `"#{DECLENSIONS_PARENT}::3. त्-Ending Nouns"`, file `sanskrit_declensions_2_t_nouns_anki.txt` → `sanskrit_declensions_3_t_nouns_anki.txt`. Update `test/anki_test.rb`, `test/declensions_test.rb`, `test/deck_filenames_test.rb` expectations, and CLAUDE.md (Deck layout block, declensions table, "Next paradigms join as 3., 4." → "4., 5."). Regenerate and commit both decks. Tell the user to rename the deck in Anki.

**Data schema (`data/case_analysis.json`)** — a top-level `sentences` array:

```json
{
  "id": "rama-vanam-gacchati-sitaya",
  "source": "Goldman reading, Lesson 6" | "composed",
  "english": "Rāma goes to the forest with Sītā.",
  "devanagari": "रामः सीतया सह वनं गच्छति",
  "iast": "rāmaḥ sītayā saha vanaṃ gacchati",
  "words": [
    {
      "english": "Rāma",
      "devanagari": "रामः", "iast": "rāmaḥ",
      "stem_devanagari": "राम", "stem_iast": "rāma",
      "gender": "m", "number": "singular",
      "case": "nominative", "use": "1a",
      "why": "He does the going: subject of the active verb “goes”.",
      "agrees_with": null,
      "reference": null,
      "alternatives": []
    }
  ]
}
```

`alternatives` entries: `{ "case", "use", "why" }`. `source` follows the existing examples' wording ("Goldman reading, Lesson N", "(adapted)" suffix when simplified).

**Validation (`test/case_analysis_data_test.rb`):**
- Structure; unique ids; `case` is a known case id; `use` is null or a known handout use belonging to `case`; same for every alternative. `gender` ∈ m/f/n/null (null only for 1st/2nd-person pronouns), `number` ∈ singular/dual/plural.
- A `use: null` row has a non-empty `reference`.
- An `agrees_with` row: the head is another word row in the same sentence with the same case/number (and gender, when both have one) and the same `use`.
- Sentence `devanagari`↔`iast` pass strict `IastDevanagari.valid_pair?`; each word's form and stem pairs too.
- Each word's form occurs as a whole space-separated word in the sentence, in both scripts (exactly once, unless the sentence repeats it — then the test should allow the count to match the number of word rows with that form).
- Coverage: the union of `use` across all words (primary analyses, not alternatives) equals all 40 handout uses.
- Text hygiene as the other curated files: no ASCII `"`, tabs, or markup in text fields; English uses curly quotes.

**Rendering test (`test/case_analysis_test.rb`):** front contains no Devanagari and no case labels; back contains every word's form, its class label (`mAp`) and its reason; no handout use ids (`/\b[1-8][a-j]\b/`) and no Sanskrit case names (प्रथमा …) on the back; deck/file/key as above.

## Sources and transcription

- Goldman readings: `arshabodha.org/wp-content/uploads/abc/teachings/SanskritMaterial/Reading/Ramayana{1..18}-Lesson-{4..21}.pdf`. These are scans; read by rendering to PNG (`pdftoppm`), as done for the other Arsha Bodha PDFs. Lessons 4–7 were already transcribed for the existing examples (their full sentences are in `data/case_functions.json` and can be reused, extended to analyse every word). Later lessons may be used; their grammar may exceed what the class has covered, which is fine since the front is English.
- Lightly simplified real lines are allowed and marked "(adapted)".
- Composed sentences: Rāmāyaṇa people, places, events only. Aim them at uses the readings miss (likely 1e, 2b, 2d, 3d, 3f–3j, 4d–4f, 5b, 5d, 5e, 6b–6e, 7b–7d).

## Left to the builder

- Exact sentence list and count (expect ~40–60 to cover all 40 uses with a majority from Goldman).
- English translation wording.
- Table HTML (no inline `style=`, per the TSV constraint).
