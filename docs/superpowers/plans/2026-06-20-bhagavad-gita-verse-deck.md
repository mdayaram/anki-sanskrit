# Bhagavad Gita Verse Deck Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new Anki deck of ~700 Bhagavad Gita verses (Devanagari front; IAST + literal + devotional translation + recitation audio on the back), built from the `gita/gita` open dataset.

**Architecture:** Mirror the existing pipeline split. A new standalone networked script `fetch_gita.rb` downloads the dataset + per-verse MP3s and writes `data/gita.json` + `data/gita_audio/`. A new pure-transform generator `lib/generators/gita_verses.rb` (a `Generators::Base` subclass) turns that into an Anki import file, reusing the project's existing card/audio machinery. Small generalizations to shared code add multi-deck and multi-audio-folder support.

**Tech Stack:** Ruby standard library only (`json`, `open-uri`, `fileutils`). Tests use `minitest` (a Ruby default gem — no Gemfile change). No nokogiri needed (that is only for the alphabet scrape).

## Global Constraints

- **TSV safety:** card HTML must use no inline `style="..."` attributes; use `<big>`, `<center>`, `<b>`, `<ul>` only. Newlines (`\n`) in any field must be converted to `<br>` by the generator (the writer also flattens stray newlines defensively). Tabs are flattened by the writer.
- **Stdlib only** for runtime code; `fetch_gita.rb` may use `open-uri` (stdlib).
- **Deck name:** exactly `🕉️ Bhagavad Gita`.
- **Audio filenames:** `gita_<chapter>_<verse>.mp3`, stored in `data/gita_audio/`.
- **Translations:** literal = `Swami Gambirananda`; devotional = `Swami Sivananda`.
- **CLI flag:** `--gita-verses`.
- **Dataset raw base URL:** `https://raw.githubusercontent.com/gita/gita/main/data`
- **Card key/guid:** `gita_verse:<chapter>.<verse>` (stable, so re-import updates rather than duplicates).
- **Run tests with:** `ruby test/<name>_test.rb` (files use `require_relative`).

---

## File Structure

**Create:**
- `lib/gita_dataset.rb` — pure transform: raw upstream JSON → slim verse records. (testable, no IO)
- `lib/gita.rb` — `Gita.load(path)` reads `data/gita.json` (mirrors `Letters.load`).
- `lib/generators/gita_verses.rb` — the `Generators::GitaVerses` generator.
- `fetch_gita.rb` — standalone networked fetch script (sibling of `scrape_sanskrit.rb`).
- `test/anki_test.rb`, `test/base_test.rb`, `test/media_test.rb`, `test/gita_test.rb`, `test/gita_dataset_test.rb`, `test/gita_verses_test.rb`

**Modify:**
- `lib/paths.rb` — add `GITA_JSON`, `GITA_AUDIO_DIR`.
- `lib/anki.rb` — add `GITA_DECK`; `write_deck` gains `deck:` kwarg + newline flattening.
- `lib/generators/base.rb` — add `deck`, `audio_dir`, `self.requires_letters?`; `run` passes `deck:` and reports `deck`/`audio_dir`.
- `lib/media.rb` — `copy_audio` gains `source_dir:` kwarg.
- `main.rb` — register generator; load `letters.json` only when needed; copy audio grouped by source dir; report deck(s).
- `CLAUDE.md`, `README.md` — document the new deck and fetch step.

---

### Task 1: Shared Anki primitives — custom deck + newline flattening

**Files:**
- Modify: `lib/paths.rb`
- Modify: `lib/anki.rb:13` (DECK constant), `lib/anki.rb:23-37` (write_deck)
- Test: `test/anki_test.rb`

**Interfaces:**
- Produces: `Anki::GITA_DECK` (String `"🕉️ Bhagavad Gita"`); `Anki.write_deck(path, rows, deck: Anki::DECK)` — writes the deck header from `deck:` and flattens both `\t` and `\n` in every field to a space.

- [ ] **Step 1: Write the failing test**

Create `test/anki_test.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require "tempfile"
require_relative "../lib/anki"

class AnkiTest < Minitest::Test
  def write(rows, **opts)
    file = Tempfile.new(["deck", ".txt"])
    Anki.write_deck(file.path, rows, **opts)
    File.read(file.path)
  end

  def test_gita_deck_constant
    assert_equal "🕉️ Bhagavad Gita", Anki::GITA_DECK
  end

  def test_custom_deck_in_header
    assert_includes write([["k", "f", "b"]], deck: "My Deck"), "#deck:My Deck"
  end

  def test_default_deck_in_header
    assert_includes write([["k", "f", "b"]]), "#deck:#{Anki::DECK}"
  end

  def test_flattens_newlines_in_fields
    rows = write([["k", "line1\nline2", "b"]]).lines.reject { |l| l.start_with?("#") }
    assert_equal 1, rows.size
    assert_includes rows.first, "line1 line2"
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `ruby test/anki_test.rb`
Expected: FAIL — `NameError: uninitialized constant Anki::GITA_DECK` and/or `ArgumentError` on `deck:`.

- [ ] **Step 3: Implement — add path constants**

In `lib/paths.rb`, after the `LETTERS_JSON` line (line 9) add:

```ruby
  GITA_JSON      = File.join(DATA_DIR, "gita.json")
  GITA_AUDIO_DIR = File.join(DATA_DIR, "gita_audio")
