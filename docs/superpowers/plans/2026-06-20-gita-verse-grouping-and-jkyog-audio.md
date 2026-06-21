# Gita Verse Regrouping + JKYog Audio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Regroup the Bhagavad Gita verse deck to match bhagavadgita.com's canonical verse groups (one card per group) and switch verse audio to the clearer JKYog recitation, sourcing card text from the `gita/gita` dataset we already have.

**Architecture:** A hardcoded 49-entry grouping constant drives a new pure transform that merges the 701 per-verse records into 640 group-level card records. `fetch_gita.rb` downloads dataset text (as before), runs the merge, and downloads one JKYog MP3 per card by a deterministic URL (no scraping). The generator reads the group-level records.

**Tech Stack:** Ruby standard library (`json`, `open-uri`, `fileutils`); minitest (default gem) for tests.

## Global Constraints

- **JKYog audio base:** `https://gita-audio.jkyog.org/audio/sanskrit/gita_audios/`
- **Audio filename:** single = `{ch:03d}_{v:03d}.mp3`; group = `{ch:03d}_{start:03d}-{end:03d}.mp3`.
- **Local audio filename:** `gita_<chapter>_<verse_label>.mp3` (`gita_1_7.mp3`, `gita_1_4-6.mp3`), in `data/gita_audio/`.
- **Card count:** 701 verses → 640 cards (591 singles + 49 groups).
- **Translations:** literal = `Swami Gambirananda`; devotional = `Swami Sivananda` (already chosen, unchanged).
- **Card key:** `gita_verse:<chapter>.<verse_label>` (e.g. `gita_verse:1.7`, `gita_verse:1.4-6`).
- **Deck:** `🕉️ Bhagavad Gita` (unchanged).
- **TSV safety:** no inline `style=`; generator converts `\n`→`<br>`; writer flattens stray tabs/newlines.
- **Dataset raw base URL:** `https://raw.githubusercontent.com/gita/gita/main/data`
- **Run tests with:** `ruby test/<name>_test.rb`.
- **Branch:** `gita-jkyog-audio` (already checked out).

---

## File Structure

**Create:**
- `lib/gita_groups.rb` — `GITA_VERSE_GROUPS` constant + pure `build(per_verse_records)` → group-level card records.
- `test/gita_groups_test.rb`

**Modify:**
- `lib/jkyog_audio.rb` (currently uncommitted on this branch with a `naive_url`+`extract_url` draft) — keep `naive_url`, replace `extract_url` with `range_url`.
- `test/jkyog_audio_test.rb` — rewrite for `naive_url` + `range_url`.
- `fetch_gita.rb` — group-level records + JKYog audio download; drop the `gita/gita verse_recitation` download.
- `lib/generators/gita_verses.rb` — read merged fields; key uses `verse_label`.
- `test/gita_verses_test.rb` — group-level fixture + key.
- `data/gita.json` — regenerated group-level (committed).
- `sanskrit_gita_verses_anki.txt` — regenerated (committed).
- `CLAUDE.md`, `README.md` — document regrouping + JKYog audio.

**Unchanged:** `lib/gita_dataset.rb` (still yields 701 per-verse records; its `audio_file` key is simply not consumed), `lib/gita.rb`, `main.rb`, all alphabet code and shared plumbing.

---

### Task 1: JKYog audio URL helpers

**Files:**
- Modify: `lib/jkyog_audio.rb`
- Test: `test/jkyog_audio_test.rb`

**Interfaces:**
- Produces: `JkyogAudio::BASE`; `JkyogAudio.naive_url(chapter, verse)` → `"{BASE}/{ch:03d}_{v:03d}.mp3"`; `JkyogAudio.range_url(chapter, start, finish)` → `"{BASE}/{ch:03d}_{start:03d}-{finish:03d}.mp3"`.

- [ ] **Step 1: Replace the test file**

Overwrite `test/jkyog_audio_test.rb` with:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/jkyog_audio"

