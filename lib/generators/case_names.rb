# frozen_string_literal: true

require_relative "base"
require_relative "../case_functions"

module Generators
  # The eight Sanskrit case names, in both directions. One of the three
  # case-function decks, all pure readers over data/case_functions.json.
  #
  #   sanskrit -> english   द्वितीया → Accusative, "second", direct object / "to"
  #   english  -> sanskrit  Accusative → द्वितीया dvitīyā
  #
  # The two directions carry distinct key prefixes so Anki keeps them as separate
  # notes. No audio, no JSON intermediate.
  class CaseNames < Base
    KEY         = "case-names"
    DESCRIPTION = "Sanskrit case names (प्रथमा … संबोधनम् <-> Nominative … Vocative)"
    OUTPUT_TXT  = "sanskrit_case_functions_1_names_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::CASE_NAMES_DECK

    def build
      CaseFunctions.load["cases"].flat_map { |c| [[:sanskrit, c], [:english, c]] }
    end

    def card((direction, c))
      send("#{direction}_card", c)
    end

    private

    def sanskrit_card(c)
      back = "<center>#{'<big>' * 3}<b>#{c['english']}</b>#{'</big>' * 3}" \
             "<br><big>#{c['devanagari']} #{c['iast']}</big> “#{c['literal']}”" \
             "#{details(c)}</center>"
      ["case_name:sanskrit:#{c['id']}", Anki.glyph_front(c["devanagari"]), back]
    end

    def english_card(c)
      front = "<center>#{'<big>' * 4}#{c['english']}#{'</big>' * 4}<br><small>Sanskrit name?</small></center>"
      back  = "<center>#{'<big>' * 4}#{c['devanagari']}#{'</big>' * 4}" \
              "<br><big>#{c['iast']}</big> “#{c['literal']}”" \
              "#{details(c)}</center>"
      ["case_name:english:#{c['id']}", front, back]
    end

    # Shared lower panel: where it sits in the list, what it does, its English cue.
    def details(c)
      html = +"<br><br>#{c['number'] == 8 ? 'listed 8th, after the seven numbered cases' : "case #{c['number']}"}"
      html << "<br>#{c['sense']}<br>cue: #{c['cue']}"
      html << "<br><br><small>#{c['note']}</small>" if c["note"]
      html
    end
  end
end
