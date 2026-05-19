#!/usr/bin/env ruby
# frozen_string_literal: true

# Script 3: Generate Anki flashcards for Sanskrit consonant + vowel combinations
# and vowel + anusvara/visarga combinations.
#
# Reads data/letters.json (produced by scrape_sanskrit.rb) and writes:
#   data/combinations.json          - every consonant × vowel pair
#   data/anusvara_visarga.json      - every non-'a' vowel × {anusvara, visarga}
#   sanskrit_combinations_anki.txt  - single Anki import file with all cards above
#
# The combinations themselves are deterministic Unicode: a consonant's
# Devanagari + the vowel's combining matra yields the combined glyph, and the
# IAST follows by replacing the consonant's trailing 'a' with the vowel's IAST.
# Anusvara/visarga simply append U+0902 / U+0903 to the bare vowel.
# No scraping required.
#
# Usage:
#   bundle exec ruby generate_combinations_anki.rb

require "json"
require "fileutils"

DATA_DIR              = File.join(__dir__, "data")
LETTERS_JSON          = File.join(DATA_DIR, "letters.json")
COMBINATIONS_JSON     = File.join(DATA_DIR, "combinations.json")
ANUSVARA_VISARGA_JSON = File.join(DATA_DIR, "anusvara_visarga.json")
OUTPUT_FILE           = File.join(__dir__, "sanskrit_combinations_anki.txt")
DECK_NAME             = "🕉️ Sanskrit Alphabet"

# Vowels in barakhadi order. The inherent 'a' is omitted — bare consonants
# already carry it and live in the basic alphabet deck.
VOWEL_IDS = %w[aa i ii u uu RRi RRI LLi e ai o au aM aH].freeze

# Vowel ID -> combining matra (the sign that attaches to a consonant).
# anusvara/visarga are not strictly matras but are included for completeness:
# they sit on top of the inherent 'a' rather than replacing it.
VOWEL_MATRAS = {
  "aa"  => "ा",
  "i"   => "ि",
  "ii"  => "ी",
  "u"   => "ु",
  "uu"  => "ू",
  "RRi" => "ृ",
  "RRI" => "ॄ",
  "LLi" => "ॢ",
  "e"   => "े",
  "ai"  => "ै",
  "o"   => "ो",
  "au"  => "ौ",
  "aM"  => "ं",
  "aH"  => "ः"
}.freeze

# Consonants in traditional alphabet order, including the two conjuncts.
CONSONANT_IDS = %w[
  ka kha ga gha GNa
  ca cha ja jha JNa
  Ta Tha Da Dha Na
  ta tha da dha na
  pa pha ba bha ma
  ya ra la va
  sha Sha sa ha
  kSha jJNa
].freeze

# Vowels eligible for the anusvara/visarga file. The bare 'a' is omitted —
# aṁ (अं) and aḥ (अः) already live in letters.json as aM and aH.
NON_A_VOWEL_IDS = %w[aa i ii u uu RRi RRI LLi e ai o au].freeze

# Anusvara / visarga marks that attach to a standalone vowel.
# Roman uses ṁ (dot above) to match the existing aM convention in letters.json.
VOWEL_MARKS = {
  "M" => { char: "ं", roman: "ṁ" },
  "H" => { char: "ः", roman: "ḥ" }
}.freeze

def build_combinations(letters_by_id)
  combos = []
  CONSONANT_IDS.each do |cid|
    consonant = letters_by_id.fetch(cid)
    VOWEL_IDS.each do |vid|
      vowel = letters_by_id.fetch(vid)
      matra = VOWEL_MATRAS.fetch(vid)

      combos << {
        "id"           => "#{cid}_#{vid}",
        "consonant_id" => cid,
        "vowel_id"     => vid,
        "devanagari"   => consonant["devanagari"] + matra,
        "roman"        => consonant["roman"].sub(/a\z/, vowel["roman"])
      }
    end
  end
  combos
end

def build_vowel_marks(letters_by_id)
  combos = []
  NON_A_VOWEL_IDS.each do |vid|
    vowel = letters_by_id.fetch(vid)
    VOWEL_MARKS.each do |mid, info|
      combos << {
        "id"         => "#{vid}_#{mid}",
        "vowel_id"   => vid,
        "mark_id"    => mid,
        "devanagari" => vowel["devanagari"] + info[:char],
        "roman"      => vowel["roman"] + info[:roman]
      }
    end
  end
  combos
end

def write_json(path, data)
  File.write(path, JSON.pretty_generate(data))
  puts "  Wrote #{data.size} entries to #{path}"
end

# Standalone Devanagari letters that compose a combination, shown on the back.
# Anusvara/visarga are rendered on U+25CC (◌) so the bare mark is visible —
# the letters.json forms अं/अः include a spurious 'a' and would mislead.
def components_devanagari(entry, letters_by_id)
  if entry.key?("mark_id")
    [letters_by_id.fetch(entry["vowel_id"])["devanagari"],
     "◌#{VOWEL_MARKS.fetch(entry["mark_id"])[:char]}"]
  else
    consonant_char = letters_by_id.fetch(entry["consonant_id"])["devanagari"]
    vowel_id       = entry["vowel_id"]
    vowel_char =
      case vowel_id
      when "aM" then "◌ं"
      when "aH" then "◌ः"
      else letters_by_id.fetch(vowel_id)["devanagari"]
      end
    [consonant_char, vowel_char]
  end
end

def write_anki_file(path, entries, letters_by_id)
  File.open(path, "w:UTF-8") do |f|
    f.puts "#separator:Tab"
    f.puts "#html:true"
    f.puts "#deck:#{DECK_NAME}"
    f.puts "#notetype:Basic"
    f.puts "#columns:Key\tFront\tBack"
    f.puts "#guid column:1"

    entries.each do |entry|
      key       = entry["id"]
      front     = "<center><big><big><big><big><big>#{entry["devanagari"]}</big></big></big></big></big></center>"
      breakdown = components_devanagari(entry, letters_by_id).join(" + ")
      back      = "<center><big><big><b>#{entry["roman"]}</b></big></big><br><big>#{breakdown}</big></center>"
      f.puts "#{key}\t#{front}\t#{back}"
    end
  end

  puts "  Wrote #{entries.size} cards to #{path}"
end

# --- Main ---
puts "=== Sanskrit Combinations Anki Generator ==="
puts

unless File.exist?(LETTERS_JSON)
  puts "ERROR: #{LETTERS_JSON} not found."
  puts "Run `bundle exec ruby scrape_sanskrit.rb` first."
  exit 1
end

letters = JSON.parse(File.read(LETTERS_JSON))
letters_by_id = letters.to_h { |l| [l["id"], l] }
puts "Loaded #{letters.size} letters from #{LETTERS_JSON}"
puts

puts "Step 1: Building consonant + vowel combinations..."
combos = build_combinations(letters_by_id)
write_json(COMBINATIONS_JSON, combos)
puts

puts "Step 2: Building vowel + anusvara/visarga combinations..."
vowel_marks = build_vowel_marks(letters_by_id)
write_json(ANUSVARA_VISARGA_JSON, vowel_marks)
puts

puts "Step 3: Writing combined Anki import file..."
write_anki_file(OUTPUT_FILE, combos + vowel_marks, letters_by_id)

puts
puts "=== Done! ==="
puts
puts "To import into Anki:"
puts "  1. Open Anki"
puts "  2. File > Import"
puts "  3. Select: #{OUTPUT_FILE}"
puts "  4. Cards will land in deck: #{DECK_NAME}"
