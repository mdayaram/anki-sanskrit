# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/t_nouns"

# Rendering checks on the noun-paradigm decks. The card DATA is validated by
# test/declensions_data_test.rb.
class DeclensionsTest < Minitest::Test
  def data = @data ||= Declensions.load
  def gen = @gen ||= Generators::TNouns.new([], {})
  def cards = @cards ||= gen.build.map { |e| [e, gen.card(e)] }

  def test_paradigm_is_a_declensions_subdeck
    assert_equal "#{Anki::DECLENSIONS_PARENT}::2. त्-Ending Nouns", gen.deck
    refute Generators::TNouns.requires_letters?
  end

  def test_every_form_of_every_noun_is_carded_once
    assert_equal data["nouns"].sum { |n| n["forms"].size }, cards.size
    keys = cards.map { |_e, row| row[0] }
    assert_equal keys.size, keys.uniq.size
    assert keys.all? { |k| k.start_with?("t_noun:") }
  end

  # One subdeck per case, numbered by the case's Sanskrit number, so Anki's sort
  # gives प्रथमा … संबोधनम्; each holds every noun in that case, in all 3 numbers.
  def test_one_subdeck_per_case
    by_deck = cards.group_by { |_e, row| row[3] }
    expected = Declensions::CASES.each_with_index.map do |kase, i|
      "#{gen.deck}::#{i + 1}. #{Declensions.case_names.fetch(kase)['english']}"
    end
    assert_equal expected, by_deck.keys.sort
    assert_equal expected, expected.sort, "subdecks sort in case order"
    by_deck.each do |deck, rows|
      cases = rows.map { |e, _| e["form"]["case"] }.uniq
      assert_equal 1, cases.size, deck
      assert_equal data["nouns"].size * Declensions::NUMBERS.size, rows.size, deck
    end
  end

  # The front names the stem and the cell but never the form — except where the
  # form IS the stem (मरुत् nominative singular), which is the point of that card.
  def test_noun_cards_hide_the_form
    cards.each do |entry, (_k, front, back)|
      form = entry["form"]["devanagari"]
      assert_includes front, entry["noun"]["devanagari"]
      refute_includes front, form unless form == entry["noun"]["devanagari"]
      assert_includes back, "<b>#{form}</b>"
      assert_includes back, entry["form"]["iast"]
    end
  end

  def test_noun_cards_explain_sandhi_and_name_identical_forms
    by_key = cards.to_h { |_e, (k, f, b)| [k, [f, b]] }
    _f, back = by_key.fetch("t_noun:marut:instrumental:plural")
    assert_includes back, "मरुत् + भिः → मरुद्भिः"
    assert_includes back, data["sandhi"]["voicing"]

    _f, back = by_key.fetch("t_noun:jagat:nominative:plural")
    assert_includes back, data["sandhi"]["num"]
    assert_includes back, "accusative plural, vocative plural"
  end

  def test_no_inline_styles
    cards.each { |_e, (_k, f, b)| refute_match(/style=/, f + b) }
  end
end
