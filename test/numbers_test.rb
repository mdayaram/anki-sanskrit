# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/numbers"

# Rendering check on the numbers generator. The card DATA is validated by
# test/numbers_data_test.rb.
class NumbersTest < Minitest::Test
  def gen   = @gen   ||= Generators::Numbers.new([], {})
  def data  = @data  ||= Numbers.load
  def cards = @cards ||= gen.build.map { |e| gen.card(e) }

  def test_deck_and_letters
    assert_equal Anki::NUMBERS_DECK, gen.deck
    refute Generators::Numbers.requires_letters?
  end

  def test_card_count
    expected = data["digits"].size + data["numerals"].size + (2 * data["cardinals"].size) +
               data["ordinals"].size + data["rules"].size
    assert_equal expected, cards.size
  end

  def test_keys_unique_and_prefixed
    keys = cards.map(&:first)
    assert keys.all? { |k| k.start_with?("numbers:") }
    assert_equal keys.size, keys.uniq.size
  end

  # Both directions of a cardinal must not give their answer away on the front.
  def test_cardinal_fronts_do_not_spoil_the_answer
    data["cardinals"].each do |c|
      _k, word_front, word_back = gen.card([:word_to_number, c])
      assert_includes word_front, c["devanagari"]
      refute_includes word_front, c["value"].to_s
      assert_includes word_back, c["value"].to_s

      _k, num_front, num_back = gen.card([:number_to_word, c])
      assert_includes num_front, c["value"].to_s
      refute_includes num_front, c["devanagari"]
      assert_includes num_back, c["devanagari"]
    end
  end

  def test_back_shows_alternates_and_gender_forms
    c = data["cardinals"].find { |x| x["value"] == 108 }
    _k, _f, back = gen.card([:word_to_number, c])
    assert_includes back, "अष्टाधिकशतम्"

    three = data["cardinals"].find { |x| x["value"] == 3 }
    _k, _f, back = gen.card([:number_to_word, three])
    assert_includes back, "तिस्रः"
  end

  def test_ordinal_card_names_the_chapter
    o = data["ordinals"].last
    _k, front, back = gen.card([:ordinal, o])
    assert_includes front, "अष्टादशोऽध्यायः"
    assert_includes back, "chapter 18"
    assert_includes back, "18th"
  end

  def test_ordinal_suffix
    assert_equal %w[st nd rd th th], [1, 2, 3, 4, 5].map { |n| Generators::Numbers.ordinal_suffix(n) }
    assert_equal %w[th th th], [11, 12, 13].map { |n| Generators::Numbers.ordinal_suffix(n) }
  end

  def test_no_inline_styles
    cards.each { |_k, f, b| refute_match(/style=/, f + b) }
  end
end
