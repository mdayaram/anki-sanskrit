# frozen_string_literal: true

require_relative "base"
require_relative "../case_functions"

module Generators
  # The handout's numbered case uses (1a … 8a), asked use -> case: "the object of
  # love or devotion" → Locative. One of the three case-function decks, all pure
  # readers over data/case_functions.json.
  #
  #   Front: the use, worded so it never names its own case (asserted by the data test)
  #   Back:  the case, the handout's number + description, and up to two examples
  #          from the examples section (the same sentences as the examples deck)
  #
  # Uses the handout gives no example for (3f, 3h, 6c …) still get a card; their
  # back simply has no example. No audio, no JSON intermediate.
  class CaseUses < Base
    KEY         = "case-uses"
    DESCRIPTION = "Sanskrit case uses (a use from the case-functions handout -> its case)"
    OUTPUT_TXT  = "sanskrit_case_uses_anki.txt"

    MAX_EXAMPLES = 2

    def self.requires_letters? = false
    def deck = Anki::CASE_USES_DECK

    def build
      data = CaseFunctions.load
      data["uses"].map do |u|
        { "use" => u,
          "case" => CaseFunctions.case_record(data, u["case"]),
          "examples" => data["examples"].select { |e| e["use"] == u["id"] }.first(MAX_EXAMPLES) }
      end
    end

    def card(entry)
      u = entry["use"]
      c = entry["case"]
      question = u["question"]
      prompt = question.end_with?("?") ? "" : "<br><small>Which case?</small>"
      front = "<center><big>#{question}</big>#{prompt}</center>"

      back = +"<center>#{'<big>' * 3}<b>#{CaseFunctions.case_label(c)}</b>#{'</big>' * 3}" \
              "<br><br><b>#{u['id']}</b> #{u['description']}"
      entry["examples"].each do |e|
        back << "<br><br><big>#{CaseFunctions.bold_target(e['devanagari'], e['target']['devanagari'])}</big>" \
                "<br>#{CaseFunctions.english_html(e['english'])}"
      end
      back << "</center>"
      ["case_use:#{u['id']}", front, back]
    end
  end
end
