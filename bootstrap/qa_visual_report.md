# Vedanta glossary — visual cross-reference QA report

Method C: all 59 PDF pages rendered and compared (Devanagari + IAST headword)
against `data/vedanta.json`, via 10 parallel read-only subagents (≈245 entries
each). Methods A (structural) + B (round-trip) are clean across 2,393 entries.

**Overall: excellent.** Of 2,393 entries, the visual pass found 13 worth noting.
Pages 13–42 and 49–59 returned zero discrepancies.

## Fixed (genuine extraction errors)

| entry | was | now | reason |
|---|---|---|---|
| `samprkta` | `samprkta` / सम्प्र्क्त | `sampṛkta` / सम्पृक्त | source IAST headword dropped the ṛ (typo); PDF Devanagari confirms सम्पृक्त |
| `saṇkocakaḥ` | `saṇkocakaḥ` / सण्कोचकः | `saṅkocakaḥ` / सङ्कोचकः | lone mis-decode (retroflex ṇ) in the otherwise-guttural `saṅk-` run; PDF IAST shows ṅ |

## PDF typos — our data is correct, kept as-is

- `annādhaḥ`: PDF's Devanagari column prints अन्नायः (य), contradicting its own
  IAST `annādhaḥ`; our अन्नाधः is correct.
- `samāhāraḥ`: PDF prints a spurious leading conjunct स्समाहारः; our समाहारः is
  correct.

## Nasal-orthography divergences — RESOLVED (normalized to canonical forms)

The source's IAST headword used an explicit `ṅ` (which we transliterated to a
nasal+virama conjunct), differing from the source's own Devanagari column. These
were verified against third-party dictionaries (Wisdom Library, Monier-Williams,
Wiktionary, TransLiteral) and normalized to the canonical spelling (IAST +
Devanagari updated together; round-trip stays clean):

| was | → now (canonical) | basis |
|---|---|---|
| `ahaṅkāraḥ` / अहङ्कारः | `ahaṃkāraḥ` / अहंकारः | anusvāra canonical (WL, Wiktionary) |
| `alaṅkāraḥ` / अलङ्कारः | `alaṃkāraḥ` / अलंकारः | anusvāra canonical (WL) |
| `asaṅkrānta` / असङ्क्रान्त | `asaṃkrānta` / असंक्रान्त | anusvāra |
| `saṅdhānam` / सङ्धानम् | `sandhānam` / सन्धानम् | dental-n cluster canonical |
| `saṅmārgaḥ` / सङ्मार्गः | `sanmārgaḥ` / सन्मार्गः | dental-n cluster canonical |
| `saṅnidhiḥ` / सङ्निधिः | `sannidhiḥ` / सन्निधिः | सन्निधि (WL) |
| `saṅnikarṣaḥ` / सङ्निकर्षः | `sannikarṣaḥ` / सन्निकर्षः | सन्निकर्ष (WL) |
| `saṅnikṛṣṭa` / सङ्निकृष्ट | `sannikṛṣṭa` / सन्निकृष्ट | dental-n cluster canonical |

(`sanmātraḥ`/सन्मात्रः was already canonical in our data — no change.)

`saṃpṛkta` (was `sampṛkta`): the vocalic ṛ (पृ) is confirmed canonical by
Monier-Williams / Wisdom Library / TransLiteral; written with the anusvāra prefix
as संपृक्त.

**Result: QA A+B clean, and all visual discrepancies resolved or explained.**
