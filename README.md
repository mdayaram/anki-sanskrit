# Sanskrit Anki Decks

A set of [Anki](https://apps.ankiweb.net/) flashcard decks for learning Sanskrit —
first the Devanāgarī alphabet and numbers, then a Vedānta vocabulary glossary, the
sandhi rules (how words fuse), the uses of the eight cases and their endings, and
finally whole texts:
mantras and the Bhagavad Gītā. The cards are generated from a few well-chosen,
openly available sources (see **[Sources & Acknowledgements](#sources--acknowledgements)**
below — these decks exist only thanks to the people and projects who made that
material freely available).

You don't have to generate anything to get started: all the source data is
already committed to this repo, and so are the generated import files, so you can
load them into Anki right away.

## The decks

There are seven deck families, designed to be learned roughly in order — each one
builds on the last. They're independent, though, so you can generate and import
any of them on their own.

A family with several parts is a **parent deck with numbered subdecks**, so it
collapses into a single entry in Anki's deck list; the numbers make Anki's
alphabetical sort show the subdecks in the order they're meant to be learned:

```
🕉️ Sanskrit Alphabet         1. Vowels · 2. Consonants · 3. Combinations · 4. Conjuncts · 5. Anusvāra
🕉️ Sanskrit Numbers
🕉️ Vedanta Glossary
🕉️ Sanskrit Sandhi Joining    1. Vowel · 2. Visarga · 3. External Consonant · 4. Internal Consonant
🕉️ Sanskrit Sandhi Splitting  1. Vowel · 2. Visarga · 3. External Consonant · 4. Internal Consonant
🕉️ Sanskrit Declensions       1. Cases · 2. Case Analysis · 3. त्-Ending Nouns (1. Nominative … 8. Vocative)
🕉️ Sanskrit Mantras
🕉️ Bhagavad Gita
```

### 1. 🕉️ Sanskrit Alphabet — learn to read the script

Start here. These are the building blocks of written Sanskrit:

| Subdeck | Cards | What it covers |
| --- | --- | --- |
| 1. Vowels | 15 | Every vowel (plus the aṁ/aḥ marks), with **pronunciation audio**, romanization, grammatical notes, and learning tips. |
| 2. Consonants | 35 | Every consonant (plus kṣa and jña), with the same audio and notes. |
| 3. Combinations | 378 | Consonant + vowel syllables (का, कि, कं …), limited to the ones that actually occur in the Mahābhārata. |
| 4. Conjuncts | 89 | The most common conjunct ligatures (प्र, क्त, स्त्र …). |
| 5. Anusvāra | 36 | How the anusvāra (ं) is pronounced — one card per following consonant. |

Vowels and consonants both come from one file
(`sanskrit_alphabet_1-2_vowels_consonants_anki.txt`), which sets each card's subdeck itself.

### 2. 🕉️ Sanskrit Numbers — digits and number words

126 cards on the number system: the Devanāgarī digits (०–९), multi-digit numbers and
verse references as printed (२.४७, ॥१८.६६॥), the number words in both directions,
the ordinals 1st–18th in the form a Gītā reader meets them (प्रथमोऽध्यायः → chapter 1),
and the rules for building compounds. Rather than the whole 1–100 grid, it cards the
~20 building blocks, all of 11–19, and only the compounds that are irregular — the
rest follow from the rule. No audio.

### 3. 🕉️ Vedanta Glossary — build vocabulary

Once you can read the script, start recognizing words: 2,393 common Vedānta terms.
Front: Devanāgarī. Back: IAST transliteration and an English meaning. No audio.

### 4. 🕉️ Sanskrit Sandhi — learn how words fuse

Running Sanskrit fuses adjacent sounds at their boundaries, so a verse rarely shows
its words in isolation. Sandhi splits into three families by what meets at the
junction — vowel (*svara*), visarga, and consonant (*vyañjana*) sandhi — and each is
carded in **both directions**, as two parent decks:

- **🕉️ Sanskrit Sandhi Joining** — the two parts in Devanāgarī on the front; the
  combined form, the rule that applied, and an explanation on the back.
- **🕉️ Sanskrit Sandhi Splitting** — the reverse skill (*vigraha*): the combined form
  on the front, the parts it came from on the back.

| Subdeck | Joining | Splitting |
| --- | --- | --- |
| 1. Vowel | 78 | 78 |
| 2. Visarga | 86 | 86 |
| 3. External Consonant | 82 | 81 |
| 4. Internal Consonant | 22 | 19 |

Every card's back also glosses the words — `deva “god” + ālaya “abode” → devālaya
“temple”` — so you learn vocabulary along the way. No audio.

**Vowel.** The five vowel sandhis (dīrgha, guṇa, vṛddhi, yaṇ, ayādi): देव इन्द्र →
देवेन्द्र. Each card also gives the context — whether the sandhi happens between two
words, inside a compound, or within a single word — because the same vowels can
combine differently across a word boundary than inside a word.

**Visarga.** What a word-final visarga (ḥ) becomes depending on the vowel before it
and the sound after it: नरः गच्छति → नरो गच्छति. The front also shows the word's
underlying final -s or -r, which decides the outcome. Some junctions have more than
one accepted form (before a voiceless stop the visarga may become a sibilant or
stay a visarga); those cards show every form.

**External and internal consonant.** Split the way their source handout splits
them. **External** covers the twelve rules for where one word's final consonant
meets the next word's first sound — voicing (वाक् देवी → वाग्देवी), nasal assimilation
(वाक् मय → वाङ्मय), the changes specific to final त् and न्, म् becoming anusvāra, and
the doubling rules. **Internal** covers the two rules that operate inside a single
word: स् → ष् (वि + सीदति → विषीदति) and न् → ण् (ब्रह्मन् + आ → ब्रह्मणा). Each rule turns
on three separate conditions — what triggers it, what the target sound may be
followed by, and what may stand in between — so every card spells out how its own
example satisfies (or fails) them. Combined forms are written joined, the way they
appear in a printed text (तत् + च → तच्च). Where a word's final consonant is not its
dictionary form, the card shows where it came from (वाक् ← वाच्). A few joining cards
are deliberate contrasts where the rule does *not* fire; those aren't carded in the
splitting direction, since splitting them teaches nothing.

### 5. 🕉️ Sanskrit Declensions — the cases and their endings, put to use

Declension (*vibhakti*) from the Arsha Bodha Beginning Sanskrit Grammar class: the
eight cases once, then recognising them in real sentences, then whole nouns
declined through every one of them.

- **1. Cases** (8 cards) — Nominative → प्रथमा and so on (English to Sanskrit only,
  since the class works with the English names). The back gives the case's core
  sense and English cue ("by, with", "from", "in, on, at"), its **basic endings**
  for singular, dual and plural (with the neuter's own row for the nominative,
  accusative and vocative), and every numbered use the "Sanskrit Case Functions"
  handout lists for that case (1a … 8a).
- **2. Case Analysis** (61 cards) — a *Rāmāyaṇa* sentence in English on the front
  ("Rāma comes for the protection of the sages from the rākṣasas."); on the back,
  the Sanskrit and every declined word with its label in the class's notation
  (`mNs` = masculine Nominative singular; Ablative is `Ab`) and the reason it takes
  that case — "the ones protected: object of the verb-derived noun रक्षण
  'protecting'". Most sentences are the class's own Goldman readings (Lessons
  4–10); the rest are composed, always about the *Rāmāyaṇa*, so that every use on
  the case-functions handout comes up. Uses the handout doesn't list (the
  accusative of time, "best *of* women") are marked "beyond the handout", with a
  grammar reference.
- **3. त्-Ending Nouns** (120 cards) — five nouns in every case and number: मरुत्
  "wind" and जगत् "world", declined in class, and the homework nouns इन्द्रजित्,
  विद्युत् "lightning" and बृहत् "big" (declined as a neuter). *मरुत्, instrumental
  plural* → मरुद्भिः. The back shows the working (मरुत् + भिः → मरुद्भिः), explains
  any sandhi change, and names the other cells with the same form. The cards are
  split into **one subdeck per case** (1. Nominative … 8. Vocative, numbered like
  the Sanskrit cases), so each case can be drilled on its own before mixing them.

Each later model-noun handout (रामः/फलम्, शाला/दासी, …) is meant to join as the next
numbered paradigm, with the same eight case subdecks. No audio.

### 6. 🕉️ Sanskrit Mantras — whole mantras with a recitation

Two cards: the Gāyatrī mantra and Ādi Śaṅkara's Prātaḥ Smaraṇa Stotram. Front: the
mantra in Devanāgarī, and nothing else. Back: an English translation and a
**recitation audio clip**.

### 7. 🕉️ Bhagavad Gita — read whole verses

With the script and a base vocabulary in hand, move on to real text: 640 cards of
whole-verse reading practice. Front: the Devanāgarī verse(s). Back: transliteration,
a literal and a devotional English translation, and a **recitation audio clip**.

## Getting started

You'll need [Anki](https://apps.ankiweb.net/) and Ruby (any reasonably recent
version — the generator uses only Ruby's standard library, no gems to install).

The import files are already committed, each named after the deck it fills, so the
listing reads in deck order (`sanskrit_declensions_1_cases_anki.txt`,
`sanskrit_declensions_2_case_analysis_anki.txt`, …). You can skip
straight to [importing](#importing-into-anki). To rebuild them, run `main.rb` from
the repository root. Flags pick which files to generate, and they combine:

```bash
./main.rb --all                    # generate everything
./main.rb --basic --combinations   # just a couple of categories
./main.rb --list                   # see all available categories
./main.rb --help
```

| Flag | Generates | Deck |
| --- | --- | --- |
| `--basic` | Alphabet letters (with audio) | Alphabet › 1. Vowels, 2. Consonants |
| `--combinations` | Consonant + vowel syllables | Alphabet › 3. Combinations |
| `--conjuncts` | Conjunct ligatures | Alphabet › 4. Conjuncts |
| `--anusvara` | Anusvāra pronunciation | Alphabet › 5. Anusvāra |
| `--numbers` | Digits, number words, ordinals, rules | Numbers |
| `--vedanta` | Vedānta glossary | Vedanta Glossary |
| `--vowel-sandhi` / `--vowel-sandhi-split` | Vowel (svara) sandhi | Sandhi Joining / Splitting › 1. Vowel |
| `--visarga-sandhi` / `--visarga-sandhi-split` | Visarga sandhi | Sandhi Joining / Splitting › 2. Visarga |
| `--external-consonant-sandhi` / `--external-consonant-sandhi-split` | External consonant sandhi | Sandhi Joining / Splitting › 3. External Consonant |
| `--internal-consonant-sandhi` / `--internal-consonant-sandhi-split` | Internal consonant sandhi (ṣatva/ṇatva) | Sandhi Joining / Splitting › 4. Internal Consonant |
| `--case-names` | The eight cases, with endings and uses | Declensions › 1. Cases |
| `--case-analysis` | Rāmāyaṇa sentences: every word's case and why | Declensions › 2. Case Analysis |
| `--t-nouns` | Five त्-ending nouns, every form | Declensions › 3. त्-Ending Nouns › 1. Nominative … 8. Vocative |
| `--mantras` | Mantras (with audio) | Mantras |
| `--gita-verses` | Bhagavad Gītā verses (with audio) | Bhagavad Gita |

All the data these flags read is already in the repo, so they all work right away.

### A note on audio

Three decks include audio: the alphabet letters (pronunciations), the mantras, and
the Bhagavad Gītā (verse recitations). After generating one of these, `main.rb` will
**ask you** before copying the mp3s into your Anki media folder — answer `y` so the
audio plays after import. The Gītā recitations are too large to keep in the repo
(~289 MB), so the first time you copy them they're downloaded automatically.

It finds your Anki media folder automatically on macOS, Windows, and Linux (it
prefers Anki's default "User 1" profile). If it can't find it, or you use a
different profile, point it at the right place with the `ANKI_MEDIA_DIR`
environment variable (the full path to your `collection.media` folder), or answer
`n` and copy the mp3s in yourself.

## Importing into Anki

For each file you want:

1. Open Anki.
2. **File → Import** and select the file.
3. Each file already knows its deck, note type, and field mapping, so just click
   **Import**.

The files include a stable ID for every card, so if you regenerate a file and
re-import it, Anki **updates** your existing cards instead of creating duplicates.

Two things re-importing will *not* do. It won't **move** cards you already have:
a file's deck name only applies to newly added cards, so if a deck is ever renamed
here, rename your existing deck in Anki to match (renaming keeps your review
history). And it won't **delete** cards that a later version of a deck dropped —
remove those in Anki yourself.

## Sources & Acknowledgements

These decks are built almost entirely on the generous work of others. Enormous
thanks to everyone below — please visit and support the original sources.

### The alphabet

- **[Enjoy Learning Sanskrit — Sanskrit Alphabet Tutor](https://enjoylearningsanskrit.com/sanskrit-alphabet-tutor/)**
  — the letters, romanization, grammatical properties, and pronunciation tips for
  the vowel and consonant cards.
- **[Kautukam Sanskrit Server](https://sanskritserver.kautukam.com/)** — the
  per-letter pronunciation audio.
- **[Wikipedia: Devanagari conjuncts](https://en.wikipedia.org/wiki/Devanagari_conjuncts)**
  — used to validate every conjunct ligature, and the home of Ulrich Stiehl's
  Mahābhārata corpus frequency counts (originally from
  [sanskritweb.net](https://www.sanskritweb.net/)) that decide which syllables and
  conjuncts are common enough to be worth learning.
- **[Wikipedia: Anusvara](https://en.wikipedia.org/wiki/Anusvara)** and
  **[ashtangayoga.info](https://www.ashtangayoga.info/)** — the anusvāra
  pronunciation rules.

### The numbers

- The **[Arsha Bodha Center "Numerals" handout](https://arshabodha.org/wp-content/uploads/abc/teachings/SanskritMaterial/Basics/5-6-25-Numerals.pdf)**,
  **[Whitney's *Sanskrit Grammar*](https://en.wikisource.org/wiki/Sanskrit_Grammar_(Whitney))**
  (§§475–489), **[learnsanskrit.org](https://www.learnsanskrit.org/)**, and the
  **Monier-Williams** dictionary — the number words, their irregular forms, and the
  compounding rules.

### The Vedānta glossary

- **[Vedanta-Sanskrit Glossary](https://arshabodha.org/wp-content/uploads/abc/teachings/Vedanta-Sanskrit-Glossary.pdf)**
  (compiled by John Warne from the vocabulary used by **Pujya Swami Dayananda
  Saraswati**), published by the
  **[Arsha Bodha Center](https://arshabodha.org/)** — the source of every glossary
  term and its meaning.
- **[Monier-Williams Sanskrit Dictionary](https://www.sanskrit-lexicon.uni-koeln.de/)**
  (Cologne Digital Sanskrit Dictionaries) — used to verify the glossary headwords.

### The sandhi decks

- The **[Arsha Bodha Center](https://arshabodha.org/teachings/sanskrit-grammar/)**
  Sanskrit grammar materials: the
  **[Consonant Sandhi handout](https://arshabodha.org/wp-content/uploads/abc/teachings/SanskritMaterial/Sandhi/ConsonantSandhiRules.pdf)**
  by **Swami Tadatmananda** (the source of the consonant rules, of how they're
  divided into external and internal, and of one worked example per rule), and the
  [vowel](https://arshabodha.org/wp-content/uploads/abc/teachings/SanskritMaterial/Exercises/VowelSandhiExercise-1.pdf),
  [visarga](https://arshabodha.org/wp-content/uploads/abc/teachings/SanskritMaterial/Exercises/VisargaSandhiExercise.pdf)
  and [consonant](https://arshabodha.org/wp-content/uploads/abc/teachings/sanskrit/ConsonantSandhiExercise-1.pdf)
  sandhi exercise sheets and their answer sheets — the source of many of the
  examples.
- **[Whitney's *Sanskrit Grammar*](https://en.wikisource.org/wiki/Sanskrit_Grammar_(Whitney))**,
  **Pāṇini's *Aṣṭādhyāyī***,
  **[learnsanskrit.org](https://www.learnsanskrit.org/references/sandhi/)**,
  **[ashtangayoga.info](https://www.ashtangayoga.info/)**,
  **Emeneau & van Nooten's *Sanskrit Sandhi and Exercises***,
  **[Antonia Ruppel's *Cambridge Introduction to Sanskrit* sandhi overview](https://www.cambridge-sanskrit.org/wp-content/uploads/2016/11/Sandhi-Overview-A4.pdf)**,
  and **Guy Leavitt's *Saṁskṛtasubodhinī*
  [consonant sandhi handout](http://www.introductory-sanskrit.com/uploads/4/2/9/4/42948489/lesson_13_sandhi_handouts.pdf)**
  — used to verify every rule against an independent statement of it, and the
  source of further worked examples.

### The declension decks

- **["Sanskrit Case Functions" handout](https://arshabodha.org/wp-content/uploads/abc/teachings/SanskritMaterial/Declensions/Vibhakti_1.pdf)**
  from the **[Arsha Bodha Center](https://arshabodha.org/teachings/sanskrit-grammar/)**
  Beginning Sanskrit Grammar class (taught by Vasanthiji) — the source of the cases
  and their numbered uses.
- **Robert P. Goldman's *Devavāṇīpraveśikā*** — the graded *Rāmāyaṇa* readings
  that the class reads. Lessons 4–10 supply most of the Case Analysis sentences;
  further example sentences (with others from the handout and the class) are kept
  in `data/case_functions.json` for a later deck.
- **["Basic Terminations" handout](https://arshabodha.org/wp-content/uploads/abc/teachings/SanskritMaterial/Declensions/BasicTerminations.pdf)**
  from the same Arsha Bodha class — the table of endings, and (from the class
  recording) the five nouns declined with it and the sandhi points made along the way.

### The mantras

- **Gāyatrī mantra** — the sung recitation by **Shri Rattan Mohan Sharma**
  ([Internet Archive](https://archive.org/details/shri-rattan-mohan-sharma-gayatri-mantra)),
  trimmed to a single invocation; the translation is adapted from
  **S. Radhakrishnan**, *The Principal Upanishads* (1953), and checked against
  Dominik Haas, "Translating the Gāyatrī-Mantra" (2023).
- **Prātaḥ Smaraṇa Stotram** — the recitation and translation by **Swami
  Tadatmananda** of the Arsha Bodha Center, from
  [his YouTube channel](https://www.youtube.com/watch?v=cqPlGaHQUNQ).

### The Bhagavad Gītā

- **[gita/gita open dataset](https://github.com/gita/gita)** — the verse text,
  transliteration, word-by-word meanings, and English translations. The literal
  translation is by **Swami Gambirananda** and the devotional one by **Swami
  Sivananda**.
- **[BhagavadGita.com](https://www.bhagavadgita.com/)** (Swami Mukundananda's
  edition) — the canonical verse grouping used to combine related verses onto a
  single card.
- **[JKYog Gita audio](https://gita-audio.jkyog.org/)** — the verse recitation
  (Swami Mukundananda).

### Tools

- **[Anki](https://apps.ankiweb.net/)** — the wonderful open-source
  spaced-repetition software these decks are made for.

## Under the hood

Curious how the cards are generated, or want to re-fetch the source data yourself?
See **[`CLAUDE.md`](CLAUDE.md)** for a full tour of the pipeline (including the
Bhagavad Gītā recitation audio, which is downloaded separately), and the `test/`
directory for the unit tests.