class JkyogAudioTest < Minitest::Test
  def test_naive_url_zero_pads
    assert_equal "https://gita-audio.jkyog.org/audio/sanskrit/gita_audios/002_047.mp3",
                 JkyogAudio.naive_url(2, 47)
    assert_equal "https://gita-audio.jkyog.org/audio/sanskrit/gita_audios/018_078.mp3",
                 JkyogAudio.naive_url(18, 78)
  end

  def test_range_url_zero_pads_both_bounds
    assert_equal "https://gita-audio.jkyog.org/audio/sanskrit/gita_audios/001_004-006.mp3",
                 JkyogAudio.range_url(1, 4, 6)
    assert_equal "https://gita-audio.jkyog.org/audio/sanskrit/gita_audios/013_008-012.mp3",
                 JkyogAudio.range_url(13, 8, 12)
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `ruby test/jkyog_audio_test.rb`
Expected: FAIL — `NoMethodError: undefined method 'range_url'`.

- [ ] **Step 3: Implement**

Overwrite `lib/jkyog_audio.rb` with:

```ruby
# frozen_string_literal: true

# JKYog (Swami Mukundananda) Bhagavad Gita recitation audio — clearer and higher
# quality (320 kbps) than the gita/gita repo's own verse_recitation files, and
# the source bhagavadgita.com uses.
#
# Single verses live at <chapter3>_<verse3>.mp3 (e.g. 002_047.mp3). Verses that
# Mukundananda's edition groups share one combined "range" file (e.g.
# 001_004-006.mp3). Which verses are grouped is captured in
# GitaGroups::GITA_VERSE_GROUPS, so both URLs are deterministic — no scraping at
# fetch time.
module JkyogAudio
  BASE = "https://gita-audio.jkyog.org/audio/sanskrit/gita_audios"

  module_function

  # Audio URL for a single (non-grouped) verse.
  def naive_url(chapter, verse)
    format("%s/%03d_%03d.mp3", BASE, chapter, verse)
  end

  # Audio URL for a grouped verse range (start..finish in one chapter).
  def range_url(chapter, start, finish)
    format("%s/%03d_%03d-%03d.mp3", BASE, chapter, start, finish)
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `ruby test/jkyog_audio_test.rb`
Expected: PASS (2 runs, 0 failures).

- [ ] **Step 5: Commit**

```bash
git add lib/jkyog_audio.rb test/jkyog_audio_test.rb
git commit -m "Add JkyogAudio naive_url/range_url helpers"
```

---

### Task 2: GitaGroups — grouping constant + merge transform

**Files:**
- Create: `lib/gita_groups.rb`
- Test: `test/gita_groups_test.rb`

**Interfaces:**
- Consumes: per-verse records (from `GitaDataset.build`): each a Hash with `"chapter"`, `"verse"` (ints), `"devanagari"`, `"transliteration"`, `"word_meanings"` (strings), `"translations" => {"literal", "devotional"}`.
- Produces: `GitaGroups::GITA_VERSE_GROUPS` (49 `[chapter, start, end]` arrays); `GitaGroups.build(per_verse_records)` → array of group-level card records, each: `"chapter"` (int), `"verse_label"` (String, `"7"` or `"4-6"`), `"verses"` (array of ints), `"devanagari"`/`"transliteration"` (merged strings), `"translations" => {"literal","devotional"}` (joined strings), `"word_meanings"` (array of per-verse strings), `"audio_file"` (String `gita_<ch>_<label>.mp3`). Input order is preserved; a group emits one card at its first member.

- [ ] **Step 1: Write the failing test**

Create `test/gita_groups_test.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/gita_groups"

