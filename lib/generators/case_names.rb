# frozen_string_literal: true

require_relative "base"
require_relative "../case_functions"
require_relative "../declensions"

module Generators
  # The eight Sanskrit cases, asked English -> Sanskrit: the first subdeck of the
  # declensions, a pure reader over data/case_functions.json (names and uses) and
  # data/declensions.json (endings).
  #
  #   Front: Accusative
  #   Back:  द्वितीया dvitīyā “second”, its core sense and cue, the case's basic
  #          endings (singular · dual · plural, with the neuter's own row where it
  #          differs), then every one of the handout's numbered uses (2a … 2d)
  #
  # Only the English -> Sanskrit direction is carded: the class works with the
  # English case names. The endings are read from data/declensions.json, the same
  # table the noun decks derive their forms from, so the two cannot drift apart.
  # No audio, no JSON intermediate.
  class CaseNames < Base
    KEY         = "case-names"
    DESCRIPTION = "Sanskrit cases (Nominative … Vocative -> प्रथमा … संबोधनम्, with endings and every use)"
    OUTPUT_TXT  = "sanskrit_declensions_1_cases_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::CASE_NAMES_DECK

    def build
      data = CaseFunctions.load
      data["cases"].map { |c| { "case" => c, "uses" => data["uses"].select { |u| u["case"] == c["id"] } } }
    end

    def card(entry)
      @declensions ||= Declensions.load
      c = entry["case"]
      front = "<center>#{'<big>' * 4}#{c['english']}#{'</big>' * 4}<br><small>Sanskrit name?</small></center>"
      back  = "<center>#{'<big>' * 4}#{c['devanagari']}#{'</big>' * 4}" \
              "<br><big>#{c['iast']}</big> “#{c['literal']}”" \
              "#{details(c)}#{endings_html(c['id'])}</center>#{uses_html(entry['uses'])}"
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

    # The case's basic endings as a small table: one row for every gender, or,
    # where the neuter has its own ending (nominative, accusative, vocative), a
    # masculine/feminine row and a neuter row.
    def endings_html(kase)
      rows = if Declensions::NEUTER_CASES.include?(kase)
               [["masc. / fem.", "m"], ["neuter", "n"]]
             else
               [["all genders", "m"]]
             end
      header = "<tr><td></td>#{Declensions::NUMBERS.map { |n| "<td><small>#{n}</small></td>" }.join}</tr>"
      body = rows.map do |label, gender|
        cells = Declensions::NUMBERS.map { |n| "<td><b>#{ending_cell(kase, n, gender)}</b></td>" }.join
        "<tr><td><small>#{label}</small></td>#{cells}</tr>"
      end.join
      notes = Declensions::NUMBERS.filter_map { |n| Declensions.mf_ending(@declensions, kase, n)["note"] }.uniq
      html = +"<br><br><b>Endings</b><table>#{header}#{body}</table>"
      html << notes.map { |note| "<small>#{note}</small>" }.join("<br>")
      html
    end

    # An ending in a table cell: the neuter's empty ending is a bare dash.
    def ending_cell(kase, number, gender)
      e = Declensions.ending(@declensions, kase, number, gender)
      e["devanagari"].empty? ? "—" : Declensions.ending_html(e)
    end

    # The handout's numbered uses, left-aligned so a long list stays readable.
    def uses_html(uses)
      items = uses.map { |u| "<li><b>#{u['id']}</b> #{u['description']}</li>" }.join
      "<br><b>Uses</b><ul>#{items}</ul>"
    end
  end
end
