# frozen_string_literal: true

require "json"
require_relative "paths"
require_relative "case_functions"

# Loads data/declensions.json, the committed source of truth for the declension
# decks, and holds the shared lookups and rendering helpers. Pure reader: the
# data is validated (every form re-derived from stem + ending) in
# test/declensions_data_test.rb.
#
# The file follows the Arsha Bodha "Basic Terminations" handout (class 15):
#   endings         the masculine/feminine table, 8 cases x 3 numbers
#   neuter_endings  the neuter's own nominative/accusative/vocative (− ई इ);
#                   every other neuter cell is "as above"
#   sandhi          the text for each change a stem + ending can undergo
#   nouns           the class's त्-ending nouns, each with all 24 forms
# Case names come from data/case_functions.json, so they read the same on
# every deck.
module Declensions
  CASES   = %w[nominative accusative instrumental dative ablative genitive locative vocative].freeze
  NUMBERS = %w[singular dual plural].freeze
  # The cells where the neuter has its own ending.
  NEUTER_CASES = %w[nominative accusative vocative].freeze
  GENDERS = { "m" => "masculine", "f" => "feminine", "n" => "neuter" }.freeze

  def self.load(path = Paths.data("declensions.json"))
    abort "ERROR: #{path} not found." unless File.exist?(path)

    JSON.parse(File.read(path))
  end

  # Case id -> the case record from data/case_functions.json.
  def self.case_names = @case_names ||= CaseFunctions.load["cases"].to_h { |c| [c["id"], c] }

  # "Instrumental (तृतीया) dual".
  def self.cell_label(kase, number) = "#{CaseFunctions.case_label(case_names.fetch(kase))} #{number}"

  # Shorter, for lists: "instrumental dual".
  def self.cell_name(kase, number) = "#{kase} #{number}"

  def self.mf_ending(data, kase, number) = data["endings"].find { |e| e["case"] == kase && e["number"] == number }

  # The ending a noun of this gender takes in this cell.
  def self.ending(data, kase, number, gender)
    if gender == "n" && NEUTER_CASES.include?(kase)
      data["neuter_endings"].find { |e| e["case"] == kase && e["number"] == number }
    else
      mf_ending(data, kase, number)
    end
  end

  # An ending as printed on a card. A bare sign (the visarga of the nominative
  # singular) sits on the dotted circle, as on the alphabet decks; the neuter's
  # empty ending is spelled out.
  def self.ending_html(e)
    dev = e["devanagari"]
    return "— (no ending)" if dev.empty?

    dev.start_with?("ः") ? "◌#{dev}" : dev
  end

  # "मरुत् + भिः → मरुद्भिः", the working shown on a form's back.
  def self.working(noun, form, ending)
    "#{noun['devanagari']} + #{ending_html(ending)} → #{form['devanagari']}"
  end
end
