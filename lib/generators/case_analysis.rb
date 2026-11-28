# frozen_string_literal: true

require_relative "base"
require_relative "../case_analysis"

module Generators
  # Rāmāyaṇa sentences taken apart case by case: the second declensions subdeck,
  # practised before the noun paradigms. A pure reader over data/case_analysis.json.
  #
  #   Front: the English sentence, nothing marked (spotting the declined words is
  #          part of the exercise)
  #   Back:  the Sanskrit sentence (sandhi broken) and a table with one row per
  #          declined word, in English order: English · form · class label
  #          (mAp) · the reason, plus any defensible alternative analysis
  #
  # Handout use numbers (2c, 1d …) are deliberately not shown — the learner won't
  # have the handout open, so the reason carries the teaching; the data keeps
  # them only for the coverage test. A word whose case use is not on the handout
  # is marked "(beyond the handout)". No audio, no JSON intermediate.
  class CaseAnalysis < Base
    KEY         = "case-analysis"
    DESCRIPTION = "Rāmāyaṇa sentences: every declined word's case and why (English -> analysis)"
    OUTPUT_TXT  = "sanskrit_declensions_2_case_analysis_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::CASE_ANALYSIS_DECK

    def build = ::CaseAnalysis.load["sentences"]

    def card(sentence)
      front = "<center><big><big>#{sentence['english']}</big></big><br><br><small>Case of each word, and why?</small></center>"
      back  = "<center><big><big>#{sentence['devanagari']}</big></big><br>#{sentence['iast']}</center><br>" \
              "<table>#{sentence['words'].map { |w| row(w) }.join}</table>"
      ["case_analysis:#{sentence['id']}", front, back]
    end

    private

    def row(word)
      reason = +""
      reason << "(beyond the handout) " unless word["use"]
      reason << word["why"]
      word["alternatives"].each do |alt|
        reason << "<br>or <b>#{label(word, alt['case'])}</b> — #{alt['why']}"
      end
      "<tr><td>#{word['english']}</td><td>#{word['devanagari']}</td>" \
        "<td><b>#{label(word, word['case'])}</b></td><td>#{reason}</td></tr>"
    end

    def label(word, kase) = ::CaseAnalysis.label(word["gender"], kase, word["number"])
  end
end
