# frozen_string_literal: true

require_relative "base"
require_relative "../external_consonant_sandhi_deck"

module Generators
  # Inverse of the external consonant sandhi deck: given a joined form, recall the
  # two words it split from (vigraha). Pure rendering transform over the SAME
  # committed data/external_consonant_sandhi.json the forward deck reads — no new
  # data file, no engine (the rules are curated from the Arsha Bodha handout, not
  # derived). It mirrors the forward card: the joined Devanagari becomes the
  # prompt and the split + rule become the answer.
  #
  #   Front: the primary combined form, joined as the handout writes it (वाग्देवी)
  #   Back:  the two words (वाक् + देवी), the IAST (vāgdevī → vāk + devī), word1's
  #          citation form where the padānta reduction changed it (वाक् ← वाच्),
  #          any alternate accepted forms, which rule fired, and the explanation.
  # No audio.
  #
  # Contrast records — the junctions where the rule deliberately does NOT fire
  # (एतान् + इह → एतानिह) — are left out: splitting them at their obvious seam
  # teaches nothing the forward card didn't already.
  #
  # A record can list more than one accepted combined form; this deck emits ONE
  # card per record on the primary form (combined[0]) and names the alternates on
  # the back. Keyed with the distinct `external_consonant_sandhi_split:` prefix so
  # Anki treats these as separate notes from the forward deck (both use
  # #guid column:1); a shared key would make the two directions overwrite each
  # other on import.
  class ExternalConsonantSandhiSplit < Base
    KEY         = "external-consonant-sandhi-split"
    DESCRIPTION = "External consonant sandhi splitting (combined form -> the two words + rule)"
    OUTPUT_TXT  = "sanskrit_external_consonant_sandhi_split_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::EXTERNAL_CONSONANT_SANDHI_SPLIT_DECK

    def build = ExternalConsonantSandhiDeck.load.reject { |entry| entry["contrast"] }

    def card(entry)
      key     = "external_consonant_sandhi_split:#{entry['type']}:#{entry['word1_iast']}+#{entry['word2_iast']}"
      primary = entry["combined"].first
      front   = "<center>#{'<big>' * 3}#{primary['devanagari']}#{'</big>' * 3}</center>"

      back = +"<center>#{'<big>' * 2}<b>#{entry['word1_devanagari']} + #{entry['word2_devanagari']}</b>#{'</big>' * 2}" \
              "<br><big>#{primary['iast']} → #{entry['word1_iast']} + #{entry['word2_iast']}</big>"

      # The sandhi-final consonant is often not the stem final: वाक् comes from
      # वाच्. Splitting only gets you back to the padānta form, so the citation
      # form is the rest of the answer — where the reduction changed anything.
      if entry["word1_underlying_devanagari"]
        back << "<br><small>(#{entry['word1_devanagari']} ← #{entry['word1_underlying_devanagari']})</small>"
      end

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
