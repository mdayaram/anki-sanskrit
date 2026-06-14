#!/usr/bin/env ruby
# frozen_string_literal: true

# Script 5: Generate Anki flashcards for anusvāra (ं) pronunciation.
#
# Reads data/letters.json (produced by scrape_sanskrit.rb) and writes:
#   data/anusvara.json          - one entry per following consonant
#   sanskrit_anusvara_anki.txt  - Anki import file for them
#
# Anusvāra's sound is conditioned by the FOLLOWING consonant, not the syllable it
# is written on. Before a stop it becomes the nasal homorganic with that stop's
# articulation class — the fifth (nasal) letter of the varga:
#   guttural क-varga → ṅ,  palatal च-varga → ñ,  retroflex ट-varga → ṇ,
#   dental त-varga → n,    labial प-varga → m.
# Before a semivowel (य र ल व), sibilant (श ष स) or ह there is no homorganic stop
# nasal, so the anusvāra stays a nasalised vowel (the "true" anusvāra).
#
# So the useful cards are not the syllable it rides on but one per *following*
# consonant: front shows ◌ं + that consonant, back gives the resulting sound and
# an example. (Recognition of the written mark on a syllable — कं, कः — already
# lives in the combinations deck.) Rules verified against Wikipedia "Anusvara"
# and ashtangayoga.info; assimilation is by articulation class.
#
# Usage:
#   bundle exec ruby generate_anusvara_anki.rb

require "json"
require "fileutils"

DATA_DIR     = File.join(__dir__, "data")
LETTERS_JSON = File.join(DATA_DIR, "letters.json")
OUTPUT_JSON  = File.join(DATA_DIR, "anusvara.json")
OUTPUT_FILE  = File.join(__dir__, "sanskrit_anusvara_anki.txt")
DECK_NAME    = "🕉️ Sanskrit Alphabet"
ANUSVARA     = "ं"

# The anusvara/visarga marks themselves. Roman uses ṁ (dot above) to match the
# aM convention in letters.json.
MARKS = {
  "M" => { char: "ं", roman: "ṁ", name: "anusvāra" },
  "H" => { char: "ः", roman: "ḥ", name: "visarga" }
}.freeze

# Independent vowel + mark recognition cards, [vowel_id, mark_id]. These are the
# only standalone vowel+mark forms attested in the Mahābhārata (अं/अः already
# live in letters.json); the full grid is overwhelmingly unattested, so the marks
# normally ride on consonant syllables (कं, कः in the combinations deck) instead.
INDEPENDENT_MARKS = [
  %w[o M],   # ओं oṁ — 34 occurrences
  %w[aa H],  # आः āḥ — 2
  %w[i M]    # इं iṁ — 1
].freeze

# Each following-consonant group and how anusvāra is realised before it.
#   :nasal_id  -> assimilates to this varga nasal (a letters.json id)
#   :nasalized -> no stop nasal; stays a nasalised vowel
# Members are listed in alphabet order; one card is generated per member.
ANUSVARA_RULES = [
  { klass: "guttural (क-varga)",  members: %w[ka kha ga gha GNa], nasal_id: "GNa",
    example: { dev: "शंकर", iast: "śaṃkara", pron: "śaṅkara" } },
  { klass: "palatal (च-varga)",   members: %w[ca cha ja jha JNa], nasal_id: "JNa",
    example: { dev: "संचय", iast: "saṃcaya", pron: "sañcaya" } },
  { klass: "retroflex (ट-varga)", members: %w[Ta Tha Da Dha Na], nasal_id: "Na",
    example: { dev: "घंटा", iast: "ghaṃṭā", pron: "ghaṇṭā" } },
  { klass: "dental (त-varga)",    members: %w[ta tha da dha na], nasal_id: "na",
    example: { dev: "संतोष", iast: "saṃtoṣa", pron: "santoṣa" } },
  { klass: "labial (प-varga)",    members: %w[pa pha ba bha ma], nasal_id: "ma",
    example: { dev: "संपूर्ण", iast: "saṃpūrṇa", pron: "sampūrṇa" } },
  { klass: "semivowel",           members: %w[ya ra la va], nasalized: true,
    example: { dev: "संयोग", iast: "saṃyoga", pron: "saṃyoga (nasalised a)" } },
  { klass: "sibilant",            members: %w[sha Sha sa], nasalized: true,
    example: { dev: "संस्कृत", iast: "saṃskṛta", pron: "saṃskṛta (nasalised a)" } },
  { klass: "aspirate ह",          members: %w[ha], nasalized: true,
    example: { dev: "सिंह", iast: "siṃha", pron: "siṃha (nasalised i)" } }
].freeze