```

- [ ] **Step 4: Implement — Anki changes**

In `lib/anki.rb`, after the `DECK` line (line 13) add:

```ruby
  # The Bhagavad Gita verse deck (a separate deck from the alphabet).
  GITA_DECK = "🕉️ Bhagavad Gita"
```

Replace `write_deck` (lines 23-37) with:

```ruby
  def self.write_deck(path, rows, deck: DECK)
    File.open(path, "w:UTF-8") do |f|
      f.puts "#separator:Tab"
      f.puts "#html:true"
      f.puts "#deck:#{deck}"
      f.puts "#notetype:Basic"
      f.puts "#columns:Key\tFront\tBack"
      f.puts "#guid column:1"

      rows.each do |key, front, back|
        f.puts [key, front, back].map { |field| field.to_s.gsub(/\t/, " ").gsub(/\r?\n/, " ") }.join("\t")
      end
    end
    rows.size
  end
```

Also update the comment above `write_deck` (line 20-22) to mention the `deck:` param and that both tabs and newlines are flattened.

- [ ] **Step 5: Run test to verify it passes**

Run: `ruby test/anki_test.rb`
Expected: PASS (4 runs, 0 failures).

- [ ] **Step 6: Commit**

```bash
git add lib/paths.rb lib/anki.rb test/anki_test.rb
git commit -m "Add GITA_DECK and parameterize write_deck by deck + flatten newlines"
```

---

### Task 2: Base generator — deck, audio_dir, requires_letters?

**Files:**
- Modify: `lib/generators/base.rb`
- Test: `test/base_test.rb`

**Interfaces:**
- Consumes: `Anki.write_deck(path, rows, deck:)` (Task 1).
- Produces: instance methods `#deck` (default `Anki::DECK`) and `#audio_dir` (default `Paths::AUDIO_DIR`); class method `Base.requires_letters?` (default `true`). `#run` now passes `deck: deck` to `write_deck` and its result hash includes `deck:` and `audio_dir:` in addition to the existing keys.

- [ ] **Step 1: Write the failing test**

Create `test/base_test.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/base"

class BaseTest < Minitest::Test
  class FakeGen < Generators::Base
    KEY         = "fake"
    DESCRIPTION = "fake"
    OUTPUT_TXT  = "fake_test_output.txt"

    def self.requires_letters? = false
    def deck = "Fake Deck"
    def audio_dir = "/tmp/fake_audio"
    def build = [{ "n" => 1 }]
    def card(entry) = ["k#{entry['n']}", "front", "back"]
    def audio_files(_data) = ["x.mp3"]
  end

  def test_base_requires_letters_by_default
    assert Generators::Base.requires_letters?
  end

  def test_subclass_can_opt_out_of_letters
    refute FakeGen.requires_letters?
  end

  def test_run_reports_deck_and_audio_dir
    result = FakeGen.new([], {}).run
    assert_equal "Fake Deck", result[:deck]
    assert_equal "/tmp/fake_audio", result[:audio_dir]
    assert_equal ["x.mp3"], result[:audio_files]
    assert_includes File.read(result[:txt]), "#deck:Fake Deck"
  ensure
    File.delete(Paths.output("fake_test_output.txt")) if File.exist?(Paths.output("fake_test_output.txt"))
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `ruby test/base_test.rb`
Expected: FAIL — `NoMethodError: undefined method 'requires_letters?'` (or `result[:deck]` is `nil`).

- [ ] **Step 3: Implement**

In `lib/generators/base.rb`, inside `class Base`, after the `OUTPUT_JSON = nil` line (line 18) add:

```ruby
    # Whether main.rb must load data/letters.json before this generator runs.
    # Generators that read a different data source override this with false.
    def self.requires_letters? = true
```

After `def description = self.class::DESCRIPTION` (line 26) add:

```ruby
    # The Anki deck these cards belong to. Override for a different deck.
    def deck = Anki::DECK

    # Directory holding this generator's audio sources. Override for a different folder.
    def audio_dir = Paths::AUDIO_DIR
```

In `run`, change the `write_deck` call (line 39) to:

```ruby
      Anki.write_deck(txt_path, rows, deck: deck)
```

And replace the returned hash (lines 41-47) with:

```ruby
      {
        key: key,
        cards: rows.size,
        txt: txt_path,
        json: json_path,
        deck: deck,
        audio_files: audio_files(data),
        audio_dir: audio_dir
      }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `ruby test/base_test.rb`