class GitaGroupsTest < Minitest::Test
  def verse(ch, v, suffix)
    {
      "chapter" => ch, "verse" => v,
      "devanagari" => "DEV#{suffix}",
      "transliteration" => "iast#{suffix}",
      "translations" => { "literal" => "lit#{suffix}", "devotional" => "dev#{suffix}" },
      "word_meanings" => "wm#{suffix}"
    }
  end

  # chapter 1: verse 1 (single), verses 4-6 (a real group), verse 7 (single)
  def per_verse
    [verse(1, 1, 1), verse(1, 4, 4), verse(1, 5, 5), verse(1, 6, 6), verse(1, 7, 7)]
  end

  def cards = GitaGroups.build(per_verse)

  def test_card_count
    assert_equal 3, cards.size
  end

  def test_single_verse_passthrough
    c = cards.find { |x| x["verses"] == [1] }
    assert_equal "1", c["verse_label"]
    assert_equal "DEV1", c["devanagari"]
    assert_equal "lit1", c["translations"]["literal"]
    assert_equal ["wm1"], c["word_meanings"]
    assert_equal "gita_1_1.mp3", c["audio_file"]
  end

  def test_group_merge
    c = cards.find { |x| x["verse_label"] == "4-6" }
    assert_equal [4, 5, 6], c["verses"]
    assert_equal "DEV4\n\nDEV5\n\nDEV6", c["devanagari"]
    assert_equal "iast4\niast5\niast6", c["transliteration"]
    assert_equal "lit4 lit5 lit6", c["translations"]["literal"]
    assert_equal "dev4 dev5 dev6", c["translations"]["devotional"]
    assert_equal %w[wm4 wm5 wm6], c["word_meanings"]
    assert_equal "gita_1_4-6.mp3", c["audio_file"]
  end

  def test_order_preserved
    assert_equal [[1], [4, 5, 6], [7]], cards.map { |c| c["verses"] }
  end

  def test_groups_constant_is_well_formed
    g = GitaGroups::GITA_VERSE_GROUPS
    assert_equal 49, g.size
    covered = g.flat_map { |ch, s, e| (s..e).map { |v| [ch, v] } }
    assert_equal 110, covered.size
    assert_equal 110, covered.uniq.size, "groups must not overlap"
    assert(g.all? { |_ch, s, e| e >= s }, "every range must be non-empty")
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `ruby test/gita_groups_test.rb`
Expected: FAIL — `LoadError: cannot load such file -- ../lib/gita_groups`.

- [ ] **Step 3: Implement**

Create `lib/gita_groups.rb`:

