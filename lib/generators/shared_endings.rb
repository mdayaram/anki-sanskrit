# frozen_string_literal: true

require_relative "base"
require_relative "../declensions"

module Generators
  # The basic endings asked the other way, ending -> every cell it marks: अः →
  # nominative plural, accusative plural, ablative singular, genitive singular.
  # This is the class 15 exercise of circling the identical endings on the
  # "Basic Terminations" handout, and the skill reading needs: an ending alone
  # rarely tells you the case, so you learn the short list it could be.
  #
  #   Front: the ending
  #   Back:  every case + number it marks (and for which genders), with the
  #          vocative, which only repeats the nominative, noted on its own line
  #
  # One card per distinct ending, the neuter's ई included (its empty ending is
  # left out). A pure reader over data/declensions.json. No audio, no JSON
  # intermediate.
  class SharedEndings < Base
    KEY         = "shared-endings"
    DESCRIPTION = "Sanskrit basic endings shared by several cases (ending -> every case + number)"
    OUTPUT_TXT  = "sanskrit_shared_endings_anki.txt"

    SCOPES = { "m/f" => " (masc./fem.)", "n" => " (neuter)", "all" => "" }.freeze

    def self.requires_letters? = false
    def deck = Anki::SHARED_ENDINGS_DECK

    def build = Declensions.shared_endings(Declensions.load).values

    def card(entry)
      e = entry["ending"]
      front = "#{Anki.glyph_front(Declensions.ending_html(e))}<center><small>Which cases and numbers take this basic ending?</small></center>"

      cells, vocative = entry["cells"].partition { |c| c["case"] != "vocative" }
      items = cells.map { |c| "<li>#{Declensions.cell_name(c['case'], c['number'])}#{SCOPES.fetch(c['scope'])}</li>" }
      back = +"<center>#{'<big>' * 3}#{Declensions.ending_html(e)}#{'</big>' * 3}<br>#{Declensions.ending_iast(e)}</center>"
      back << "<ul>#{items.join}</ul>"
      notes = []
      notes << "Only this one cell." if cells.size == 1 && vocative.empty?
      unless vocative.empty?
        notes << "#{cells.size == 1 ? 'Only this cell, plus' : 'Also'} the vocative " \
                 "#{vocative.map { |c| c['number'] }.join(', ')}, which repeats the nominative."
      end
      if entry["cells"].any? { |c| c["scope"] == "n" && c["number"] == "plural" }
        notes << "After a consonant stem the neuter plural also inserts न् (जगत् → जगन्ति)."
      end
      back << "<center><small>#{notes.join(' ')}</small></center>" unless notes.empty?
      ["shared_ending:#{e['iast']}", front, back]
    end
  end
end
