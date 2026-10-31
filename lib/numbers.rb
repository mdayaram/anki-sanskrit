# frozen_string_literal: true

require "json"
require_relative "paths"

# Loads data/numbers.json (the committed source of truth for the numbers deck).
# Pure reader, mirroring Vedanta/VisargaSandhiDeck. Nothing is derived: every
# form is curated and validated in test/numbers_data_test.rb.
module Numbers
  # Devanagari digits ०-९ (U+0966-U+096F), in value order.
  DEVANAGARI_DIGITS = "०१२३४५६७८९"

  def self.load(path = Paths.data("numbers.json"))
    abort "ERROR: #{path} not found." unless File.exist?(path)

    JSON.parse(File.read(path))
  end

  # Western digits -> Devanagari digits (other characters pass through).
  def self.to_devanagari_digits(text) = text.to_s.tr("0-9", DEVANAGARI_DIGITS)

  # Devanagari digits -> Western digits (other characters pass through).
  def self.to_western_digits(text) = text.to_s.tr(DEVANAGARI_DIGITS, "0-9")
end
