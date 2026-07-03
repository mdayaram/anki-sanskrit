# frozen_string_literal: true

# Deterministic Devanagari -> IAST reader for Sanskrit words, plus a pair
# validator. A committed, reusable tool: it powers the pair-validity checks for
# data/vedanta.json and data/vowel_sandhi.json, and is available for a future per-word
# verse deck.
#
# to_iast canonicalises: it is many-to-one. A homorganic nasal cluster can be
# written with either the explicit conjunct (अहङ्कारः) or an anusvara (अहंकारः),
# and both read to the same IAST because anusvara-before-a-stop is realised as the
# homorganic nasal (ं + क -> ṅk; before a sibilant/semivowel/ha it stays ṃ). A
# curated (iast, devanagari) pair is trusted iff valid_pair?(iast, dev), i.e.
# to_iast(dev) == iast — which accepts every valid spelling of a cluster.
#
# (There is deliberately no IAST -> Devanagari direction: it is one-to-many, so
# the Devanagari is curated in the data files rather than generated.)
module IastDevanagari
  # vowel => [independent, matra ("" for inherent a)]
  VOWELS = {
    "a" => ["अ", ""],   "ā" => ["आ", "ा"], "i" => ["इ", "ि"], "ī" => ["ई", "ी"],
    "u" => ["उ", "ु"],  "ū" => ["ऊ", "ू"], "ṛ" => ["ऋ", "ृ"], "ṝ" => ["ॠ", "ॄ"],
    "ḷ" => ["ऌ", "ॢ"],  "ḹ" => ["ॡ", "ॣ"], "e" => ["ए", "े"], "ai" => ["ऐ", "ै"],
    "o" => ["ओ", "ो"],  "au" => ["औ", "ौ"]
  }.freeze

  CONSONANTS = {
    "k" => "क", "kh" => "ख", "g" => "ग", "gh" => "घ", "ṅ" => "ङ",
    "c" => "च", "ch" => "छ", "j" => "ज", "jh" => "झ", "ñ" => "ञ",
    "ṭ" => "ट", "ṭh" => "ठ", "ḍ" => "ड", "ḍh" => "ढ", "ṇ" => "ण",
    "t" => "त", "th" => "थ", "d" => "द", "dh" => "ध", "n" => "न",
    "p" => "प", "ph" => "फ", "b" => "ब", "bh" => "भ", "m" => "म",
    "y" => "य", "r" => "र", "l" => "ल", "v" => "व",
    "ś" => "श", "ṣ" => "ष", "s" => "स", "h" => "ह"
  }.freeze

  VIRAMA   = "्"
  ANUSVARA = "ं"
  VISARGA  = "ः"
  AVAGRAHA = "ऽ"

  module_function

  # Devanagari -> IAST maps (built once from the tables above).
  DEV_VOWEL_INDEP = VOWELS.to_h { |k, (ind, _m)| [ind, k] }.freeze
  DEV_VOWEL_MATRA = VOWELS.reject { |k, _| k == "a" }.to_h { |k, (_i, m)| [m, k] }.freeze
  DEV_CONSONANT   = CONSONANTS.to_h { |k, v| [v, k] }.freeze

  # Anusvara before a varga stop is realised as that varga's nasal (ṅ/ñ/ṇ/n/m).
  # Before a sibilant/semivowel/ha (or a boundary) it stays a nasalised vowel (ṃ).
  ANUSVARA_STOP_NASAL = {
    "क" => "ṅ", "ख" => "ṅ", "ग" => "ṅ", "घ" => "ṅ",
    "च" => "ñ", "छ" => "ñ", "ज" => "ñ", "झ" => "ñ",
    "ट" => "ṇ", "ठ" => "ṇ", "ड" => "ṇ", "ढ" => "ṇ",
    "त" => "n", "थ" => "n", "द" => "n", "ध" => "n",
    "प" => "m", "फ" => "m", "ब" => "m", "भ" => "m"
  }.freeze

  def to_iast(dev)
    out = +""
    pending_a = false # a consonant base was emitted; inherent 'a' unless cancelled
    i = 0
    while i < dev.length
      ch = dev[i]
      if DEV_CONSONANT.key?(ch)
        out << "a" if pending_a
        out << DEV_CONSONANT[ch]
        pending_a = true
      elsif ch == VIRAMA
        pending_a = false
      elsif DEV_VOWEL_MATRA.key?(ch)
        out << DEV_VOWEL_MATRA[ch]
        pending_a = false
      elsif DEV_VOWEL_INDEP.key?(ch)
        out << "a" if pending_a
        out << DEV_VOWEL_INDEP[ch]
        pending_a = false
      elsif ch == ANUSVARA
        out << "a" if pending_a
        pending_a = false
        out << (ANUSVARA_STOP_NASAL[dev[i + 1]] || "ṃ")
      elsif ch == VISARGA
        out << "a" if pending_a
        pending_a = false
        out << "ḥ"
      elsif ch == AVAGRAHA
        out << "a" if pending_a
        pending_a = false
        out << "'"
      else
        out << "a" if pending_a
        pending_a = false
        out << ch
      end
      i += 1
    end
    out << "a" if pending_a
    out
  end

  # A stored (iast, devanagari) pair is valid when the Devanagari, read by the
  # rules (to_iast), yields exactly the IAST. Because to_iast canonicalises
  # (anusvara -> homorganic nasal), both the anusvara and explicit spellings of a
  # homorganic cluster validate against the same IAST.
  def valid_pair?(iast, dev)
    to_iast(dev) == iast
  end
end
