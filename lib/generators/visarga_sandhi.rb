# frozen_string_literal: true

require_relative "base"
require_relative "../visarga_sandhi_deck"

module Generators
  # Visarga sandhi deck. Pure reader over data/visarga_sandhi.json (the committed
  # source of truth), read via VisargaSandhiDeck.load. Sister to the vowel-sandhi
  # deck but with NO derivation engine: visarga outcomes are curated by hand from
  # the sources (Whitney §§170-179, learnsanskrit.org), and only the
  # Devanagari<->IAST spelling of each stored form is validated
  # (IastDevanagari.valid_pair?) in test/visarga_sandhi_deck_test.rb.
  #
  #   Front: the two parts in Devanagari, space-separated (नरः गच्छति)
  #   Back:  the combined form(s), the IAST (naraḥ + gacchati → naro gacchati),
  #          which rule fired, and a brief rule explanation.
  # No audio.
  #
  # A junction can have more than one accepted outcome (e.g. before a voiceless
  # stop the visarga may assimilate to a sibilant OR be retained), so each record's
  # `combined` is a LIST of {iast, devanagari} forms; the back shows all of them.
  class VisargaSandhi < Base
    KEY         = "visarga-sandhi"
    DESCRIPTION = "Visarga sandhi (Devanagari word pair -> combined form(s) + rule)"
    OUTPUT_TXT  = "sanskrit_visarga_sandhi_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::VISARGA_SANDHI_DECK

    def build = VisargaSandhiDeck.load

    def card(entry)
      combined = entry["combined"]
      key = "visarga_sandhi:#{entry['type']}:#{entry['word1_iast']}+#{entry['word2_iast']}"

      front = "<center>#{'<big>' * 3}#{entry['word1_devanagari']} #{entry['word2_devanagari']}#{'</big>' * 3}</center>"

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
