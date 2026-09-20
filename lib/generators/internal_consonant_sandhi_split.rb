# frozen_string_literal: true

require_relative "base"
require_relative "../internal_consonant_sandhi_deck"

module Generators
  # Inverse of the internal consonant sandhi deck: given a finished word, recall
  # the morphemes it was built from and the rule that reshaped the junction. Pure
  # rendering transform over the SAME committed
  # data/internal_consonant_sandhi.json the forward deck reads — no new data file,
  # no engine.
  #
  #   Front: the combined word (विषीदति)
  #   Back:  the parts (वि + सीदति), the IAST (viṣīdati → vi + sīdati), the rule,
  #          the explanation, and the `analysis` line — which names the trigger,
  #          and so is what tells the reader the ष् in front of them is an
  #          underlying स्.
  # No audio.
  #
  # Contrast records — where the rule deliberately does NOT fire (मरुत् + सु →
  # मरुत्सु) — are left out: splitting them at their obvious seam teaches nothing
  # the forward card didn't already.
  #
  # Keyed with the distinct `internal_consonant_sandhi_split:` prefix so Anki
  # treats these as separate notes from the forward deck (both use
  # #guid column:1); a shared key would make the two directions overwrite each
  # other on import.
  class InternalConsonantSandhiSplit < Base
    KEY         = "internal-consonant-sandhi-split"
    DESCRIPTION = "Internal consonant sandhi splitting (combined word -> its parts + rule)"
    OUTPUT_TXT  = "sanskrit_internal_consonant_sandhi_split_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::INTERNAL_CONSONANT_SANDHI_SPLIT_DECK

    def build = InternalConsonantSandhiDeck.load.reject { |entry| entry["contrast"] }

    def card(entry)
      key     = "internal_consonant_sandhi_split:#{entry['type']}:#{entry['word1_iast']}+#{entry['word2_iast']}"
      primary = entry["combined"].first
      front   = "<center>#{'<big>' * 3}#{primary['devanagari']}#{'</big>' * 3}</center>"

      back = +"<center>#{'<big>' * 2}<b>#{entry['word1_devanagari']} + #{entry['word2_devanagari']}</b>#{'</big>' * 2}" \
              "<br><big>#{primary['iast']} → #{entry['word1_iast']} + #{entry['word2_iast']}</big>" \
              "<br><br><b>#{entry['rule']}</b>" \
              "<br>#{entry['explanation']}"
      back << "<br><br><small>#{entry['analysis']}</small>" if entry["analysis"]
      back << "</center>"

      [key, front, back]
    end
  end
end
