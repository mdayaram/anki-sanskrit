# frozen_string_literal: true

require_relative "base"
require_relative "../case_functions"

module Generators
  # Example sentences, asked sentence -> case + use. One of the three
  # case-function decks, all pure readers over data/case_functions.json.
  #
  #   Front: the sentence in Devanagari (sandhi broken, as in the handout) with the
  #          target word in bold, and the English with that word underlined. The
  #          English is on the front on purpose: the deck tests the FUNCTION of a
  #          case, before the endings that mark it have been learned.
  #   Back:  the case, the handout's use number + description, the target word's
  #          stem, gender and number, the IAST of the sentence, an optional note
  #          and the source.
  #
  # Sentences come from the handout, the teacher's in-class examples and the
  # Goldman Rāmāyaṇa readings the class uses. No audio, no JSON intermediate.
  class CaseExamples < Base
    KEY         = "case-examples"
    DESCRIPTION = "Sanskrit case examples (a sentence with one word in bold -> its case and use)"
    OUTPUT_TXT  = "sanskrit_case_examples_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::CASE_EXAMPLES_DECK

    def build
      data = CaseFunctions.load
      data["examples"].map do |e|
        use = CaseFunctions.use(data, e["use"])
        { "example" => e, "use" => use, "case" => CaseFunctions.case_record(data, use["case"]) }
      end
    end

    def card(entry)
      e = entry["example"]
      u = entry["use"]
      c = entry["case"]
      t = e["target"]

      front = "<center>#{'<big>' * 3}#{CaseFunctions.bold_target(e['devanagari'], t['devanagari'])}#{'</big>' * 3}" \
              "<br><big>#{CaseFunctions.english_html(e['english'])}</big>" \
              "<br><small>Which case, and which use?</small></center>"

      grammar = "#{CaseFunctions::GENDERS.fetch(t['gender'])} #{c['english'].downcase} #{t['number']}"
      back = +"<center>#{'<big>' * 3}<b>#{CaseFunctions.case_label(c)}</b>#{'</big>' * 3}" \
              "<br><br><b>#{u['id']}</b> #{u['description']}" \
              "<br><br><big><b>#{t['devanagari']}</b> #{t['iast']}</big> ← #{t['stem_devanagari']} #{t['stem_iast']} “#{t['meaning']}”" \
              "<br>#{grammar}" \
              "<br><br>#{e['iast']}"
      back << "<br><br><small>#{e['note']}</small>" if e["note"]
      back << "<br><br><small>source: #{e['source']}</small></center>"
      ["case_example:#{e['id']}", front, back]
    end
  end
end