Expected: PASS (3 runs, 0 failures).

- [ ] **Step 5: Run existing pipeline sanity check**

Run: `./main.rb --basic`
Expected: still prints `... cards -> sanskrit_anki.txt` with no error (the basic generator uses the new defaults unchanged). Answer `n` to the audio prompt.

- [ ] **Step 6: Commit**

```bash
git add lib/generators/base.rb test/base_test.rb
git commit -m "Add deck/audio_dir/requires_letters? hooks to Generators::Base"
```

---

### Task 3: Media — copy from a configurable source directory

**Files:**
- Modify: `lib/media.rb:38-87`
- Test: `test/media_test.rb`

**Interfaces:**
- Produces: `Media.copy_audio(filenames, source_dir: Paths::AUDIO_DIR)` — resolves each source file under `source_dir` (default unchanged) and uses `source_dir` in all user-facing messages.

- [ ] **Step 1: Write the failing test**

Create `test/media_test.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "stringio"
require_relative "../lib/media"

class MediaTest < Minitest::Test
  def test_copies_from_custom_source_dir
    Dir.mktmpdir do |src|
      Dir.mktmpdir do |dest|
        File.write(File.join(src, "gita_1_1.mp3"), "AUDIO")
        ENV["ANKI_MEDIA_DIR"] = dest
        old_stdin = $stdin
        $stdin = StringIO.new("y\n")
        begin
          Media.copy_audio(["gita_1_1.mp3"], source_dir: src)
        ensure
          $stdin = old_stdin
          ENV.delete("ANKI_MEDIA_DIR")
        end
        assert File.exist?(File.join(dest, "gita_1_1.mp3"))
        assert_equal "AUDIO", File.read(File.join(dest, "gita_1_1.mp3"))
      end
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `ruby test/media_test.rb`
Expected: FAIL — `ArgumentError: unknown keyword: :source_dir`.

- [ ] **Step 3: Implement**

In `lib/media.rb`, change the signature (line 38):

```ruby
  def self.copy_audio(filenames, source_dir: Paths::AUDIO_DIR)
```

In the body, replace every reference to `Paths::AUDIO_DIR` with `source_dir`:
- line 47: `puts "Copy #{source_dir}/*.mp3 into your profile's collection.media folder yourself,"`
- line 67: `puts "  Skipped. Before importing, copy #{source_dir}/*.mp3 to:"`
- line 75: `src = File.join(source_dir, name)`
- line 85: `puts "  WARNING: #{missing.size} referenced files missing from #{source_dir}: #{missing.join(', ')}" unless missing.empty?`

- [ ] **Step 4: Run test to verify it passes**

Run: `ruby test/media_test.rb`
Expected: PASS (1 run, 0 failures).

- [ ] **Step 5: Commit**

```bash
git add lib/media.rb test/media_test.rb
git commit -m "Let Media.copy_audio copy from a configurable source dir"
```

---

### Task 4: Gita data loader

**Files:**
- Create: `lib/gita.rb`
- Test: `test/gita_test.rb`

**Interfaces:**
- Consumes: `Paths::GITA_JSON` (Task 1).
- Produces: `Gita.load(path = Paths::GITA_JSON)` → `Array<Hash>` of verse records parsed from JSON; `abort`s with a "run fetch_gita.rb first" message if the file is missing.

- [ ] **Step 1: Write the failing test**

Create `test/gita_test.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require "tempfile"
require_relative "../lib/gita"

class GitaTest < Minitest::Test
  def test_load_parses_json_from_given_path
    file = Tempfile.new(["gita", ".json"])
    file.write('[{"chapter":1,"verse":1,"audio_file":"gita_1_1.mp3"}]')
    file.flush
    data = Gita.load(file.path)
    assert_equal 1, data.size
    assert_equal "gita_1_1.mp3", data.first["audio_file"]
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `ruby test/gita_test.rb`
Expected: FAIL — `LoadError: cannot load such file -- ../lib/gita`.

- [ ] **Step 3: Implement**

Create `lib/gita.rb`:

