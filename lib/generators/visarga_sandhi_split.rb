# frozen_string_literal: true

require_relative "base"
require_relative "../visarga_sandhi_deck"

module Generators
  # Inverse of the visarga sandhi deck: given a combined form, recall the two
  # words it split from (vigraha). Pure rendering transform over the SAME committed
  # data/visarga_sandhi.json the forward deck reads — no new data file, no engine
  # (visarga is curated, not derived). It mirrors the forward card: the combined
  # Devanagari becomes the prompt and the split + rule become the answer.
  #
  #   Front: the primary combined form in Devanagari (नरश् चरति)
  #   Back:  the two words (नरः + चरति), the IAST (naraś carati → naraḥ + carati),
  #          word1's underlying pre-visarga form (नरः ← नरस्), any alternate
  #          accepted forms, which rule fired, and the rule explanation.
  # No audio.
  #
  # A record can list more than one accepted combined form; this deck emits ONE
  # card per record on the primary form (combined[0]) and shows the alternates on
  # the back. Keyed with the distinct `visarga_sandhi_split:` prefix so Anki treats
  # these as separate notes from the forward deck (both use #guid column:1); a
  # shared key would make the two directions overwrite each other on import.
  class VisargaSandhiSplit < Base
    KEY         = "visarga-sandhi-split"
    DESCRIPTION = "Visarga sandhi splitting (combined form -> the two words + rule)"
    OUTPUT_TXT  = "sanskrit_visarga_sandhi_split_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::VISARGA_SANDHI_SPLIT_DECK

    def build = VisargaSandhiDeck.load

    def card(entry)
      key     = "visarga_sandhi_split:#{entry['type']}:#{entry['word1_iast']}+#{entry['word2_iast']}"
      primary = entry["combined"].first
      front   = "<center>#{'<big>' * 3}#{primary['devanagari']}#{'</big>' * 3}</center>"

      back = +"<center>#{'<big>' * 2}<b>#{entry['word1_devanagari']} + #{entry['word2_devanagari']}</b>#{'</big>' * 2}" \
              "<br><big>#{primary['iast']} → #{entry['word1_iast']} + #{entry['word2_iast']}</big>" \
              "<br><small>(#{entry['word1_devanagari']} ← #{entry['word1_underlying_devanagari']})</small>"

      alternates = entry["combined"].drop(1)
      unless alternates.empty?
        back << "<br><small>(also accepted: #{alternates.map { |a| a['devanagari'] }.join(' / ')})</small>"
      end

      back << "<br><br><b>#{entry['rule']}</b>" \
              "<br>#{entry['explanation']}</center>"

      [key, front, back]
    end
  end
end