def onset(letter)
  letter["roman"].sub(/a\z/, "")
end

# Recognition cards for the few attested standalone vowel+mark glyphs.
def build_independent(letters_by_id)
  INDEPENDENT_MARKS.map do |vid, mid|
    vowel = letters_by_id.fetch(vid)
    mark  = MARKS.fetch(mid)
    {
      "type"             => "independent",
      "id"               => "indep_#{vid}_#{mid}",
      "vowel_id"         => vid,
      "vowel_devanagari" => vowel["devanagari"],
      "vowel_roman"      => vowel["roman"],
      "mark_id"          => mid,
      "devanagari"       => vowel["devanagari"] + mark[:char],
      "roman"            => vowel["roman"] + mark[:roman]
    }
  end
end

def build_entries(letters_by_id)
  entries = []
  ANUSVARA_RULES.each do |rule|
    rule[:members].each do |cid|
      cons = letters_by_id.fetch(cid)
      entry = {
        "type"           => "following",
        "id"             => "anusvara_before_#{cid}",
        "following_id"   => cid,
        "following"      => cons["devanagari"],
        "following_iast" => onset(cons),
        "class"          => rule[:klass]
      }
      if rule[:nasal_id]
        nasal = letters_by_id.fetch(rule[:nasal_id])
        entry["result_iast"]       = onset(nasal)
        entry["result_devanagari"] = nasal["devanagari"]
      else
        entry["result_iast"]       = "ṃ"
        entry["result_devanagari"] = nil # nasalised vowel, no stop nasal
      end
      entry["example"] = rule[:example]
      entries << entry
    end
  end
  entries
end

def write_json(path, data)
  File.write(path, JSON.pretty_generate(data))
  puts "  Wrote #{data.size} entries to #{path}"
end

def write_anki_file(path, entries)
  File.open(path, "w:UTF-8") do |f|
    f.puts "#separator:Tab"
    f.puts "#html:true"
    f.puts "#deck:#{DECK_NAME}"
    f.puts "#notetype:Basic"
    f.puts "#columns:Key\tFront\tBack"
    f.puts "#guid column:1"

    entries.each do |entry|
      if entry["type"] == "independent"
        mark  = MARKS.fetch(entry["mark_id"])
        front = "<center><big><big><big><big><big>#{entry["devanagari"]}</big></big></big></big></big></center>"
        back  = "<center><big><big><b>#{entry["roman"]}</b></big></big>" \
                "<br><big>#{entry["vowel_devanagari"]} (#{entry["vowel_roman"]}) + ◌#{mark[:char]} (#{mark[:name]})</big></center>"
        f.puts "#{entry["id"]}\t#{front}\t#{back}"
        next
      end

      front = "<center><big><big><big>◌#{ANUSVARA} + #{entry["following"]}</big></big></big>" \
              "<br><small>anusvāra before #{entry["following_iast"]}</small></center>"

      if entry["result_devanagari"]
        answer = "→ <b>#{entry["result_iast"]}</b> (#{entry["result_devanagari"]})"
        rule   = "anusvāra becomes #{entry["result_iast"]}, the #{entry["class"]} nasal"
      else
        answer = "→ <b>nasalised vowel</b> (anusvāra ṃ kept)"
        rule   = "no stop nasal before a #{entry["class"]} — the vowel is nasalised"
      end

      ex   = entry["example"]
      back = "<center><big><big>#{answer}</big></big>" \
             "<br>#{rule}" \
             "<br><small>e.g. #{ex[:dev]} #{ex[:iast]} → #{ex[:pron]}</small></center>"

      f.puts "#{entry["id"]}\t#{front}\t#{back}"
    end
  end
  puts "  Wrote #{entries.size} cards to #{path}"
end

# --- Main ---
puts "=== Sanskrit Anusvāra Anki Generator ==="
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

puts "Step 1: Building anusvāra cards..."
entries = build_independent(letters_by_id) + build_entries(letters_by_id)
write_json(OUTPUT_JSON, entries)
puts

puts "Step 2: Writing Anki import file..."
write_anki_file(OUTPUT_FILE, entries)

puts
puts "=== Done! ==="
puts
puts "To import into Anki:"
puts "  1. Open Anki"
puts "  2. File > Import"
puts "  3. Select: #{OUTPUT_FILE}"
puts "  4. Cards will land in deck: #{DECK_NAME}"
