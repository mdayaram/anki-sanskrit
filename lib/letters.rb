# frozen_string_literal: true

require "json"
require_relative "paths"

# Loads data/letters.json (produced by scrape_sanskrit.rb). Every generator is a
# pure transform over this data, so this is the single place that reads it.
module Letters
  # The ordered list of letters, as scraped.
  def self.load
    unless File.exist?(Paths::LETTERS_JSON)
      abort "ERROR: #{Paths::LETTERS_JSON} not found.\n" \
            "Run `bundle exec ruby scrape_sanskrit.rb` first."
    end

    JSON.parse(File.read(Paths::LETTERS_JSON))
  end

  # The same letters keyed by their internal id (a, aa, RRi, kSha, …).
  def self.by_id(letters = load)
    letters.to_h { |l| [l["id"], l] }
  end
end
