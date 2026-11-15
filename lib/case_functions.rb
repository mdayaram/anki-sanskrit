# frozen_string_literal: true

require "json"
require_relative "paths"

# Loads data/case_functions.json, the committed source of truth for the three
# case-function decks (case names, case uses, case examples). Pure reader, like
# Numbers/VisargaSandhiDeck: nothing is derived, and the data is validated in
# test/case_functions_data_test.rb.
#
# The file has three sections, following the Arsha Bodha "Sanskrit Case
# Functions" handout (Vibhakti_1.pdf):
#   cases     the 8 cases (प्रथमा … संबोधनम्) with English name and core sense
#   uses      the handout's numbered sub-uses, 1a … 8a
#   examples  sentences (sandhi broken) with one target word in a given use
module CaseFunctions
  GENDERS = { "m" => "masc.", "f" => "fem.", "n" => "neut." }.freeze

  def self.load(path = Paths.data("case_functions.json"))
    abort "ERROR: #{path} not found." unless File.exist?(path)

    JSON.parse(File.read(path))
  end

  def self.case_record(data, id) = data["cases"].find { |c| c["id"] == id } || raise(KeyError, "no case #{id}")
  def self.use(data, id) = data["uses"].find { |u| u["id"] == id } || raise(KeyError, "no use #{id}")

  # "Accusative (द्वितीया)", the way every card names a case.
  def self.case_label(c) = "#{c['english']} (#{c['devanagari']})"

  # English with its [target] rendered underlined, as the handout does.
  def self.english_html(english) = english.sub(/\[([^\]]+)\]/, '<u>\1</u>')

  # The sentence with the target word (a whole space-separated token) in bold.
  def self.bold_target(sentence, target)
    sentence.split(" ").map { |w| w == target ? "<b>#{w}</b>" : w }.join(" ")
  end
end
