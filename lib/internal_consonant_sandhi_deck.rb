# frozen_string_literal: true

require "json"
require_relative "paths"

# Loads data/internal_consonant_sandhi.json (the committed source of truth for the
# internal consonant sandhi deck) — the handout's two internal rules, ṣatva
# (स् -> ष्) and ṇatva (न् -> ण्). Pure reader, sibling of
# ExternalConsonantSandhiDeck.
module InternalConsonantSandhiDeck
  def self.load(path = Paths.data("internal_consonant_sandhi.json"))
    unless File.exist?(path)
      abort "ERROR: #{path} not found."
    end

    JSON.parse(File.read(path))
  end
end