```ruby
# frozen_string_literal: true

# Merges the 701 per-verse gita/gita records into bhagavadgita.com's canonical
# verse groups (one card per group). The grouping is hardcoded in
# GITA_VERSE_GROUPS — 49 [chapter, start, end] ranges discovered once from
# bhagavadgita.com (every grouped verse's page maps to a single combined JKYog
# audio clip, e.g. verses 1.4/1.5/1.6 all -> 001_004-006.mp3). Verified: these
# ranges cover exactly the 110 grouped verses with no gaps or overlaps; every
# other verse is its own single card.
#
# Pure transform — no IO. fetch_gita.rb calls this and then downloads one JKYog
# clip per card by the deterministic audio URL.
module GitaGroups
  GITA_VERSE_GROUPS = [
    [1, 4, 6], [1, 16, 18], [1, 21, 22], [1, 29, 31], [1, 32, 33], [1, 34, 35],
    [1, 36, 37], [1, 38, 39], [1, 45, 46], [2, 42, 43], [3, 1, 2], [3, 20, 21],
    [4, 29, 30], [5, 8, 9], [5, 27, 28], [6, 12, 13], [6, 24, 25], [6, 41, 42],
    [8, 1, 2], [8, 9, 10], [8, 23, 26], [9, 7, 8], [9, 16, 17], [10, 4, 5],
    [10, 12, 13], [10, 16, 17], [11, 10, 11], [11, 26, 27], [11, 28, 29],
    [11, 41, 42], [11, 52, 53], [12, 3, 4], [12, 6, 7], [12, 13, 14],
    [12, 18, 19], [13, 8, 12], [14, 3, 4], [14, 11, 13], [14, 14, 15],
    [14, 22, 23], [14, 24, 25], [15, 3, 4], [16, 1, 3], [16, 13, 15],
    [16, 19, 20], [17, 5, 6], [17, 26, 27], [18, 15, 16], [18, 51, 53]
  ].freeze

  module_function

  def build(per_verse)
    by_cv = per_verse.to_h { |r| [[r["chapter"], r["verse"]], r] }

    # (chapter, verse) -> [chapter, start, end] for grouped verses.
    group_of = {}
    GITA_VERSE_GROUPS.each do |ch, s, e|
      (s..e).each { |v| group_of[[ch, v]] = [ch, s, e] }
    end

    emitted = {}
    cards = []
    per_verse.each do |r|
      key = [r["chapter"], r["verse"]]
      group = group_of[key]
      if group
        next if emitted[group]

        emitted[group] = true
        ch, s, e = group
        members = (s..e).map { |v| by_cv[[ch, v]] }
        cards << merge_group(ch, s, e, members)
      else
        cards << single(r)
      end
    end
    cards
  end

  def single(r)
    {
      "chapter" => r["chapter"],
      "verse_label" => r["verse"].to_s,
      "verses" => [r["verse"]],
      "devanagari" => r["devanagari"],
      "transliteration" => r["transliteration"],
      "translations" => {
        "literal" => r.dig("translations", "literal"),
        "devotional" => r.dig("translations", "devotional")
      },
      "word_meanings" => [r["word_meanings"]],
      "audio_file" => "gita_#{r['chapter']}_#{r['verse']}.mp3"
    }
  end

  def merge_group(chapter, start, finish, members)
    {
      "chapter" => chapter,
      "verse_label" => "#{start}-#{finish}",
      "verses" => (start..finish).to_a,
      "devanagari" => members.map { |m| m["devanagari"] }.join("\n\n"),
      "transliteration" => members.map { |m| m["transliteration"] }.join("\n"),
      "translations" => {
        "literal" => members.map { |m| m.dig("translations", "literal").to_s }.join(" "),
        "devotional" => members.map { |m| m.dig("translations", "devotional").to_s }.join(" ")
      },
      "word_meanings" => members.map { |m| m["word_meanings"] },
      "audio_file" => "gita_#{chapter}_#{start}-#{finish}.mp3"
    }
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `ruby test/gita_groups_test.rb`
Expected: PASS (5 runs, 0 failures).

- [ ] **Step 5: Commit**

```bash
git add lib/gita_groups.rb test/gita_groups_test.rb
git commit -m "Add GitaGroups: hardcoded verse groups + merge transform"
```

---

### Task 3: Update the GitaVerses generator for group records

**Files:**
- Modify: `lib/generators/gita_verses.rb`
- Test: `test/gita_verses_test.rb`

**Interfaces:**
- Consumes: group-level records from `GitaGroups.build` (Task 2), loaded via `Gita.load`.
- Produces: `card(entry)` → `["gita_verse:<chapter>.<verse_label>", front, back]`; `audio_files(data)` unchanged (`data.map { |e| e["audio_file"] }`).

- [ ] **Step 1: Rewrite the test**

Overwrite `test/gita_verses_test.rb` with:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/gita_verses"

class GitaVersesTest < Minitest::Test
  def entry
    {
      "chapter"         => 1,
      "verse_label"     => "4-6",
      "verses"          => [4, 5, 6],
      "devanagari"      => "अत्र शूरा\n\nधृष्टकेतु\n\nयुधामन्यु",
      "transliteration" => "atra śhūrā\ndhṛiṣhṭaketu\nyudhāmanyu",
      "translations"    => { "literal" => "Here are heroes...", "devotional" => "Behold the warriors..." },
      "word_meanings"   => ["wm4", "wm5", "wm6"],
      "audio_file"      => "gita_1_4-6.mp3"
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

  def test_card_key_uses_verse_label
    key, front, = gen.card(entry)
    assert_equal "gita_verse:1.4-6", key
    refute_includes front, "\n"
    assert_includes front, "<br>"
    assert_includes front, "अत्र शूरा"
    refute_includes front, "style="
  end

  def test_card_back_sections
    _key, _front, back = gen.card(entry)
    assert_includes back, "IAST"
    assert_includes back, "Here are heroes..."
    assert_includes back, "Behold the warriors..."
    assert_includes back, "[sound:gita_1_4-6.mp3]"
    refute_includes back, "\n"
    refute_includes back, "style="
  end

  def test_audio_files
    assert_equal ["gita_1_4-6.mp3"], gen.audio_files([entry])
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `ruby test/gita_verses_test.rb`
Expected: FAIL — `test_card_key_uses_verse_label` expects `gita_verse:1.4-6` but the current generator builds the key from `entry["verse"]` (now absent → `gita_verse:1.`).

- [ ] **Step 3: Implement**

In `lib/generators/gita_verses.rb`, replace the `card` method with:

```ruby
    def card(entry)
      chapter = entry["chapter"]
      label   = entry["verse_label"]
      key     = "gita_verse:#{chapter}.#{label}"

      front = "<center><big>#{br(entry['devanagari'])}</big></center>"

      back = [
        "<b>IAST:</b><br>#{br(entry['transliteration'])}",
        "<b>Literal — Gambirananda:</b><br>#{br(entry.dig('translations', 'literal').to_s)}",
        "<b>Devotional — Sivananda:</b><br>#{br(entry.dig('translations', 'devotional').to_s)}",
        "[sound:#{entry['audio_file']}]"
      ].join("<br><br>")

      [key, front, back]
    end
