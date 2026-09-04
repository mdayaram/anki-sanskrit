# frozen_string_literal: true

require "json"
require_relative "paths"

# Loads data/external_consonant_sandhi.json (the committed source of truth for the
# external consonant sandhi deck). Pure reader, mirroring VisargaSandhiDeck.
#
# Like the visarga deck there is deliberately no derivation engine: the rules and
# their worked examples are curated from the Arsha Bodha "Consonant Sandhi"
# handout (12 external rules), cross-checked against Whitney, Ruppel and
# learnsanskrit.org. Only the Devanagari<->IAST spelling of each stored form is
# validated (IastDevanagari.valid_pair?) in
# test/external_consonant_sandhi_deck_test.rb.
module ExternalConsonantSandhiDeck
  def self.load(path = Paths.data("external_consonant_sandhi.json"))
    unless File.exist?(path)
      abort "ERROR: #{path} not found."
    end

    JSON.parse(File.read(path))
  end
end
