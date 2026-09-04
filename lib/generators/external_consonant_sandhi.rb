# frozen_string_literal: true

require_relative "base"
require_relative "../external_consonant_sandhi_deck"

module Generators
  # External consonant (vyañjana) sandhi deck — the junction between two words.
  # Pure reader over data/external_consonant_sandhi.json (the committed source of
  # truth), read via ExternalConsonantSandhiDeck.load. Sister to the visarga deck,
  # and like it there is NO derivation engine: the 12 rules and their examples are
  # curated from the Arsha Bodha "Consonant Sandhi" handout and cross-checked
  # against Whitney, Ruppel and learnsanskrit.org. Only the Devanagari<->IAST
  # spelling of each stored form is validated, in
  # test/external_consonant_sandhi_deck_test.rb.
  #
  #   Front: the two parts in Devanagari, space-separated (वाक् देवी), with word1's
  #          citation form beneath it when the padānta reduction changed it (वाच्).
  #   Back:  the combined form(s) written JOINED the way the handout writes them
  #          (वाग्देवी), the IAST (vāk + devī → vāgdevī), which rule fired, and a
  #          brief explanation.
  # No audio.
  #
  # A junction can have more than one accepted outcome (तत् + हि → तद्धि or तद् हि;
  # ch-doubling is optional after a long vowel), so each record's `combined` is a
  # LIST of {iast, devanagari} forms; the back shows all of them.
  class ExternalConsonantSandhi < Base
    KEY         = "external-consonant-sandhi"
    DESCRIPTION = "External consonant sandhi (Devanagari word pair -> combined form(s) + rule)"
    OUTPUT_TXT  = "sanskrit_external_consonant_sandhi_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::EXTERNAL_CONSONANT_SANDHI_DECK

    def build = ExternalConsonantSandhiDeck.load

    def card(entry)
      combined = entry["combined"]
      key = "external_consonant_sandhi:#{entry['type']}:#{entry['word1_iast']}+#{entry['word2_iast']}"

      # A word's sandhi-final consonant is often not its stem final: वाच् may only
      # end a word as वाक्, षष् as षट्. Showing that citation form under the pair is
      # what makes the junction legible — it is the padānta reduction that had to
      # happen before any of these rules could apply. Omitted when nothing changed.
      front = "<center>#{'<big>' * 3}#{entry['word1_devanagari']} #{entry['word2_devanagari']}#{'</big>' * 3}"
      if entry["word1_underlying_devanagari"]
        front += "<br><small>(#{entry['word1_devanagari']} ← #{entry['word1_underlying_devanagari']})</small>"
      end
      front += "</center>"

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
