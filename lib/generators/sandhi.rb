# frozen_string_literal: true

require_relative "base"
require_relative "../sandhi_deck"

module Generators
  # Vowel (svara) sandhi deck. Pure transform over data/sandhi.json (the committed
  # source of truth), read via SandhiDeck.load. Each record already holds the two
  # words and the combined form in both IAST and Devanagari, the rule name, and a
  # short explanation; the sandhi engine (lib/sandhi.rb) and IastDevanagari.valid_pair?
  # validate every record in test/sandhi_deck_test.rb rather than at generation time.
  #
  #   Front: the two parts in Devanagari, space-separated (देव इन्द्र)
  #   Back:  the combined Devanagari, the IAST (deva + indra → devendra),
  #          which sandhi fired, a brief rule explanation, and the CONTEXT.
  # No audio.
  #
  # Context matters because the front shows two pieces, and how vowels behave at a
  # junction depends on whether those pieces are two free words, the members of a
  # compound, or a stem+affix inside one word. The vowel rules give the same result
  # in all three EXCEPT for a word-final diphthong: between two words, e/o + a →
  # avagraha (te'pi) and ai/au reduce/retain (the ay/av of ayādi never appears
  # across a word boundary). So each record carries its context, and the two
  # context-bound rules are kept consistent (ayādi is internal, avagraha is between
  # words) — asserted in the deck test. Add a card by adding a record to
  # data/sandhi.json; the validating test checks the derivation and the Devanagari.
  class Sandhi < Base
    KEY         = "sandhi"
    DESCRIPTION = "Vowel sandhi (Devanagari word pair -> combined form + rule)"
    OUTPUT_TXT  = "sanskrit_sandhi_anki.txt"

    # How the two pieces relate, shown on the card so the junction isn't misread.
    CONTEXTS = {
      external: "between two separate words",
      compound: "within a compound",
      internal: "within a single word"
    }.freeze

    def self.requires_letters? = false
    def deck = Anki::SANDHI_DECK

    def build = SandhiDeck.load

    def card(entry)
      key     = "sandhi:#{entry['type']}:#{entry['word1_iast']}+#{entry['word2_iast']}"
      context = CONTEXTS.fetch(entry["context"].to_sym)
      front   = "<center>#{'<big>' * 3}#{entry['word1_devanagari']} #{entry['word2_devanagari']}#{'</big>' * 3}</center>"
      back    = "<center>#{'<big>' * 2}<b>#{entry['combined_devanagari']}</b>#{'</big>' * 2}" \
                "<br><big>#{entry['word1_iast']} + #{entry['word2_iast']} → #{entry['combined_iast']}</big>" \
                "<br><br><b>#{entry['sandhi_name']} sandhi (#{entry['sandhi_devanagari']})</b>" \
                "<br>#{entry['explanation']}" \
                "<br><small>(sandhi #{context})</small></center>"
      [key, front, back]
    end
  end
end
