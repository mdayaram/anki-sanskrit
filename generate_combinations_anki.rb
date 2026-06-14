#!/usr/bin/env ruby
# frozen_string_literal: true

# Script 3: Generate Anki flashcards for Sanskrit consonant + vowel combinations.
#
# Reads data/letters.json (produced by scrape_sanskrit.rb) and writes:
#   data/combinations.json          - every attested consonant × vowel pair
#   sanskrit_combinations_anki.txt  - Anki import file for them
#
# The combinations themselves are deterministic Unicode: a consonant's
# Devanagari + the vowel's combining matra yields the combined glyph, and the
# IAST follows by replacing the consonant's trailing 'a' with the vowel's IAST.
# The aM/aH "vowels" attach the anusvara/visarga sign to the inherent 'a'
# (कं, कः). No scraping required. (Standalone vowel + mark and anusvara
# pronunciation live in generate_anusvara_anki.rb.)
#
# Usage:
#   bundle exec ruby generate_combinations_anki.rb

require "json"
require "fileutils"

DATA_DIR              = File.join(__dir__, "data")
LETTERS_JSON          = File.join(DATA_DIR, "letters.json")
COMBINATIONS_JSON     = File.join(DATA_DIR, "combinations.json")
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

# Drop combinations that never occur in the corpus. 1 = keep anything attested
# at least once; raise this to prune rare syllables too.
MIN_FREQUENCY = 1

