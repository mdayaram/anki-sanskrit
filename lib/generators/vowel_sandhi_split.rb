# frozen_string_literal: true

require_relative "base"
require_relative "vowel_sandhi"
require_relative "../vowel_sandhi_deck"

module Generators
  # Inverse of the vowel (svara) sandhi deck: given a combined form, recall the
  # two words it split from (vigraha). Pure rendering transform over the SAME
  # committed data/vowel_sandhi.json the forward deck reads — no new data file,
  # no engine change. It just mirrors the card: the combined Devanagari becomes
  # the prompt and the split + rule become the answer.
  #
  #   Front: the combined form in Devanagari (देवेन्द्र)
  #   Back:  the two words (देव + इन्द्र), the IAST (devendra → deva + indra),
  #          which sandhi fired, the rule explanation, and the CONTEXT.
  # No audio.
  #
  # Keyed with the distinct `vowel_sandhi_split:` prefix so Anki treats these as
  # separate notes from the forward deck (both files use #guid column:1); a shared
  # key would make the two directions overwrite each other on import.
  class VowelSandhiSplit < Base
    KEY         = "vowel-sandhi-split"
    DESCRIPTION = "Vowel (svara) sandhi splitting (combined form -> the two words + rule)"
    OUTPUT_TXT  = "sanskrit_vowel_sandhi_split_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::VOWEL_SANDHI_SPLIT_DECK

    def build = VowelSandhiDeck.load

    def card(entry)
      key     = "vowel_sandhi_split:#{entry['type']}:#{entry['word1_iast']}+#{entry['word2_iast']}"
      context = VowelSandhi::CONTEXTS.fetch(entry["context"].to_sym)
      front   = "<center>#{'<big>' * 3}#{entry['combined_devanagari']}#{'</big>' * 3}</center>"
      back    = "<center>#{'<big>' * 2}<b>#{entry['word1_devanagari']} + #{entry['word2_devanagari']}</b>#{'</big>' * 2}" \
                "<br><big>#{entry['combined_iast']} → #{entry['word1_iast']} + #{entry['word2_iast']}</big>" \
                "<br><br><b>#{entry['sandhi_name']} sandhi (#{entry['sandhi_devanagari']})</b>" \
                "<br>#{entry['explanation']}" \
                "<br><small>(sandhi #{context})</small></center>"
      [key, front, back]
    end
  end
end
