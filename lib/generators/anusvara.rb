# frozen_string_literal: true

require_relative "base"

module Generators
  # Anusvāra (ं) pronunciation. Its sound is conditioned by the FOLLOWING
  # consonant, not the syllable it is written on, so there is one card per
  # following consonant rather than per syllable. Before a stop it becomes the
  # nasal homorganic with that stop's articulation class (the fifth/nasal letter
  # of the varga): guttural क-varga → ṅ, palatal च-varga → ñ, retroflex ट-varga
  # → ṇ, dental त-varga → n, labial प-varga → m. Before a semivowel (य र ल व),
  # sibilant (श ष स) or ह there is no homorganic stop nasal, so the anusvāra
  # stays a nasalised vowel. Rules verified against Wikipedia "Anusvara" and
  # ashtangayoga.info. A few standalone vowel+mark recognition cards are also
  # emitted, only the three forms attested in the corpus.
  class Anusvara < Base
    KEY         = "anusvara"
    DESCRIPTION = "Anusvāra pronunciation — one card per following consonant"
    OUTPUT_TXT  = "sanskrit_anusvara_anki.txt"
    OUTPUT_JSON = "anusvara.json"

    ANUSVARA = "ं"

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

    def build
      build_independent + build_following
    end

    def card(entry)
      entry["type"] == "independent" ? independent_card(entry) : following_card(entry)
    end

    private

    def onset(letter)
      letter["roman"].sub(/a\z/, "")
    end

    # Recognition cards for the few attested standalone vowel+mark glyphs.
    def build_independent
      INDEPENDENT_MARKS.map do |vid, mid|
        vowel = @letters_by_id.fetch(vid)
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

    def build_following
      entries = []
      ANUSVARA_RULES.each do |rule|
        rule[:members].each do |cid|
          cons = @letters_by_id.fetch(cid)
          entry = {
            "type"           => "following",
            "id"             => "anusvara_before_#{cid}",
            "following_id"   => cid,
            "following"      => cons["devanagari"],
            "following_iast" => onset(cons),
            "class"          => rule[:klass]
          }
          if rule[:nasal_id]
            nasal = @letters_by_id.fetch(rule[:nasal_id])
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

    def independent_card(entry)
      mark  = MARKS.fetch(entry["mark_id"])
      front = Anki.glyph_front(entry["devanagari"])
      back  = "<center><big><big><b>#{entry['roman']}</b></big></big>" \
              "<br><big>#{entry['vowel_devanagari']} (#{entry['vowel_roman']}) + ◌#{mark[:char]} (#{mark[:name]})</big></center>"
      [entry["id"], front, back]
    end

    def following_card(entry)
      front = "<center><big><big><big>◌#{ANUSVARA} + #{entry['following']}</big></big></big>" \
              "<br><small>anusvāra before #{entry['following_iast']}</small></center>"

      if entry["result_devanagari"]
        answer = "→ <b>#{entry['result_iast']}</b> (#{entry['result_devanagari']})"
        rule   = "anusvāra becomes #{entry['result_iast']}, the #{entry['class']} nasal"
      else
        answer = "→ <b>nasalised vowel</b> (anusvāra ṃ kept)"
        rule   = "no stop nasal before a #{entry['class']} — the vowel is nasalised"
      end

      ex   = entry["example"]
      back = "<center><big><big>#{answer}</big></big>" \
             "<br>#{rule}" \
             "<br><small>e.g. #{ex[:dev]} #{ex[:iast]} → #{ex[:pron]}</small></center>"

      [entry["id"], front, back]
    end
  end
end
