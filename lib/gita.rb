# frozen_string_literal: true

require "json"
require_relative "paths"

# Loads data/gita.json (produced by fetch_gita.rb). The Gita verse generator is a
# pure transform over this data, so this is the single place that reads it.
module Gita
  # The ordered list of verse records, as fetched. Accepts an explicit path so
  # tests can point at a fixture.
  def self.load(path = Paths::GITA_JSON)
    unless File.exist?(path)
      abort "ERROR: #{path} not found.\n" \
            "Run `ruby fetch_gita.rb` first."
    end

    JSON.parse(File.read(path))
  end
end
