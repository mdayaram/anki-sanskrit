# frozen_string_literal: true

require "json"
require_relative "paths"

# Loads data/visarga_sandhi.json (the committed source of truth for the visarga
# sandhi deck). Pure reader, mirroring Letters/Gita/Vedanta/VowelSandhiDeck.
#
# Unlike the vowel-sandhi deck there is deliberately no derivation engine: visarga
# outcomes are curated by hand from worked examples in the sources (Whitney,
# learnsanskrit.org) and only the Devanagari<->IAST spelling of each stored form is
# validated (IastDevanagari.valid_pair?) in test/visarga_sandhi_deck_test.rb.
module VisargaSandhiDeck
  def self.load(path = Paths.data("visarga_sandhi.json"))
    unless File.exist?(path)
      abort "ERROR: #{path} not found."
    end

    JSON.parse(File.read(path))
  end
end