# Corpus frequency of every consonant×vowel syllable, keyed [consonant][vowel].
# Counts are consonant→vowel akṣara adjacencies in the BORI Mahābhārata (~223k
# half-verse lines, the same corpus Stiehl used for conjuncts), tabulated from
# the GRETIL Unicode edition. A 0 means the syllable never appears across the
# whole epic, so it is dropped — 112 of the 490 do, almost entirely the vocalic
# vowels ḷ (LLi) and ṝ (RRI) and the nasals ṅ (GNa) / ñ (JNa), which only live
# inside conjuncts and never independently carry a vowel.
COMBINATION_FREQUENCY = {
  "ka" => { "aa" => 23868, "i" => 6692, "ii" => 2691, "u" => 12276, "uu" => 628, "RRi" => 15471, "RRI" => 0, "LLi" => 33, "e" => 7369, "ai" => 1315, "o" => 3727, "au" => 2566, "aM" => 3327, "aH" => 2001 },
  "kha" => { "aa" => 2214, "i" => 754, "ii" => 286, "u" => 59, "uu" => 0, "RRi" => 0, "RRI" => 0, "LLi" => 0, "e" => 745, "ai" => 379, "o" => 331, "au" => 23, "aM" => 1112, "aH" => 257 },
  "ga" => { "aa" => 8878, "i" => 1662, "ii" => 1012, "u" => 5272, "uu" => 253, "RRi" => 3152, "RRI" => 0, "LLi" => 0, "e" => 2965, "ai" => 743, "o" => 2806, "au" => 651, "aM" => 1456, "aH" => 725 },
  "gha" => { "aa" => 2053, "i" => 38, "ii" => 44, "u" => 199, "uu" => 49, "RRi" => 258, "RRI" => 0, "LLi" => 0, "e" => 137, "ai" => 249, "o" => 1987, "au" => 21, "aM" => 137, "aH" => 56 },
  "GNa" => { "aa" => 0, "i" => 0, "ii" => 0, "u" => 0, "uu" => 0, "RRi" => 0, "RRI" => 0, "LLi" => 0, "e" => 0, "ai" => 0, "o" => 0, "au" => 0, "aM" => 0, "aH" => 0 },
  "ca" => { "aa" => 15529, "i" => 11370, "ii" => 635, "u" => 671, "uu" => 144, "RRi" => 2, "RRI" => 0, "LLi" => 0, "e" => 3297, "ai" => 7413, "o" => 2144, "au" => 107, "aM" => 412, "aH" => 1014 },
  "cha" => { "aa" => 1839, "i" => 1321, "ii" => 63, "u" => 165, "uu" => 71, "RRi" => 124, "RRI" => 0, "LLi" => 0, "e" => 1422, "ai" => 40, "o" => 93, "au" => 14, "aM" => 77, "aH" => 3 },
  "ja" => { "aa" => 13878, "i" => 5199, "ii" => 2473, "u" => 2689, "uu" => 44, "RRi" => 38, "RRI" => 0, "LLi" => 0, "e" => 2741, "ai" => 469, "o" => 1738, "au" => 328, "aM" => 1581, "aH" => 1316 },
  "jha" => { "aa" => 0, "i" => 12, "ii" => 0, "u" => 0, "uu" => 0, "RRi" => 0, "RRI" => 0, "LLi" => 0, "e" => 0, "ai" => 0, "o" => 1, "au" => 0, "aM" => 0, "aH" => 0 },
  "JNa" => { "aa" => 4, "i" => 0, "ii" => 0, "u" => 0, "uu" => 0, "RRi" => 0, "RRI" => 0, "LLi" => 0, "e" => 0, "ai" => 0, "o" => 0, "au" => 0, "aM" => 0, "aH" => 0 },
  "Ta" => { "aa" => 3070, "i" => 1616, "ii" => 245, "u" => 683, "uu" => 3, "RRi" => 3, "RRI" => 1, "LLi" => 0, "e" => 672, "ai" => 195, "o" => 1157, "au" => 264, "aM" => 1110, "aH" => 668 },
  "Tha" => { "aa" => 1122, "i" => 3578, "ii" => 75, "u" => 35, "uu" => 3, "RRi" => 0, "RRI" => 0, "LLi" => 0, "e" => 633, "ai" => 60, "o" => 450, "au" => 31, "aM" => 636, "aH" => 339 },
  "Da" => { "aa" => 807, "i" => 1464, "ii" => 650, "u" => 1040, "uu" => 235, "RRi" => 1, "RRI" => 0, "LLi" => 0, "e" => 467, "ai" => 60, "o" => 309, "au" => 11, "aM" => 173, "aH" => 116 },
  "Dha" => { "aa" => 330, "i" => 0, "ii" => 7, "u" => 94, "uu" => 0, "RRi" => 0, "RRI" => 0, "LLi" => 0, "e" => 89, "ai" => 28, "o" => 132, "au" => 11, "aM" => 173, "aH" => 71 },
  "Na" => { "aa" => 17088, "i" => 7266, "ii" => 2228, "u" => 2154, "uu" => 41, "RRi" => 0, "RRI" => 0, "LLi" => 0, "e" => 5738, "ai" => 2290, "o" => 3432, "au" => 581, "aM" => 5250, "aH" => 3429 },
  "ta" => { "aa" => 55813, "i" => 48680, "ii" => 7939, "u" => 23771, "uu" => 1301, "RRi" => 2228, "RRI" => 663, "LLi" => 0, "e" => 44038, "ai" => 4290, "o" => 18505, "au" => 3084, "aM" => 20272, "aH" => 21854 },
  "tha" => { "aa" => 23729, "i" => 8305, "ii" => 461, "u" => 409, "uu" => 124, "RRi" => 0, "RRI" => 0, "LLi" => 0, "e" => 3108, "ai" => 2535, "o" => 2159, "au" => 458, "aM" => 5290, "aH" => 1375 },
  "da" => { "aa" => 21781, "i" => 13934, "ii" => 4200, "u" => 11755, "uu" => 1155, "RRi" => 7964, "RRI" => 0, "LLi" => 0, "e" => 15866, "ai" => 2050, "o" => 2270, "au" => 901, "aM" => 4215, "aH" => 1309 },
  "dha" => { "aa" => 11894, "i" => 12849, "ii" => 2146, "u" => 2310, "uu" => 751, "RRi" => 2632, "RRI" => 1, "LLi" => 0, "e" => 3257, "ai" => 995, "o" => 1831, "au" => 617, "aM" => 2493, "aH" => 1197 },
  "na" => { "aa" => 47709, "i" => 37466, "ii" => 6472, "u" => 12922, "uu" => 553, "RRi" => 3971, "RRI" => 29, "LLi" => 0, "e" => 11018, "ai" => 3613, "o" => 7430, "au" => 1193, "aM" => 13018, "aH" => 11489 },
  "pa" => { "aa" => 29743, "i" => 14878, "ii" => 1481, "u" => 22817, "uu" => 5460, "RRi" => 4514, "RRI" => 0, "LLi" => 0, "e" => 2900, "ai" => 747, "o" => 2188, "au" => 1086, "aM" => 1724, "aH" => 1676 },
  "pha" => { "aa" => 185, "i" => 9, "ii" => 67, "u" => 195, "uu" => 26, "RRi" => 0, "RRI" => 0, "LLi" => 0, "e" => 76, "ai" => 1, "o" => 43, "au" => 0, "aM" => 2, "aH" => 0 },
  "ba" => { "aa" => 5644, "i" => 1157, "ii" => 501, "u" => 3724, "uu" => 156, "RRi" => 822, "RRI" => 0, "LLi" => 0, "e" => 220, "ai" => 15, "o" => 759, "au" => 4, "aM" => 48, "aH" => 25 },
  "bha" => { "aa" => 13218, "i" => 15959, "ii" => 7453, "u" => 3942, "uu" => 9542, "RRi" => 2582, "RRI" => 0, "LLi" => 0, "e" => 2077, "ai" => 615, "o" => 2825, "au" => 965, "aM" => 670, "aH" => 624 },
  "ma" => { "aa" => 59927, "i" => 22855, "ii" => 2363, "u" => 18917, "uu" => 2733, "RRi" => 5614, "RRI" => 0, "LLi" => 0, "e" => 19139, "ai" => 1907, "o" => 6267, "au" => 1136, "aM" => 4902, "aH" => 4119 },
  "ya" => { "aa" => 65779, "i" => 3892, "ii" => 364, "u" => 22969, "uu" => 1397, "RRi" => 59, "RRI" => 0, "LLi" => 0, "e" => 21363, "ai" => 3173, "o" => 20070, "au" => 1815, "aM" => 19789, "aH" => 8881 },
  "ra" => { "aa" => 75888, "i" => 25214, "ii" => 9011, "u" => 23607, "uu" => 6371, "RRi" => 111, "RRI" => 0, "LLi" => 0, "e" => 18873, "ai" => 5540, "o" => 16341, "au" => 3032, "aM" => 13911, "aH" => 7172 },
  "la" => { "aa" => 8237, "i" => 3787, "ii" => 1553, "u" => 966, "uu" => 186, "RRi" => 2, "RRI" => 0, "LLi" => 0, "e" => 4865, "ai" => 907, "o" => 9536, "au" => 339, "aM" => 4598, "aH" => 1820 },
  "va" => { "aa" => 74363, "i" => 56882, "ii" => 11152, "u" => 824, "uu" => 26, "RRi" => 8538, "RRI" => 0, "LLi" => 0, "e" => 19031, "ai" => 11344, "o" => 4089, "au" => 594, "aM" => 13361, "aH" => 3951 },
  "sha" => { "aa" => 9855, "i" => 7212, "ii" => 2449, "u" => 6282, "uu" => 2200, "RRi" => 1695, "RRI" => 0, "LLi" => 0, "e" => 3262, "ai" => 1046, "o" => 4154, "au" => 583, "aM" => 4966, "aH" => 2623 },
  "Sha" => { "aa" => 7766, "i" => 4729, "ii" => 1214, "u" => 7314, "uu" => 178, "RRi" => 0, "RRI" => 0, "LLi" => 0, "e" => 2543, "ai" => 429, "o" => 1359, "au" => 80, "aM" => 1447, "aH" => 924 },
  "sa" => { "aa" => 19329, "i" => 9465, "ii" => 2644, "u" => 18476, "uu" => 3955, "RRi" => 2479, "RRI" => 2, "LLi" => 0, "e" => 6767, "ai" => 2315, "o" => 3977, "au" => 2122, "aM" => 24111, "aH" => 2216 },
  "ha" => { "aa" => 23565, "i" => 14024, "ii" => 3042, "u" => 5619, "uu" => 1351, "RRi" => 3379, "RRI" => 0, "LLi" => 0, "e" => 4208, "ai" => 554, "o" => 2359, "au" => 211, "aM" => 5086, "aH" => 973 },
  "kSha" => { "aa" => 1809, "i" => 4375, "ii" => 696, "u" => 1519, "uu" => 43, "RRi" => 0, "RRI" => 0, "LLi" => 0, "e" => 1707, "ai" => 133, "o" => 623, "au" => 227, "aM" => 625, "aH" => 299 },
  "jJNa" => { "aa" => 5500, "i" => 231, "ii" => 14, "u" => 18, "uu" => 0, "RRi" => 0, "RRI" => 0, "LLi" => 0, "e" => 1013, "ai" => 239, "o" => 785, "au" => 22, "aM" => 306, "aH" => 721 }
}.freeze

def build_combinations(letters_by_id)
  combos = []
  CONSONANT_IDS.each do |cid|
    consonant = letters_by_id.fetch(cid)
    VOWEL_IDS.each do |vid|
      count = COMBINATION_FREQUENCY.fetch(cid).fetch(vid)
      next if count < MIN_FREQUENCY # skip syllables never attested in the corpus

      vowel = letters_by_id.fetch(vid)
      matra = VOWEL_MATRAS.fetch(vid)

      combos << {
        "id"                => "#{cid}_#{vid}",
        "consonant_id"      => cid,
        "vowel_id"          => vid,
        "devanagari"        => consonant["devanagari"] + matra,
        "roman"             => consonant["roman"].sub(/a\z/, vowel["roman"]),
        "mahabharata_count" => count
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

puts "Step 2: Writing Anki import file..."
write_anki_file(OUTPUT_FILE, combos, letters_by_id)

puts
puts "=== Done! ==="
puts
puts "To import into Anki:"
puts "  1. Open Anki"
puts "  2. File > Import"
puts "  3. Select: #{OUTPUT_FILE}"
puts "  4. Cards will land in deck: #{DECK_NAME}"
