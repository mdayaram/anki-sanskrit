# Sanskrit Alphabet Anki Deck

A generator for [Anki](https://apps.ankiweb.net/) flashcards to learn the
Sanskrit alphabet (Devanāgarī) — the basic letters, consonant+vowel syllables,
conjunct ligatures, and anusvāra pronunciation. A single `main.rb` writes one
tab-separated `.txt` file per category for you to import into Anki. All cards
land in a single deck, **🕉️ Sanskrit Alphabet**, so you can import as many of the
files as you like and they merge together.

There is also a separate **🕉️ Bhagavad Gita** deck for reading practice on whole
verses (Devanāgarī front; transliteration, two English translations, and a
recitation clip on the back) — see [Bhagavad Gita verse deck](#bhagavad-gita-verse-deck).

The source data the alphabet scripts read (`data/letters.json` and the
pronunciation mp3s in `data/audio/`) is already committed to the repo, so you can
generate those import files right away. The Bhagavad Gita data is fetched
separately with `fetch_gita.rb` (see below).

## Prerequisites

- Ruby (any reasonably recent version) — the generators use only the standard
  library.

## Generating the import files

Run `main.rb` from the repository root. Flags pick which categories to
generate, and they combine:

```bash
./main.rb --all                    # generate every category
./main.rb --basic --combinations   # generate a subset
./main.rb --list                   # list categories
./main.rb --help
```

| Flag | File | Cards | Contents |
| --- | --- | --- | --- |
| `--basic` | `sanskrit_anki.txt` | 50 | Each vowel and consonant, with pronunciation **audio**, romanization, grammatical properties, and tips. |
| `--combinations` | `sanskrit_combinations_anki.txt` | 378 | Consonant + vowel syllables (का, कि, कं …), pruned to those that actually occur in the Mahābhārata corpus. |
| `--conjuncts` | `sanskrit_conjuncts_anki.txt` | 89 | The most common conjunct ligatures / saṃyuktākṣara (प्र, क्त, स्त्र …). |
| `--anusvara` | `sanskrit_anusvara_anki.txt` | 36 | Anusvāra (ं) pronunciation — one card per following consonant — plus the few attested standalone vowel+mark forms. |
| `--gita-verses` | `sanskrit_gita_verses_anki.txt` | 640 | Bhagavad Gita verses (separate **🕉️ Bhagavad Gita** deck), grouped to match bhagavadgita.com, with JKYog recitation **audio**. Requires running `fetch_gita.rb` first — see below. |

### Bhagavad Gita verse deck

```bash
ruby fetch_gita.rb            # download verses + recitation audio -> data/
./main.rb --gita-verses       # generate sanskrit_gita_verses_anki.txt
```

`fetch_gita.rb` is a standalone networked step (like `scrape_sanskrit.rb`) that
downloads the open [gita/gita](https://github.com/gita/gita) dataset, merges
verses into bhagavadgita.com's canonical groups (e.g. 1.4–6 become one card), and
downloads the JKYog (Swami Mukundananda) recitation mp3s into `data/gita.json` +
`data/gita_audio/` (re-running skips files already downloaded; clear the folder to
re-download). Then `./main.rb --gita-verses` builds the **🕉️ Bhagavad Gita** deck:
front = the Devanāgarī verse(s); back = IAST transliteration, a literal
translation (Swami Gambirananda), a devotional translation (Swami Sivananda), and
a recitation audio clip. The two translation authors are configurable at the top
of `fetch_gita.rb`.

### Audio

Categories with `[sound:…]` tags (`--basic` and `--gita-verses`) **prompt you** to
copy the mp3s into your Anki media folder after generating — answer `y` so the
audio works after import. Each category copies from its own folder (`data/audio/`
for the alphabet, `data/gita_audio/` for the Gita).

> `main.rb` finds your Anki media folder automatically — it checks the standard
> locations for macOS, Windows, and Linux (including Flatpak) and prefers Anki's
> default "User 1" profile. If it can't find it, or you want a specific profile,
> set the `ANKI_MEDIA_DIR` environment variable to the full path of your
> `collection.media` folder (e.g. `ANKI_MEDIA_DIR="…/collection.media" ./main.rb
> --basic`), or answer `n` and copy `data/audio/*.mp3` in yourself.

## Importing into Anki

For each `.txt` file you generated:

1. Open Anki.
2. **File → Import** and select the file.
3. The file's header sets the deck (**🕉️ Sanskrit Alphabet**, or **🕉️ Bhagavad
   Gita** for the verse file), note type (**Basic**), and field mapping
   automatically, so just click **Import**.

The files set a stable GUID column, so re-importing an updated file **updates**
the existing cards rather than creating duplicates.

## Notes

- `sanskrit_anki.txt` (the basic alphabet) and `sanskrit_gita_verses_anki.txt`
  (the Gita verses) have audio; the other alphabet decks are text-only.
- `main.rb` requires only the Ruby standard library. The alphabet source data is
  already committed; to re-fetch it, run `bundle exec ruby scrape_sanskrit.rb`
  (needs the `nokogiri` gem from the `Gemfile`). The Bhagavad Gita data is fetched
  with `ruby fetch_gita.rb` (standard library only). Both are the only steps that
  touch the network.
- Unit tests for the shared primitives and pure transforms live in `test/`
  (minitest, a Ruby default gem); run a file with `ruby test/<name>_test.rb`.
  There is no linter or build step. The categories live in `lib/generators/`;
  shared card/IO helpers live in `lib/`.
- See [`CLAUDE.md`](CLAUDE.md) for how the data and card generation work
  internally.
