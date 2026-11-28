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

  # The cases come first, then each noun paradigm.
  def test_declension_subdecks_sort_in_learning_order
    decks = [Anki::CASE_NAMES_DECK, Anki::CASE_ANALYSIS_DECK, Anki::T_NOUNS_DECK]
    decks.each { |d| assert d.start_with?("#{Anki::DECLENSIONS_PARENT}::"), d }
    assert_equal decks.sort, decks
  end

  def test_case_subdeck_nests_under_its_paradigm
    assert_equal "#{Anki::T_NOUNS_DECK}::3. Instrumental", Anki.case_subdeck(Anki::T_NOUNS_DECK, 3, "Instrumental")
  end

  # A row carrying a 4th element names its own deck: the file switches from a
  # #deck header to a Deck column.
  def test_per_row_deck_uses_a_deck_column
    out = write([["k1", "f", "b", "A::1"], ["k2", "f", "b", "A::2"]], deck: "ignored")
    assert_includes out, "#deck column:4"
    assert_includes out, "#columns:Key\tFront\tBack\tDeck"
    refute_includes out, "#deck:"
    assert_includes out, "k2\tf\tb\tA::2"
  end

  def test_per_row_deck_must_be_on_every_row
    assert_raises(ArgumentError) { write([["k1", "f", "b", "A::1"], ["k2", "f", "b"]]) }
  end

  def test_alphabet_subdecks_sort_in_learning_order
    decks = [Anki::ALPHABET_VOWELS_DECK, Anki::ALPHABET_CONSONANTS_DECK, Anki::ALPHABET_COMBINATIONS_DECK,
             Anki::ALPHABET_CONJUNCTS_DECK, Anki::ALPHABET_ANUSVARA_DECK]
    decks.each { |d| assert d.start_with?("#{Anki::DECK}::"), d }
    assert_equal decks.sort, decks
  end
end
