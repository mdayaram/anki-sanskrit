# frozen_string_literal: true

require_relative "base"
require_relative "../case_functions"

module Generators
  # The eight Sanskrit case names, asked English -> Sanskrit. One of the two
  # case-function decks, both pure readers over data/case_functions.json.
  #
  #   Front: Accusative
  #   Back:  द्वितीया dvitīyā “second”, its core sense and cue, then every one of
  #          the handout's numbered uses for that case (2a … 2d)
  #
  # Only the English -> Sanskrit direction is carded: the class works with the
  # English case names. The handout's uses live on the back rather than in a deck
  # of their own. No audio, no JSON intermediate.
  class CaseNames < Base
    KEY         = "case-names"
    DESCRIPTION = "Sanskrit case names (Nominative … Vocative -> प्रथमा … संबोधनम्, with every use)"
    OUTPUT_TXT  = "sanskrit_case_functions_1_names_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::CASE_NAMES_DECK

    def build
      data = CaseFunctions.load
      data["cases"].map { |c| { "case" => c, "uses" => data["uses"].select { |u| u["case"] == c["id"] } } }
    end

    def card(entry)
      c = entry["case"]
      front = "<center>#{'<big>' * 4}#{c['english']}#{'</big>' * 4}<br><small>Sanskrit name?</small></center>"
      back  = "<center>#{'<big>' * 4}#{c['devanagari']}#{'</big>' * 4}" \
              "<br><big>#{c['iast']}</big> “#{c['literal']}”" \
              "#{details(c)}</center>#{uses_html(entry['uses'])}"
      ["case_name:english:#{c['id']}", front, back]
    end

    private

    # Where it sits in the list, what it does, its English cue.
    def details(c)
      html = +"<br><br>#{c['number'] == 8 ? 'listed 8th, after the seven numbered cases' : "case #{c['number']}"}"
      html << "<br>#{c['sense']}<br>cue: #{c['cue']}"
      html << "<br><br><small>#{c['note']}</small>" if c["note"]
      html
    end

    # The handout's numbered uses, left-aligned so a long list stays readable.
    def uses_html(uses)
      items = uses.map { |u| "<li><b>#{u['id']}</b> #{u['description']}</li>" }.join
      "<br><b>Uses</b><ul>#{items}</ul>"
    end
  end
end
