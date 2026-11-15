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

  # The sandhi decks nest under two parents (joining, splitting) holding the same
  # four families, numbered so Anki's alphabetical sort gives the learning order.
  def test_sandhi_decks_nest_under_joining_and_splitting_parents
    joining = [Anki::VOWEL_SANDHI_DECK, Anki::VISARGA_SANDHI_DECK,
               Anki::EXTERNAL_CONSONANT_SANDHI_DECK, Anki::INTERNAL_CONSONANT_SANDHI_DECK]
    splitting = [Anki::VOWEL_SANDHI_SPLIT_DECK, Anki::VISARGA_SANDHI_SPLIT_DECK,
                 Anki::EXTERNAL_CONSONANT_SANDHI_SPLIT_DECK, Anki::INTERNAL_CONSONANT_SANDHI_SPLIT_DECK]
    families = ["1. Vowel", "2. Visarga", "3. External Consonant", "4. Internal Consonant"]

    assert_equal families.map { |f| "#{Anki::SANDHI_JOINING_PARENT}::#{f}" }, joining
    assert_equal families.map { |f| "#{Anki::SANDHI_SPLITTING_PARENT}::#{f}" }, splitting
    assert_equal joining.sort, joining, "joining subdecks sort in learning order"
  end

  def test_case_function_subdecks_sort_in_learning_order
    decks = [Anki::CASE_NAMES_DECK, Anki::CASE_USES_DECK, Anki::CASE_EXAMPLES_DECK]
    assert_equal decks.sort, decks
  end
end