```ruby
# frozen_string_literal: true

require "json"
require_relative "paths"

# Loads data/gita.json (produced by fetch_gita.rb). The Gita verse generator is a
# pure transform over this data, so this is the single place that reads it.
module Gita
  # The ordered list of verse records, as fetched. Accepts an explicit path so
  # tests can point at a fixture.
  def self.load(path = Paths::GITA_JSON)
    unless File.exist?(path)
      abort "ERROR: #{path} not found.\n" \
            "Run `ruby fetch_gita.rb` first."
    end

    JSON.parse(File.read(path))
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `ruby test/gita_test.rb`
Expected: PASS (1 run, 0 failures).

- [ ] **Step 5: Commit**

```bash
git add lib/gita.rb test/gita_test.rb
git commit -m "Add Gita.load for reading data/gita.json"
```

---

### Task 5: Gita dataset transform (pure)

**Files:**
- Create: `lib/gita_dataset.rb`
- Test: `test/gita_dataset_test.rb`

**Interfaces:**
- Produces: `GitaDataset.build(verses, translations, literal_author:, devotional_author:)` → `Array<Hash>`. Each input verse (`{"id", "chapter_number", "verse_number", "text", "transliteration", "word_meanings"}`) joins to English translations (`{"verse_id", "authorName", "lang", "description"}`) by `verse_id == id`, producing a record:
  `{"chapter", "verse", "devanagari", "transliteration", "word_meanings", "translations" => {"literal", "devotional"}, "audio_file" => "gita_<ch>_<v>.mp3"}`.

- [ ] **Step 1: Write the failing test**

Create `test/gita_dataset_test.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/gita_dataset"

class GitaDatasetTest < Minitest::Test
  def verses
    [{ "id" => 1, "chapter_number" => 1, "verse_number" => 1,
       "text" => "धर्म", "transliteration" => "dharma", "word_meanings" => "धर्म—dharma" }]
  end

  def translations
    [
      { "verse_id" => 1, "authorName" => "Swami Gambirananda", "lang" => "english", "description" => "Literal text" },
      { "verse_id" => 1, "authorName" => "Swami Sivananda", "lang" => "english", "description" => "Devotional text" },
      { "verse_id" => 1, "authorName" => "Swami Ramsukhdas", "lang" => "hindi", "description" => "हिंदी" }
    ]
  end

  def record
    GitaDataset.build(verses, translations,
                      literal_author: "Swami Gambirananda",
                      devotional_author: "Swami Sivananda").first
  end

  def test_basic_fields
    assert_equal 1, record["chapter"]
    assert_equal 1, record["verse"]
    assert_equal "धर्म", record["devanagari"]
    assert_equal "dharma", record["transliteration"]
    assert_equal "धर्म—dharma", record["word_meanings"]
  end

  def test_selects_named_english_translations
    assert_equal "Literal text", record["translations"]["literal"]
    assert_equal "Devotional text", record["translations"]["devotional"]
  end

  def test_audio_filename
    assert_equal "gita_1_1.mp3", record["audio_file"]
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `ruby test/gita_dataset_test.rb`
Expected: FAIL — `LoadError: cannot load such file -- ../lib/gita_dataset`.

- [ ] **Step 3: Implement**

Create `lib/gita_dataset.rb`:

