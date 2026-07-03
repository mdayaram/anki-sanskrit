# frozen_string_literal: true

require "json"
require_relative "paths"

# Loads data/vowel_sandhi.json (the committed source of truth for the vowel
# (svara) sandhi deck). Pure reader, mirroring Letters/Gita/Vedanta. Named
# VowelSandhiDeck because the VowelSandhi module (lib/vowel_sandhi.rb) is the join
# engine; here we only read the curated cards. The engine + IastDevanagari.valid_pair?
# validate this data in the tests.
module VowelSandhiDeck
  def self.load(path = Paths.data("vowel_sandhi.json"))
    unless File.exist?(path)
      abort "ERROR: #{path} not found."
    end

    JSON.parse(File.read(path))
  end
end
