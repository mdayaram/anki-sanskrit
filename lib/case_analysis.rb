# frozen_string_literal: true

require "json"
require_relative "paths"

# Loads data/case_analysis.json, the committed source of truth for the Case
# Analysis deck: Rāmāyaṇa sentences with every declined word analysed (case,
# handout use, reason). Pure reader, like CaseFunctions: nothing is derived, and
# the data is validated in test/case_analysis_data_test.rb.
#
# Also builds the class's cell label: lowercase gender + Capital case + lowercase
# number, e.g. "mAp" (masculine Accusative plural). Ablative is "Ab" so it stays
# distinct from Accusative "A"; a word with no grammatical gender (अहम्, त्वम्)
# drops the gender letter ("Ns").
module CaseAnalysis
  CASE_ABBREVIATIONS = {
    "nominative" => "N", "accusative" => "A", "instrumental" => "I", "dative" => "D",
    "ablative" => "Ab", "genitive" => "G", "locative" => "L", "vocative" => "V"
  }.freeze
  NUMBER_LETTERS = { "singular" => "s", "dual" => "d", "plural" => "p" }.freeze

  def self.load(path = Paths.data("case_analysis.json"))
    abort "ERROR: #{path} not found." unless File.exist?(path)

    JSON.parse(File.read(path))
  end

  def self.label(gender, kase, number)
    "#{gender}#{CASE_ABBREVIATIONS.fetch(kase)}#{NUMBER_LETTERS.fetch(number)}"
  end
end