```ruby
# frozen_string_literal: true

# Pure transform from the raw gita/gita upstream JSON into the slim per-verse
# records written to data/gita.json. No IO — fetch_gita.rb handles downloads and
# file writing and calls this. Translations are matched to verses by verse_id and
# filtered to the two named English authors (one literal, one devotional).
module GitaDataset
  module_function

  def build(verses, translations, literal_author:, devotional_author:)
    by_verse = Hash.new { |h, k| h[k] = {} }
    translations.each do |t|
      next unless t["lang"] == "english"

      by_verse[t["verse_id"]][t["authorName"]] = t["description"]
    end

    verses.map do |v|
      chapter = v["chapter_number"]
      verse   = v["verse_number"]
      authors = by_verse[v["id"]]

      {
        "chapter"         => chapter,
        "verse"           => verse,
        "devanagari"      => v["text"],
        "transliteration" => v["transliteration"],
        "word_meanings"   => v["word_meanings"],
        "translations"    => {
          "literal"    => authors[literal_author],
          "devotional" => authors[devotional_author]
        },
        "audio_file"      => "gita_#{chapter}_#{verse}.mp3"
      }
    end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `ruby test/gita_dataset_test.rb`
Expected: PASS (3 runs, 0 failures).

- [ ] **Step 5: Commit**

```bash
git add lib/gita_dataset.rb test/gita_dataset_test.rb
git commit -m "Add GitaDataset.build pure transform for gita.json records"
```

---

### Task 6: fetch_gita.rb — download dataset + audio, write gita.json

**Files:**
- Create: `fetch_gita.rb`

**Interfaces:**
- Consumes: `GitaDataset.build` (Task 5), `Paths::GITA_JSON`, `Paths::GITA_AUDIO_DIR` (Task 1).
- Produces: `data/gita.json` (array of verse records) and `data/gita_audio/gita_<ch>_<v>.mp3` files. This is a networked integration step; verification is by running it and checking outputs (no unit test — the pure logic it uses is covered by Task 5).

- [ ] **Step 1: Implement the script**

Create `fetch_gita.rb` (make it executable in Step 2):

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# Standalone networked fetch for the Bhagavad Gita verse deck. Downloads the
# gita/gita dataset (verses, English translations, chapter metadata) and the
# per-verse recitation MP3s, then writes data/gita.json + data/gita_audio/*.mp3.
#
# Like scrape_sanskrit.rb, this is the only networked step for its deck and is
# kept out of main.rb. The generator (lib/generators/gita_verses.rb) is a pure
# transform over data/gita.json. Re-running skips MP3s already on disk.
#
# Usage: ruby fetch_gita.rb

require "json"
require "fileutils"
require "open-uri"
require_relative "lib/paths"
require_relative "lib/gita_dataset"

RAW                = "https://raw.githubusercontent.com/gita/gita/main/data"
LITERAL_AUTHOR     = "Swami Gambirananda"
DEVOTIONAL_AUTHOR  = "Swami Sivananda"

def fetch_json(name)
  url = "#{RAW}/#{name}"
  puts "Fetching #{url} ..."
  JSON.parse(URI.parse(url).open(&:read))
end

verses       = fetch_json("verse.json")
translations = fetch_json("translation.json")
chapters     = fetch_json("chapters.json")

records = GitaDataset.build(
  verses, translations,
  literal_author: LITERAL_AUTHOR, devotional_author: DEVOTIONAL_AUTHOR
)
records.sort_by! { |r| [r["chapter"], r["verse"]] }

# Validate translation coverage before touching the network for audio.
missing = records.reject { |r| r["translations"]["literal"] && r["translations"]["devotional"] }
unless missing.empty?
  warn "ERROR: #{missing.size} verses are missing a literal or devotional translation."
  warn "First few: #{missing.first(5).map { |r| "#{r['chapter']}.#{r['verse']}" }.join(', ')}"
  abort "Check that LITERAL_AUTHOR/DEVOTIONAL_AUTHOR match authors present in translation.json."
end

# Validate per-chapter verse counts against chapters.json.
expected = chapters.to_h { |c| [c["chapter_number"], c["verses_count"]] }
actual   = records.group_by { |r| r["chapter"] }.transform_values(&:size)
expected.each do |chapter, count|
  got = actual[chapter] || 0
  warn "WARNING: chapter #{chapter}: expected #{count} verses, built #{got}" unless got == count
end

# Download recitation audio (skip files already present).
FileUtils.mkdir_p(Paths::GITA_AUDIO_DIR)
downloaded = 0
failed = []
records.each do |r|
  dest = File.join(Paths::GITA_AUDIO_DIR, r["audio_file"])
  next if File.exist?(dest) && File.size(dest).positive?

  url = "#{RAW}/verse_recitation/#{r['chapter']}/#{r['verse']}.mp3"
  begin
    data = URI.parse(url).open(&:read)
    File.binwrite(dest, data)
    downloaded += 1
    print "\r  downloaded #{downloaded} audio files ..."
  rescue OpenURI::HTTPError => e
    failed << "#{r['chapter']}.#{r['verse']} (#{e.message})"
  end
  sleep 0.1
end
puts ""
warn "WARNING: #{failed.size} audio files failed: #{failed.first(5).join(', ')}" unless failed.empty?

File.write(Paths::GITA_JSON, JSON.pretty_generate(records))

present_audio = records.count { |r| File.exist?(File.join(Paths::GITA_AUDIO_DIR, r["audio_file"])) }
puts ""
puts "Wrote #{records.size} verses to #{Paths::GITA_JSON}"
puts "Audio present: #{present_audio}/#{records.size} in #{Paths::GITA_AUDIO_DIR}"
puts "Next: ./main.rb --gita-verses"
```

- [ ] **Step 2: Make the script executable**

Run: `chmod +x fetch_gita.rb`

- [ ] **Step 3: Run it (real network download)**

Run: `ruby fetch_gita.rb`
Expected: prints the three "Fetching ..." lines, a download progress counter, then `Wrote 700 verses to .../data/gita.json` and `Audio present: 700/700`. (BG has 700 verses total; small count differences across editions are acceptable but should be near 700 with no chapter-count WARNINGs.)

- [ ] **Step 4: Verify the outputs**

Run:
```bash
ruby -rjson -e 'd=JSON.parse(File.read("data/gita.json")); puts d.size; r=d.first; puts r["chapter"], r["verse"], r["audio_file"]; puts r["translations"].keys.inspect; puts(r["translations"].values.all? { |v| v && !v.empty? })'
ls data/gita_audio | wc -l
file data/gita_audio/gita_1_1.mp3
```
Expected: count ~700; first record has `chapter`/`verse`/`audio_file` and both translation values non-empty (`true`); audio dir holds ~700 files; `gita_1_1.mp3` reports `MPEG ADTS, layer III` (real audio, not an LFS pointer).

- [ ] **Step 5: Ignore the audio blob in git, then commit the script**

Add to `.gitignore` (create if absent): `data/gita_audio/`

```bash
echo "data/gita_audio/" >> .gitignore
git add fetch_gita.rb .gitignore
git commit -m "Add fetch_gita.rb to download Gita dataset and recitation audio"
```

