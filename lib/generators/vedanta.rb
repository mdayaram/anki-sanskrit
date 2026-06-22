# frozen_string_literal: true

require_relative "base"
require_relative "../vedanta"

module Generators
  # Vedanta glossary word deck. Pure transform over data/vedanta.json (the
  # committed source of truth). One card per term:
  #   Front: the Devanagari term (large, centered)
  #   Back:  IAST + English definition
  # No audio.
  class Vedanta < Base
    KEY         = "vedanta"
    DESCRIPTION = "Vedanta glossary terms (Devanagari -> IAST + meaning)"
    OUTPUT_TXT  = "sanskrit_vedanta_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::VEDANTA_DECK

    def build = ::Vedanta.load

    def card(entry)
      iast = entry["iast"]
      key  = "vedanta:#{iast}"
      front = "<center><big>#{br(entry['devanagari'])}</big></center>"
      back  = "<b>#{br(iast)}</b><br><br>#{br(entry['definition'].to_s)}"
      [key, front, back]
    end

    private

    def br(text)
      text.to_s.gsub(/\r?\n/, "<br>")
    end
  end
end
