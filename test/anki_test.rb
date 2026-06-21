# frozen_string_literal: true

require "minitest/autorun"
require "tempfile"
require_relative "../lib/anki"

class AnkiTest < Minitest::Test
  def write(rows, **opts)
    file = Tempfile.new(["deck", ".txt"])
    Anki.write_deck(file.path, rows, **opts)
    File.read(file.path)
  end

  def test_gita_deck_constant
    assert_equal "🕉️ Bhagavad Gita", Anki::GITA_DECK
  end

  def test_custom_deck_in_header
    assert_includes write([["k", "f", "b"]], deck: "My Deck"), "#deck:My Deck"
  end

  def test_default_deck_in_header
    assert_includes write([["k", "f", "b"]]), "#deck:#{Anki::DECK}"
  end

  def test_flattens_newlines_in_fields
    rows = write([["k", "line1\nline2", "b"]]).lines.reject { |l| l.start_with?("#") }
    assert_equal 1, rows.size
    assert_includes rows.first, "line1 line2"
  end
end
