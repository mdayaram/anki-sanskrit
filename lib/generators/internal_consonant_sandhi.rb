# frozen_string_literal: true

require_relative "base"
require_relative "../internal_consonant_sandhi_deck"

module Generators
  # Internal consonant sandhi deck — sandhi WITHIN a single word, i.e. the two
  # internal rules of the Arsha Bodha handout: ṣatva (स् -> ष् after a vowel other
  # than अ/आ) and ṇatva (न् -> ण् after ष् र् ऋ). Pure reader over
  # data/internal_consonant_sandhi.json.
  #
  # The parts joined here are morphemes, not free words — a prefix and a verb
  # (वि + सीदति), or a stem and an ending (राम + एन) — but they are stored in the
  # same word1/word2 fields as the external deck, following the vowel-sandhi deck,
  # which already uses those names for morphemes in its internal-context records.
  #
  #   Front: the two parts in Devanagari, joined by + (वि + सीदति)
  #   Back:  the combined word (विषीदति), the IAST, the rule, the explanation.
  # No audio.
  class InternalConsonantSandhi < Base
    KEY         = "internal-consonant-sandhi"
    DESCRIPTION = "Internal consonant sandhi (ṣatva/ṇatva: Devanagari parts -> combined word)"
    OUTPUT_TXT  = "sanskrit_internal_consonant_sandhi_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::INTERNAL_CONSONANT_SANDHI_DECK

    def build = InternalConsonantSandhiDeck.load

    def card(entry)
      combined = entry["combined"]
      key = "internal_consonant_sandhi:#{entry['type']}:#{entry['word1_iast']}+#{entry['word2_iast']}"

      # The parts are morphemes, so unlike the external deck they are shown with an
      # explicit "+": वि सीदति would read as two words, which they are not.
      front = "<center>#{'<big>' * 3}#{entry['word1_devanagari']} + #{entry['word2_devanagari']}#{'</big>' * 3}</center>"

      combined_dev  = combined.map { |c| "<b>#{c['devanagari']}</b>" }.join(" &nbsp;/&nbsp; ")
      combined_iast = combined.map { |c| c["iast"] }.join(" / ")
      inputs        = "#{entry['word1_iast']} + #{entry['word2_iast']}"

      back = "<center>#{'<big>' * 2}#{combined_dev}#{'</big>' * 2}" \
             "<br><big>#{inputs} → #{combined_iast}</big>" \
             "<br><br><b>#{entry['rule']}</b>" \
             "<br>#{entry['explanation']}</center>"

      [key, front, back]
    end
  end
end
