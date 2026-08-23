# frozen_string_literal: true

require "json"
require_relative "paths"

# Loads data/mantras.json (the committed source of truth for the mantra deck).
# Pure reader, mirroring Letters/Gita/Vedanta/VisargaSandhiDeck. Nothing about a
# mantra is derived: the Devanagari, its transliteration, the translations and the
# word gloss are all curated, and test/mantras_data_test.rb checks that the
# Devanagari and the IAST are the same text (IastDevanagari.valid_pair?).
module Mantras
  def self.load(path = Paths.data("mantras.json"))
    unless File.exist?(path)
      abort "ERROR: #{path} not found."
    end

    JSON.parse(File.read(path))
  end
end
