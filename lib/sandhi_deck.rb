# frozen_string_literal: true

require "json"
require_relative "paths"

# Loads data/sandhi.json (the committed source of truth for the vowel-sandhi
# deck). Pure reader, mirroring Letters/Gita/Vedanta. Named SandhiDeck because the
# Sandhi module (lib/sandhi.rb) is the join engine; here we only read the curated
# cards. The engine + IastDevanagari.valid_pair? validate this data in the tests.
module SandhiDeck
  def self.load(path = Paths.data("sandhi.json"))
    unless File.exist?(path)
      abort "ERROR: #{path} not found."
    end

    JSON.parse(File.read(path))
  end
end