(`data/gita.json` is a generated data file; matching the repo's existing convention of committing `data/*.json`, add it too: `git add data/gita.json` before committing, unless the repo gitignores `data/`. Check `git status --porcelain data/` first; commit `data/gita.json` only if other `data/*.json` files are tracked.)

---

### Task 7: GitaVerses generator

**Files:**
- Create: `lib/generators/gita_verses.rb`
- Test: `test/gita_verses_test.rb`

**Interfaces:**
- Consumes: `Generators::Base` (Tasks 1-2), `Gita.load` (Task 4), `Anki::GITA_DECK`, `Paths::GITA_AUDIO_DIR`.
- Produces: `Generators::GitaVerses` — `KEY = "gita-verses"`; `card(entry)` → `["gita_verse:<ch>.<v>", front_html, back_html]`; `audio_files(data)` → array of `audio_file` strings; `deck == Anki::GITA_DECK`; `audio_dir == Paths::GITA_AUDIO_DIR`; `requires_letters? == false`.

- [ ] **Step 1: Write the failing test**

Create `test/gita_verses_test.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/gita_verses"

class GitaVersesTest < Minitest::Test
  def entry
    {
      "chapter"         => 1,
      "verse"           => 1,
      "devanagari"      => "धृतराष्ट्र उवाच\nधर्मक्षेत्रे कुरुक्षेत्रे",
      "transliteration" => "dhṛitarāśhtra uvācha\ndharma-kṣhetre",
      "translations"    => { "literal" => "Literal line", "devotional" => "Devotional line" },
      "audio_file"      => "gita_1_1.mp3"
    }
  end

  def gen = Generators::GitaVerses.new([], {})

  def test_deck_is_gita
    assert_equal Anki::GITA_DECK, gen.deck
  end

  def test_audio_dir_is_gita_audio
    assert_equal Paths::GITA_AUDIO_DIR, gen.audio_dir
  end

  def test_does_not_require_letters
    refute Generators::GitaVerses.requires_letters?
  end

  def test_card_key_and_front
    key, front, = gen.card(entry)
    assert_equal "gita_verse:1.1", key
    refute_includes front, "\n"
    assert_includes front, "<br>"
    assert_includes front, "धर्मक्षेत्रे"
    refute_includes front, "style="
  end

  def test_card_back_sections
    _key, _front, back = gen.card(entry)
    assert_includes back, "IAST"
    assert_includes back, "Literal line"
    assert_includes back, "Devotional line"
    assert_includes back, "[sound:gita_1_1.mp3]"
    refute_includes back, "\n"
    refute_includes back, "style="
  end

  def test_audio_files
    assert_equal ["gita_1_1.mp3"], gen.audio_files([entry])
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `ruby test/gita_verses_test.rb`
Expected: FAIL — `LoadError: cannot load such file -- ../lib/generators/gita_verses`.

- [ ] **Step 3: Implement**

Create `lib/generators/gita_verses.rb`:

```ruby
# frozen_string_literal: true

require_relative "base"
require_relative "../gita"

module Generators
  # Bhagavad Gita verses. Pure transform over data/gita.json (produced by
  # fetch_gita.rb). Targets its own deck (Anki::GITA_DECK), separate from the
  # alphabet. Each card:
  #   Front: the Devanagari shloka (large, centered)
  #   Back:  IAST transliteration + literal + devotional translation + recitation
  #
  # No OUTPUT_JSON: data/gita.json already is the structured intermediate, so a
  # second JSON file would just duplicate it.
  class GitaVerses < Base
    KEY         = "gita-verses"
    DESCRIPTION = "Bhagavad Gita verses (Devanagari -> IAST + translations + audio)"
    OUTPUT_TXT  = "sanskrit_gita_verses_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::GITA_DECK
    def audio_dir = Paths::GITA_AUDIO_DIR

    def build = Gita.load

    def card(entry)
      chapter = entry["chapter"]
      verse   = entry["verse"]
      key     = "gita_verse:#{chapter}.#{verse}"

      front = "<center><big>#{br(entry['devanagari'])}</big></center>"

      back = [
        "<b>IAST:</b><br>#{br(entry['transliteration'])}",
        "<b>Literal — Gambirananda:</b><br>#{br(entry.dig('translations', 'literal').to_s)}",
        "<b>Devotional — Sivananda:</b><br>#{br(entry.dig('translations', 'devotional').to_s)}",
        "[sound:#{entry['audio_file']}]"
      ].join("<br><br>")

      [key, front, back]
    end

    def audio_files(data)
      data.map { |entry| entry["audio_file"] }.compact
    end

    private

    # Convert source newlines to <br> so multi-line verses/prose render correctly
    # and never break the TSV row. (write_deck also flattens stray newlines.)
    def br(text)
      text.to_s.gsub(/\r?\n/, "<br>")
    end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `ruby test/gita_verses_test.rb`
Expected: PASS (7 runs, 0 failures).

- [ ] **Step 5: Commit**

```bash
git add lib/generators/gita_verses.rb test/gita_verses_test.rb
git commit -m "Add GitaVerses generator for the Bhagavad Gita verse deck"
```

---

### Task 8: Wire the generator into main.rb

**Files:**
- Modify: `main.rb:22-33` (requires + registry), `main.rb:71-73` (letters load), `main.rb:89-90` (audio copy), `main.rb:102` (deck message)

**Interfaces:**
- Consumes: `Generators::GitaVerses` (Task 7); `Base.requires_letters?`, result `:deck`/`:audio_dir`/`:audio_files` (Task 2); `Media.copy_audio(..., source_dir:)` (Task 3).

- [ ] **Step 1: Register the generator**

In `main.rb`, after line 25 (`require_relative "lib/generators/anusvara"`) add:

```ruby
require_relative "lib/generators/gita_verses"
```

In the `GENERATORS` array (lines 28-33) add `Generators::GitaVerses` as the last entry:

```ruby
GENERATORS = [
  Generators::Basic,
  Generators::Combinations,
  Generators::Conjuncts,
  Generators::Anusvara,
  Generators::GitaVerses
].freeze
```

- [ ] **Step 2: Load letters.json only when needed**

Replace lines 71-73:

```ruby
letters = Letters.load
letters_by_id = Letters.by_id(letters)
puts "Loaded #{letters.size} letters from #{Paths::LETTERS_JSON}"
puts
```

with:

```ruby
needs_letters = selected.any?(&:requires_letters?)
letters = needs_letters ? Letters.load : []
letters_by_id = needs_letters ? Letters.by_id(letters) : {}
if needs_letters
  puts "Loaded #{letters.size} letters from #{Paths::LETTERS_JSON}"
  puts
end
```

- [ ] **Step 3: Copy audio grouped by source directory**

Replace lines 87-90 (the audio comment + the single `Media.copy_audio` call):

```ruby
# Any category that emitted [sound:...] tags contributes audio to copy. Today
# only the basic alphabet does, but this stays data-driven for future categories.
audio_files = results.flat_map { |r| r[:audio_files] }
Media.copy_audio(audio_files) # dedups and skips when empty
```

with:

```ruby
# Categories that emitted [sound:...] tags contribute audio to copy, grouped by
# the source folder they live in (alphabet vs. Gita), so each is copied from the
# right directory. Stays data-driven — no category is hardcoded here.
results.group_by { |r| r[:audio_dir] }.each do |source_dir, group|
  files = group.flat_map { |r| r[:audio_files] }
  Media.copy_audio(files, source_dir: source_dir) # dedups and skips when empty
end
```

- [ ] **Step 4: Report the deck(s) used**

Replace line 102:

```ruby
puts "  4. Cards land in deck: #{Anki::DECK}"
```

with:

```ruby
puts "  4. Cards land in deck(s): #{results.map { |r| r[:deck] }.uniq.join(', ')}"
```

- [ ] **Step 5: Verify --list and a Gita-only run**

Run: `./main.rb --list`
Expected: lists all categories including `--gita-verses    Bhagavad Gita verses ...`.

Run: `./main.rb --gita-verses`
Expected: prints `Generating gita-verses...`, `~700 cards -> sanskrit_gita_verses_anki.txt`, then the Anki-media prompt for ~700 files sourced from `data/gita_audio`. Answer `n` for now. It must NOT print "Loaded N letters" (Gita doesn't require letters). No errors.

- [ ] **Step 6: Spot-check the generated file**

Run:
```bash
head -6 sanskrit_gita_verses_anki.txt
ruby -e 'l=File.readlines("sanskrit_gita_verses_anki.txt").reject{|x|x.start_with?("#")}; puts l.size; c=l[0].split("\t"); puts c.size; puts c[0]; puts c[1][0,60]; puts c[2][0,80]'
grep -c "	" sanskrit_gita_verses_anki.txt
```
Expected: header line 3 is `#deck:🕉️ Bhagavad Gita`; ~700 data lines; each row splits into exactly 3 columns; first column like `gita_verse:1.1`; front contains `<center><big>`; back contains `[sound:gita_1_1.mp3]`. No row should contain a raw newline (line count of data rows ≈ verse count).

- [ ] **Step 7: Commit**

```bash
git add main.rb
git commit -m "Wire GitaVerses into main.rb with per-deck audio copy and lazy letters load"
```

---

### Task 9: Documentation

**Files:**
- Modify: `CLAUDE.md`, `README.md`

**Interfaces:** none (docs only).

- [ ] **Step 1: Update CLAUDE.md commands**

In `CLAUDE.md`, in the Commands code block, add after the `scrape_sanskrit.rb` line:

```bash
ruby fetch_gita.rb                    # step 1b: fetch Bhagavad Gita verses + recitation mp3s -> data/
```

And add a line documenting tests near the "no tests" note — replace "There are no tests, linter, or build step." with:

```
Unit tests for the pure transforms and shared primitives live in `test/` (minitest, a Ruby default gem); run a file with `ruby test/<name>_test.rb`. There is no linter or build step.
```

- [ ] **Step 2: Add an architecture subsection to CLAUDE.md**

After the "### Combinations are computed, not scraped" section, add:

```markdown
### The Bhagavad Gita verse deck

A second deck (`🕉️ Bhagavad Gita`, the constant `Anki::GITA_DECK`) separate from the alphabet. `fetch_gita.rb` is a standalone networked script (sibling of `scrape_sanskrit.rb`) that downloads the [`gita/gita`](https://github.com/gita/gita) open dataset — `verse.json` (Devanagari `text`, IAST `transliteration`, word-by-word `word_meanings`), `translation.json` (multi-author English/Hindi), `chapters.json` — plus the per-verse recitation MP3s at `verse_recitation/<ch>/<v>.mp3`. It writes one slim record per verse to `data/gita.json` and the audio to `data/gita_audio/gita_<ch>_<v>.mp3` (skipping files already present). `GitaDataset.build` (`lib/gita_dataset.rb`) is the pure join/filter that selects the two configured English translations (literal = Swami Gambirananda, devotional = Swami Sivananda — change the constants at the top of `fetch_gita.rb` to swap). `word_meanings` is kept in `data/gita.json` though the verse deck doesn't use it, so a future word deck needs no re-fetch.

`lib/generators/gita_verses.rb` (`--gita-verses`) is a pure transform over `data/gita.json` (read via `Gita.load`): front is the Devanagari shloka, back is IAST + literal + devotional + `[sound:...]`. It overrides `deck`, `audio_dir` (→ `data/gita_audio`), and `requires_letters?` (→ false, so a Gita-only run needs no alphabet scrape). It writes no JSON intermediate — `data/gita.json` already is one. Multi-deck/multi-audio-folder support: `Anki.write_deck` takes a `deck:` kwarg, `Media.copy_audio` takes a `source_dir:` kwarg, and `main.rb` copies audio grouped by each generator's `audio_dir`.
```

- [ ] **Step 3: Update README.md**

In `README.md`, document the new step and deck. Add to the usage/quick-start section (adapt to the file's existing wording):

```markdown
### Bhagavad Gita verse deck

```bash
ruby fetch_gita.rb            # download verses + recitation audio -> data/
./main.rb --gita-verses       # generate sanskrit_gita_verses_anki.txt
```

Builds a separate **🕉️ Bhagavad Gita** deck: front = the Devanagari verse, back = IAST transliteration, a literal translation (Swami Gambirananda), a devotional translation (Swami Sivananda), and a recitation audio clip. Source: the open [gita/gita](https://github.com/gita/gita) dataset.
```

- [ ] **Step 4: Verify docs render and commit**

Run: `git diff --stat CLAUDE.md README.md`
Expected: both files modified.

```bash
git add CLAUDE.md README.md
git commit -m "Document the Bhagavad Gita verse deck and fetch step"
```

---

## Self-Review

**Spec coverage:**
- Source `gita/gita` dataset + translation pairing → Tasks 5, 6. ✓
- Per-verse recitation audio on back → Tasks 6 (download), 7 (`[sound:]`), 3 + 8 (copy). ✓
- Separate `🕉️ Bhagavad Gita` deck → Tasks 1 (constant), 2 (deck hook), 7, 8. ✓
- Verse card front Devanagari / back IAST + literal + devotional → Task 7. ✓
- `fetch_gita.rb` standalone, writes slim `data/gita.json`, keeps `word_meanings` → Tasks 5, 6. ✓
- `requires_letters?` lazy letters load → Tasks 2, 8. ✓
- Newline/TSV safety → Tasks 1 (writer guard), 7 (`br`). ✓
- Validation (counts, non-empty translations) → Task 6. ✓
- Word deck explicitly out of scope (future spec) → not planned here, by design. ✓
- Edge cases (multi-line text, prose newlines) → Tasks 1, 7. ✓

**Placeholder scan:** No TBD/TODO; every code step has complete code; commands have expected output. ✓

**Type consistency:** `Anki.write_deck(path, rows, deck:)`, `Media.copy_audio(filenames, source_dir:)`, `Gita.load(path)`, `GitaDataset.build(verses, translations, literal_author:, devotional_author:)`, record keys (`chapter`, `verse`, `devanagari`, `transliteration`, `word_meanings`, `translations`→`literal`/`devotional`, `audio_file`), generator `card`/`audio_files`/`deck`/`audio_dir`/`requires_letters?` — used consistently across Tasks 1-8. ✓

**Note on OUTPUT_JSON:** The spec mentioned a `gita_verses.json` intermediate; the plan omits it (YAGNI) because `data/gita.json` already is the structured per-verse record and a second file would duplicate it. Documented in Task 7's comment and CLAUDE.md.