```

(The `build`, `audio_files`, `deck`, `audio_dir`, `requires_letters?`, and `br` members stay as they are.)

- [ ] **Step 4: Run test to verify it passes**

Run: `ruby test/gita_verses_test.rb`
Expected: PASS (6 runs, 0 failures).

- [ ] **Step 5: Commit**

```bash
git add lib/generators/gita_verses.rb test/gita_verses_test.rb
git commit -m "GitaVerses: key/card from group-level verse_label fields"
```

---

### Task 4: Rework fetch_gita.rb for grouped records + JKYog audio

**Files:**
- Modify: `fetch_gita.rb` (full rewrite)
- Regenerates: `data/gita.json` (group-level), `data/gita_audio/*.mp3`

**Interfaces:**
- Consumes: `GitaDataset.build` (per-verse), `GitaGroups.build` (Task 2), `JkyogAudio.naive_url`/`range_url` (Task 1), `Paths::GITA_JSON`/`GITA_AUDIO_DIR`.
- Produces: group-level `data/gita.json` and one JKYog MP3 per card.

- [ ] **Step 1: Replace the script**

Overwrite `fetch_gita.rb` with:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# Standalone networked fetch for the Bhagavad Gita verse deck.
#
# Text comes from the gita/gita open dataset; verses are merged into
# bhagavadgita.com's canonical groups (GitaGroups), and audio is the JKYog
# (Swami Mukundananda) recitation — one clip per card, by a deterministic URL
# (no scraping). Writes data/gita.json (group-level) + data/gita_audio/*.mp3.
#
# Like scrape_sanskrit.rb, this is the only networked step for its deck and is
# kept out of main.rb. Re-running skips MP3s already on disk; to re-download
# after changing the audio source, clear data/gita_audio/ first.
#
# Usage: ruby fetch_gita.rb

require "json"
require "fileutils"
require "open-uri"
require_relative "lib/paths"
require_relative "lib/gita_dataset"
require_relative "lib/gita_groups"
require_relative "lib/jkyog_audio"

RAW               = "https://raw.githubusercontent.com/gita/gita/main/data"
LITERAL_AUTHOR    = "Swami Gambirananda"
DEVOTIONAL_AUTHOR = "Swami Sivananda"
UA                = "Mozilla/5.0 (compatible; anki-sanskrit/1.0)"

def fetch_json(name)
  url = "#{RAW}/#{name}"
  puts "Fetching #{url} ..."
  JSON.parse(URI.parse(url).open(&:read))
end

def http_get(url)
  URI.parse(url).open("User-Agent" => UA, &:read)
rescue OpenURI::HTTPError
  nil
end

# Deterministic JKYog URL for a card: single verse -> naive, group -> range.
def audio_url_for(card)
  verses = card["verses"]
  if verses.size == 1
    JkyogAudio.naive_url(card["chapter"], verses.first)
  else
    JkyogAudio.range_url(card["chapter"], verses.first, verses.last)
  end
end

verses       = fetch_json("verse.json")
translations = fetch_json("translation.json")
chapters     = fetch_json("chapters.json")

per_verse = GitaDataset.build(
  verses, translations,
  literal_author: LITERAL_AUTHOR, devotional_author: DEVOTIONAL_AUTHOR
)
per_verse.sort_by! { |r| [r["chapter"], r["verse"]] }

cards = GitaGroups.build(per_verse)

# Validate translation coverage before touching the network for audio.
missing = cards.reject { |c| c.dig("translations", "literal") && c.dig("translations", "devotional") }
unless missing.empty?
  warn "ERROR: #{missing.size} cards missing a literal or devotional translation."
  warn "First few: #{missing.first(5).map { |c| "#{c['chapter']}.#{c['verse_label']}" }.join(', ')}"
  abort "Check LITERAL_AUTHOR/DEVOTIONAL_AUTHOR against translation.json."
end

# Validate per-chapter verse counts (sum of card verses) against chapters.json.
expected = chapters.to_h { |c| [c["chapter_number"], c["verses_count"]] }
actual   = cards.group_by { |c| c["chapter"] }.transform_values { |cs| cs.sum { |c| c["verses"].size } }
expected.each do |chapter, count|
  got = actual[chapter] || 0
  warn "WARNING: chapter #{chapter}: expected #{count} verses, built #{got}" unless got == count
end

# Download JKYog audio, one clip per card (skip files already present).
FileUtils.mkdir_p(Paths::GITA_AUDIO_DIR)
downloaded = 0
failed = []
cards.each do |card|
  dest = File.join(Paths::GITA_AUDIO_DIR, card["audio_file"])
  next if File.exist?(dest) && File.size(dest).positive?

  data = http_get(audio_url_for(card))
  if data
    File.binwrite(dest, data)
    downloaded += 1
    print "\r  downloaded #{downloaded} audio files ..."
  else
    failed << "#{card['chapter']}.#{card['verse_label']}"
  end
  sleep 0.1
end
puts ""
warn "WARNING: #{failed.size} audio downloads failed: #{failed.first(5).join(', ')}" unless failed.empty?

File.write(Paths::GITA_JSON, JSON.pretty_generate(cards))

present = cards.count { |c| File.exist?(File.join(Paths::GITA_AUDIO_DIR, c["audio_file"])) }
puts ""
puts "Wrote #{cards.size} cards to #{Paths::GITA_JSON}"
puts "Audio present: #{present}/#{cards.size} in #{Paths::GITA_AUDIO_DIR}"
puts "Next: ./main.rb --gita-verses"
```

- [ ] **Step 2: Clear the obsolete per-verse audio**

The old `gita_<ch>_<v>.mp3` files would be skipped by the "already present" guard, so remove them before re-fetching:

Run: `rm -rf data/gita_audio && echo cleared`
Expected: `cleared`

- [ ] **Step 3: Run the fetch (real network download)**

Run: `ruby fetch_gita.rb`
Expected: three "Fetching ..." lines, a download counter, then `Wrote 640 cards to .../data/gita.json` and `Audio present: 640/640`, with no chapter-count WARNINGs and no failed downloads.

- [ ] **Step 4: Verify the outputs**

Run:
```bash
ruby -rjson -e 'd=JSON.parse(File.read("data/gita.json")); puts d.size; g=d.find{|x|x["verse_label"]=="4-6"&&x["chapter"]==1}; puts g["verses"].inspect; puts g["audio_file"]; puts g["devanagari"].include?("\n"); puts(d.all?{|c| c["translations"]["literal"]&&!c["translations"]["literal"].empty?})'
ls data/gita_audio | wc -l
file data/gita_audio/gita_1_4-6.mp3
file data/gita_audio/gita_1_7.mp3
```
Expected: count `640`; the 1.4-6 card has `verses` `[4, 5, 6]`, `audio_file` `gita_1_4-6.mp3`, Devanagari contains a newline (`true`), and all cards have a non-empty literal translation (`true`); ~640 audio files; both `gita_1_4-6.mp3` and `gita_1_7.mp3` report `MPEG ADTS ... layer III` at high bitrate (real JKYog audio).

- [ ] **Step 5: Commit**

```bash
git add fetch_gita.rb data/gita.json
git commit -m "fetch_gita: group-level records + JKYog per-card audio"
```

---

### Task 5: Regenerate the deck and verify

**Files:**
- Regenerates: `sanskrit_gita_verses_anki.txt`

- [ ] **Step 1: Regenerate (decline the audio copy for now)**

Run: `printf 'n\n' | ./main.rb --gita-verses`
Expected: `Generating gita-verses...`, `640 cards -> sanskrit_gita_verses_anki.txt`, the audio prompt for ~640 files from `data/gita_audio`, deck `🕉️ Bhagavad Gita`. No "Loaded N letters" line. No errors.

- [ ] **Step 2: Spot-check the file**

Run:
```bash
ruby -e 'l=File.readlines("sanskrit_gita_verses_anki.txt").reject{|x|x.start_with?("#")}; puts "rows=#{l.size}"; puts "bad_cols=#{l.count{|r| r.split("\t").size != 3}}"; row=l.find{|r| r.start_with?("gita_verse:1.4-6\t")}; c=row.split("\t"); puts c[0]; puts c[2][-45..]'
grep -m1 '^#deck' sanskrit_gita_verses_anki.txt
```
Expected: `rows=640`; `bad_cols=0`; the 1.4-6 row's key is `gita_verse:1.4-6` and its back ends with `[sound:gita_1_4-6.mp3]`; deck header `#deck:🕉️ Bhagavad Gita`.

- [ ] **Step 3: Run the full test suite**

Run: `for f in test/*_test.rb; do ruby "$f" 2>&1 | tail -1; done`
Expected: every file reports `0 failures, 0 errors`.

- [ ] **Step 4: Commit**

```bash
git add sanskrit_gita_verses_anki.txt
git commit -m "Regenerate Gita verse deck with grouped cards"
```

---

### Task 6: Documentation

**Files:**
- Modify: `CLAUDE.md`, `README.md`

- [ ] **Step 1: Update the CLAUDE.md Gita section**

In `CLAUDE.md`, replace the body of the "### The Bhagavad Gita verse deck" section's audio/structure description so it reads (keep the surrounding section heading):

Replace the sentence describing audio and the per-verse generator with text stating:
- Audio is the **JKYog (Swami Mukundananda) recitation** from `https://gita-audio.jkyog.org/audio/sanskrit/gita_audios/` (320 kbps), not the gita/gita `verse_recitation` files.
- Verses are merged into **bhagavadgita.com's canonical groups** via the hardcoded `GitaGroups::GITA_VERSE_GROUPS` (49 `[chapter,start,end]` ranges, covering exactly the 110 grouped verses); 701 verses → **640 cards**.
- `data/gita.json` is **group-level**: `chapter`, `verse_label` ("4-6"/"7"), `verses[]`, merged `devanagari`/`transliteration`/`translations`, per-verse `word_meanings[]`, `audio_file`.
- Audio filename is `gita_<ch>_<verse_label>.mp3`; the JKYog URL is deterministic (`JkyogAudio.naive_url`/`range_url`), so `fetch_gita.rb` does **not** scrape.

Concretely, replace the two paragraphs under that heading with:

```markdown
A second deck (`🕉️ Bhagavad Gita`, the constant `Anki::GITA_DECK`) separate from the alphabet. `fetch_gita.rb` is a standalone networked script (sibling of `scrape_sanskrit.rb`) that downloads the [`gita/gita`](https://github.com/gita/gita) open dataset — `verse.json` (Devanagari `text`, IAST `transliteration`, word-by-word `word_meanings`), `translation.json` (multi-author English/Hindi), `chapters.json`. `GitaDataset.build` (`lib/gita_dataset.rb`) is the pure join/filter that selects the two configured English translations (literal = Swami Gambirananda, devotional = Swami Sivananda — change the constants at the top of `fetch_gita.rb`).

Verses are then merged into **bhagavadgita.com's canonical groups** by `GitaGroups.build` (`lib/gita_groups.rb`), driven by the hardcoded `GITA_VERSE_GROUPS` — 49 `[chapter, start, end]` ranges (e.g. `[1,4,6]`) that Swami Mukundananda's edition combines, covering exactly the 110 grouped verses with no gaps/overlaps. 701 verses → **640 cards** (591 singles + 49 groups). `data/gita.json` is therefore **group-level**: each record has `chapter`, `verse_label` (`"4-6"`/`"7"`), `verses[]`, merged `devanagari`/`transliteration`/`translations`, per-verse `word_meanings[]` (kept for a future word deck), and `audio_file`.

Audio is the **JKYog (Swami Mukundananda) recitation** (`https://gita-audio.jkyog.org/audio/sanskrit/gita_audios/`, 320 kbps — clearer than the gita/gita `verse_recitation` files). Each card maps to one clip by a deterministic URL — `JkyogAudio.naive_url(ch,v)` (`002_047.mp3`) for singles, `JkyogAudio.range_url(ch,s,e)` (`001_004-006.mp3`) for groups (`lib/jkyog_audio.rb`) — so `fetch_gita.rb` never scrapes. MP3s download to `data/gita_audio/gita_<ch>_<verse_label>.mp3` (gitignored; skipped if already present — clear the folder to re-download after a source change).

`lib/generators/gita_verses.rb` (`--gita-verses`) is a pure transform over the group-level `data/gita.json` (read via `Gita.load`): key `gita_verse:<ch>.<verse_label>`, front is the merged Devanagari shloka(s), back is IAST + literal + devotional + `[sound:...]`. It overrides `deck`, `audio_dir` (→ `data/gita_audio`), and `requires_letters?` (→ false). Multi-deck/multi-audio-folder support in shared code: `Anki.write_deck` takes a `deck:` kwarg, `Media.copy_audio` takes a `source_dir:` kwarg, and `main.rb` copies audio grouped by each generator's `audio_dir`.
```

- [ ] **Step 2: Update README.md**

In `README.md`, in the `--gita-verses` table row and the "Bhagavad Gita verse deck" section, update the card count to **640** and the description to note grouped cards + JKYog audio. Replace the existing `--gita-verses` table row with:

```markdown
| `--gita-verses` | `sanskrit_gita_verses_anki.txt` | 640 | Bhagavad Gita verses (separate **🕉️ Bhagavad Gita** deck), grouped to match bhagavadgita.com, with JKYog recitation **audio**. Requires running `fetch_gita.rb` first — see below. |
```

And in the "Bhagavad Gita verse deck" prose, replace the description paragraph with:

```markdown
`fetch_gita.rb` is a standalone networked step (like `scrape_sanskrit.rb`) that downloads the open [gita/gita](https://github.com/gita/gita) dataset, merges verses into bhagavadgita.com's canonical groups (e.g. 1.4–6 become one card), and downloads the JKYog (Swami Mukundananda) recitation mp3s into `data/gita.json` + `data/gita_audio/` (re-running skips files already downloaded; clear the folder to re-download). Then `./main.rb --gita-verses` builds the **🕉️ Bhagavad Gita** deck: front = the Devanāgarī verse(s); back = IAST transliteration, a literal translation (Swami Gambirananda), a devotional translation (Swami Sivananda), and a recitation audio clip.
```

- [ ] **Step 3: Verify and commit**

Run: `git diff --stat CLAUDE.md README.md`
Expected: both files modified.

```bash
git add CLAUDE.md README.md
git commit -m "Document Gita verse regrouping and JKYog audio"
```

---

## Self-Review

**Spec coverage:**
- JKYog audio URLs (single + range) → Task 1. ✓
- Hardcoded 49-group constant + merge transform (640 cards, per-verse word_meanings) → Task 2. ✓
- Generator reads group fields / `verse_label` key → Task 3. ✓
- fetch_gita.rb: group-level records, deterministic JKYog download, drop old recitation, group-level gita.json, validation → Task 4. ✓
- Clear obsolete audio before re-fetch → Task 4 Step 2. ✓
- Regenerate + verify deck (640 rows) → Task 5. ✓
- Docs → Task 6. ✓
- Translations joined for groups → Task 2 `merge_group`. ✓
- `gita_dataset.rb`/`gita.rb`/`main.rb` unchanged → reflected in File Structure. ✓

**Placeholder scan:** No TBD/TODO; all code steps show complete code; commands have expected output. ✓

**Type consistency:** `JkyogAudio.naive_url(chapter, verse)` / `range_url(chapter, start, finish)`; `GitaGroups.build(per_verse)` returning records with keys `chapter`/`verse_label`/`verses`/`devanagari`/`transliteration`/`translations`/`word_meanings`/`audio_file`; generator reads `verse_label` + `audio_file`; fetch's `audio_url_for(card)` uses `card["verses"]`/`card["chapter"]`. Consistent across Tasks 1–4. ✓
