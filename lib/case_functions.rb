# frozen_string_literal: true

require "json"
require_relative "paths"

# Loads data/case_functions.json, the committed source of truth for the cases
# deck (case names with their uses) and for the case names every declension card
# prints. Pure reader, like Numbers/VisargaSandhiDeck: nothing is derived, and
# the data is validated in test/case_functions_data_test.rb.
#
# The file has three sections, following the Arsha Bodha "Sanskrit Case
# Functions" handout (Vibhakti_1.pdf):
#   cases     the 8 cases (प्रथमा … संबोधनम्) with English name and core sense
#   uses      the handout's numbered sub-uses, 1a … 8a
#   examples  sentences (sandhi broken) with one target word in a given use.
#             No deck renders them any more (a sentence deck was premature
#             before the endings are known); they are kept, and still validated,
#             to serve as context sentences on a later deck.
module CaseFunctions
  def self.load(path = Paths.data("case_functions.json"))
    abort "ERROR: #{path} not found." unless File.exist?(path)

    JSON.parse(File.read(path))
  end

  def self.use(data, id) = data["uses"].find { |u| u["id"] == id } || raise(KeyError, "no use #{id}")

  # "Accusative (द्वितीया)", the way every card names a case.
  def self.case_label(c) = "#{c['english']} (#{c['devanagari']})"
end
