# Sanskrit Alphabet Anki Deck

Scripts that generate [Anki](https://apps.ankiweb.net/) flashcards for learning the
Sanskrit alphabet (Devanāgarī) — the basic letters, consonant+vowel syllables,
conjunct ligatures, and anusvāra pronunciation. Every script writes a
tab-separated `.txt` file you import into Anki. All cards land in a single deck,
**🕉️ Sanskrit Alphabet**, so you can import as many of the files as you like and
they merge together.

The source data the scripts read (`data/letters.json` and the pronunciation mp3s
in `data/audio/`) is already committed to the repo, so you can generate the
import files right away.

## Prerequisites

- Ruby (any reasonably recent version) — the generators use only the standard
  library.

## Generating the import files

Run the scripts from the repository root.

### The basic alphabet (with audio)

```bash
ruby generate_anki.rb
```

Writes **`sanskrit_anki.txt`** (50 cards: each vowel and consonant, with
pronunciation audio, romanization, grammatical properties, and tips). It then
**prompts you** to copy the mp3s into your Anki media folder — answer `y` so the
`[sound:…]` tags work after import.

> The script finds your Anki media folder automatically — it checks the standard
> locations for macOS, Windows, and Linux (including Flatpak) and prefers Anki's
> default "User 1" profile. If it can't find it, or you want a specific profile,
> set the `ANKI_MEDIA_DIR` environment variable to the full path of your
> `collection.media` folder (e.g. `ANKI_MEDIA_DIR="…/collection.media" ruby
> generate_anki.rb`), or answer `n` and copy `data/audio/*.mp3` in yourself.

### Optional — extra decks (no audio)

Each writes one import file:

```bash
ruby generate_combinations_anki.rb  # sanskrit_combinations_anki.txt — 378 cards
ruby generate_conjuncts_anki.rb     # sanskrit_conjuncts_anki.txt    —  89 cards
ruby generate_anusvara_anki.rb      # sanskrit_anusvara_anki.txt     —  36 cards
```

| File | Contents |
| --- | --- |
| `sanskrit_combinations_anki.txt` | Consonant + vowel syllables (का, कि, कं …), pruned to those that actually occur in the Mahābhārata corpus. |
| `sanskrit_conjuncts_anki.txt` | The most common conjunct ligatures / saṃyuktākṣara (प्र, क्त, स्त्र …). |
| `sanskrit_anusvara_anki.txt` | Anusvāra (ं) pronunciation — one card per following consonant — plus the few attested standalone vowel+mark forms. |

## Importing into Anki

For each `.txt` file you generated:

1. Open Anki.
2. **File → Import** and select the file.
3. The file's header sets the deck (**🕉️ Sanskrit Alphabet**), note type
   (**Basic**), and field mapping automatically, so just click **Import**.

The files set a stable GUID column, so re-importing an updated file **updates**
the existing cards rather than creating duplicates.

## Notes

- Only `sanskrit_anki.txt` (the basic alphabet) has audio; the other decks are
  text-only.
- There are no tests or build step — the scripts are standalone.
- See [`CLAUDE.md`](CLAUDE.md) for how the data and card generation work
  internally.
