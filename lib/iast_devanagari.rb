# frozen_string_literal: true

# Deterministic IAST <-> Devanagari transliteration for Sanskrit words.
#
# A committed, reusable tool: it builds the Devanagari column of
# data/vedanta.json and powers the pair-validity check, and is available for a
# future per-word verse deck.
#
# IAST -> Devanagari is one-to-many: a homorganic nasal cluster can be written
# with either the explicit conjunct (अहङ्कारः) or an anusvara (अहंकारः). So
# to_devanagari returns one canonical spelling (the explicit conjunct), always a
# valid_pair? for its input, while to_iast canonicalises the other direction
# (Devanagari -> IAST, many-to-one) by realising anusvara-before-a-stop as the
# homorganic nasal. A curated (iast, devanagari) pair is trusted iff
# valid_pair?(iast, dev), i.e. to_iast(dev) == iast — which accepts every valid
# spelling, not just the canonical one.
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

  # IAST tokens, longest first, so "kh"/"ai" match before "k"/"a".
  IAST_TOKENS = (CONSONANTS.keys + VOWELS.keys + ["ṃ", "ḥ", "'"]).sort_by { |t| -t.length }.freeze

  module_function

  def to_devanagari(iast)
    out = +""
    pending_consonant = false # a consonant glyph was emitted with no vowel yet
    i = 0
    s = iast
    while i < s.length
      tok = IAST_TOKENS.find { |t| s[i, t.length] == t }
      if tok.nil?
        # boundary / unknown char (space, hyphen, etc.): close a bare consonant
        out << VIRAMA if pending_consonant
        pending_consonant = false
        out << s[i] unless s[i] == "-" # drop compound hyphens; keep spaces
        i += 1
        next
      end

      if CONSONANTS.key?(tok)
        out << VIRAMA if pending_consonant
        out << CONSONANTS[tok]
        pending_consonant = true
      elsif VOWELS.key?(tok)
        indep, matra = VOWELS[tok]
        out << (pending_consonant ? matra : indep)
        pending_consonant = false
      else # marks
        out << VIRAMA if pending_consonant
        pending_consonant = false
        out << { "ṃ" => ANUSVARA, "ḥ" => VISARGA, "'" => AVAGRAHA }[tok]
      end
      i += tok.length
    end
    out << VIRAMA if pending_consonant
    out
  end

  # Reverse maps (built once).
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
