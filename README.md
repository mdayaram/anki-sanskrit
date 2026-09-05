# Sanskrit Anki Decks

A set of [Anki](https://apps.ankiweb.net/) flashcard decks for learning Sanskrit —
first the Devanāgarī alphabet, then a Vedānta vocabulary glossary, then the vowel
sandhi rules, and finally the Bhagavad Gītā. The cards are generated from a few
well-chosen, openly available
sources (see **[Sources & Acknowledgements](#sources--acknowledgements)** below —
these decks exist only thanks to the people and projects who made that material
freely available).

You don't have to generate anything to get started: all the source data is
already committed to this repo, so you can build the import files and load them
into Anki right away.

## The decks

There are six decks, designed to be learned in order — each one builds on the
last. They're independent, though, so you can generate and import any of them on
their own.

### 1. 🕉️ Sanskrit Alphabet — learn to read the script

Start here. These are the building blocks of written Sanskrit:

| File | Cards | What it covers |
| --- | --- | --- |
| Basic letters | 50 | Every vowel and consonant, with **pronunciation audio**, romanization, grammatical notes, and learning tips. |
| Combinations | 378 | Consonant + vowel syllables (का, कि, कं …), limited to the ones that actually occur in the Mahābhārata. |
| Conjuncts | 89 | The most common conjunct ligatures (प्र, क्त, स्त्र …). |
| Anusvāra | 36 | How the anusvāra (ं) is pronounced — one card per following consonant. |

### 2. 🕉️ Vedanta Glossary — build vocabulary

Once you can read the script, start recognizing words: 2,393 common Vedānta terms.
Front: Devanāgarī. Back: IAST transliteration and an English meaning. (No audio.)

### 3. 🕉️ Sanskrit Vowel Sandhi — learn how words fuse

Running Sanskrit fuses adjacent sounds at their boundaries, so a verse rarely
shows its words in isolation. Sandhi splits into three families by what meets at
the junction — vowel (*svara*), consonant (*vyañjana*), and visarga sandhi; this
deck covers the first. It teaches the five vowel (svara) sandhis — 35 cards.
Front: the two parts in Devanāgarī (देव इन्द्र).
Back: the combined form (देवेन्द्र), the IAST for the parts and the whole, which
sandhi applied, a brief statement of its rule, and the context — whether the
sandhi happens between two words, inside a compound, or within a single word
(which matters: the same vowels can combine differently across a word boundary
than inside a word). No audio.

### 4. 🕉️ Sanskrit Visarga Sandhi — the final-ḥ rules

The second sandhi family: what a word-final visarga (ḥ) becomes depending on the
vowel before it and the sound after it — 50 cards. Front: the two parts in
Devanāgarī (नरः गच्छति). Back: the combined form(s) (नरो गच्छति), the IAST for the
parts and the whole, which rule applied, and a brief statement of that rule. Some
junctions have more than one accepted outcome (e.g. before a voiceless stop the
visarga may become a sibilant or stay a visarga); those cards show every form. No
audio.

### 5. 🕉️ Sanskrit External / Internal Consonant Sandhi — the consonant rules

The third and last sandhi family, split the way its source handout splits it.
**External** (53 cards) covers the twelve rules for what happens where one word's
final consonant meets the next word's first sound — voicing (वाक् देवी → वाग्देवी),
nasal assimilation (वाक् मय → वाङ्मय), the several changes specific to final त् and
न्, म् becoming anusvāra, and the doubling rules. **Internal** (23 cards) covers the
two rules that operate inside a single word: स् → ष् (वि + सीदति → विषीदति) and
न् → ण् (ब्रह्मन् + आ → ब्रह्मणा). Each rule turns on three separate conditions —
what triggers it, what the target sound may be followed by, and what may stand in
between — so every card also spells out how its own example satisfies (or fails)
them. A few cards are deliberate contrasts where the rule does *not* fire.

Front: the two parts in Devanāgarī. Back: the combined form written joined, the
way it appears in a printed text (तत् + च → तच्च), the IAST for the parts and the
whole, which rule applied, and a brief statement of it. Where a word's final
consonant is not its dictionary form, the front also shows where it came from
(वाक् ← वाच्) — a word can only end in a few consonants, and that reduction happens
before any of these rules apply. A few cards are deliberate contrasts, showing a
junction where the rule does *not* fire. No audio.

### 6. 🕉️ Bhagavad Gita — read whole verses

With the script and a base vocabulary in hand, move on to real text: 640 cards of
whole-verse reading practice. Front: the Devanāgarī verse(s). Back: transliteration,
a literal and a devotional English translation, and a recitation audio clip.

## Getting started

You'll need [Anki](https://apps.ankiweb.net/) and Ruby (any reasonably recent
version — the generator uses only Ruby's standard library, no gems to install).

Run `main.rb` from the repository root to build the import files. Flags pick which
decks to generate, and they combine:

```bash
./main.rb --all                    # generate everything
./main.rb --basic --combinations   # just a couple of categories
./main.rb --list                   # see all available categories
./main.rb --help
```

| Flag | Generates |
| --- | --- |
| `--basic` | Basic alphabet letters (with audio) |
| `--combinations` | Consonant + vowel syllables |
| `--conjuncts` | Conjunct ligatures |
| `--anusvara` | Anusvāra pronunciation |
| `--vedanta` | Vedānta glossary |
| `--vowel-sandhi` | Vowel (svara) sandhi word pairs |
| `--visarga-sandhi` | Visarga sandhi word pairs |
| `--external-consonant-sandhi` | External consonant sandhi word pairs |
| `--internal-consonant-sandhi` | Internal consonant sandhi (ṣatva/ṇatva) |
| `--gita-verses` | Bhagavad Gītā verses |

All the data these flags read is already in the repo, so they all work right away.

### A note on audio

Two decks include audio: the basic alphabet (letter pronunciations) and the
Bhagavad Gītā (verse recitations). After generating one of these, `main.rb` will
**ask you** before copying the mp3s into your Anki media folder — answer `y` so the
audio plays after import.

It finds your Anki media folder automatically on macOS, Windows, and Linux (it
prefers Anki's default "User 1" profile). If it can't find it, or you use a
different profile, point it at the right place with the `ANKI_MEDIA_DIR`
environment variable (the full path to your `collection.media` folder), or answer
`n` and copy the mp3s in yourself.

## Importing into Anki

For each file you generated:

1. Open Anki.
2. **File → Import** and select the file.
3. Each file already knows its deck, note type, and field mapping, so just click
   **Import**.

The files include a stable ID for every card, so if you regenerate a file and
re-import it, Anki **updates** your existing cards instead of creating duplicates.

## Sources & Acknowledgements

These decks are built almost entirely on the generous work of others. Enormous
thanks to everyone below — please visit and support the original sources.

### The alphabet

- **[Enjoy Learning Sanskrit — Sanskrit Alphabet Tutor](https://enjoylearningsanskrit.com/sanskrit-alphabet-tutor/)**
  — the letters, romanization, grammatical properties, and pronunciation tips for
  the basic alphabet deck.
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

### The Vedānta glossary

- **[Vedanta-Sanskrit Glossary](https://arshabodha.org/wp-content/uploads/abc/teachings/Vedanta-Sanskrit-Glossary.pdf)**
  (compiled by John Warne from the vocabulary used by **Pujya Swami Dayananda
  Saraswati**), published by the
  **[Arsha Bodha Center](https://arshabodha.org/)** — the source of every glossary
  term and its meaning.
- **[Monier-Williams Sanskrit Dictionary](https://www.sanskrit-lexicon.uni-koeln.de/)**
  (Cologne Digital Sanskrit Dictionaries) — used to verify the glossary headwords.

### The consonant sandhi decks

- **[Consonant Sandhi handout](https://arshabodha.org/wp-content/uploads/abc/teachings/SanskritMaterial/Sandhi/ConsonantSandhiRules.pdf)**
  by **Swami Tadatmananda**, published by the
  **[Arsha Bodha Center](https://arshabodha.org/teachings/sanskrit-grammar/)** —
  the source of the rules, of how they're divided into external and internal, and
  of one worked example per rule.
- **[Whitney's *Sanskrit Grammar*](https://en.wikisource.org/wiki/Sanskrit_Grammar_(Whitney))**,
  **[learnsanskrit.org](https://www.learnsanskrit.org/references/sandhi/)**,
  **[Antonia Ruppel's *Cambridge Introduction to Sanskrit* sandhi overview](https://www.cambridge-sanskrit.org/wp-content/uploads/2016/11/Sandhi-Overview-A4.pdf)**,
  and **Guy Leavitt's *Saṁskṛtasubodhinī*
  [consonant sandhi handout](http://www.introductory-sanskrit.com/uploads/4/2/9/4/42948489/lesson_13_sandhi_handouts.pdf)**
  — used to verify every rule against an independent statement of it, and the
  source of the additional worked examples on the cards.

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
