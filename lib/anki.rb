# frozen_string_literal: true

require "json"

# Shared Anki card primitives. Every generator targets the same deck and the same
# tab-separated import format, so the header and field handling live here once.
#
# Card HTML avoids inline style="..." attributes: semicolons inside styles
# collide with parsers that read the TSV as semicolon-separated. Use <big>,
# <center>, <b>, <ul> instead.
module Anki
  # All categories merge into one deck, so importing every file builds one deck.
  DECK = "🕉️ Sanskrit Alphabet"

  # The Bhagavad Gita verse deck (a separate deck from the alphabet).
  GITA_DECK = "🕉️ Bhagavad Gita"

  # The Vedanta glossary word deck (a separate deck).
  VEDANTA_DECK = "🕉️ Vedanta Glossary"

  # The vowel-sandhi deck (a separate deck).
  SANDHI_DECK = "🕉️ Sanskrit Sandhi"

  # A large centered glyph: the text wrapped in five nested <big> tags.
  def self.glyph_front(text)
    "<center>#{'<big>' * 5}#{text}#{'</big>' * 5}</center>"
  end

  # Write an Anki import file: the standard 6-line header followed by one row per
  # entry. `rows` is an array of [key, front, back]; `deck:` sets the #deck header
  # (defaults to DECK). Tabs and newlines inside a field would break the row/column
  # split, so both are flattened to spaces. Returns the row count.
  def self.write_deck(path, rows, deck: DECK)
    File.open(path, "w:UTF-8") do |f|
      f.puts "#separator:Tab"
      f.puts "#html:true"
      f.puts "#deck:#{deck}"
      f.puts "#notetype:Basic"
      f.puts "#columns:Key\tFront\tBack"
      f.puts "#guid column:1"

      rows.each do |key, front, back|
        f.puts [key, front, back].map { |field| field.to_s.gsub(/\t/, " ").gsub(/\r?\n/, " ") }.join("\t")
      end
    end
    rows.size
  end

  # Write a pretty-printed JSON intermediate. Returns the entry count.
  def self.write_json(path, data)
    File.write(path, JSON.pretty_generate(data))
    data.size
  end
end
