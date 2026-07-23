# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/vowel_sandhi_split"
require_relative "../lib/vowel_sandhi_deck"

# Rendering check on the vowel-sandhi splitting generator. The card DATA is
# already validated by test/vowel_sandhi_deck_test.rb; this only covers the
# inverse rendering transform (front = combined form, back = the split + rule).
class VowelSandhiSplitDeckTest < Minitest::Test
  def gen     = @gen     ||= Generators::VowelSandhiSplit.new([], {})
  def entries = @entries ||= VowelSandhiDeck.load
  def cards   = @cards   ||= gen.build.map { |e| gen.card(e) }

  def test_one_card_per_record
    assert_equal entries.size, cards.size
  end

  def test_keys_unique_and_prefixed
    keys = cards.map { |k, _f, _b| k }
    assert keys.all? { |k| k.start_with?("vowel_sandhi_split:") }, "every key uses the split prefix"
    assert_equal keys.size, keys.uniq.size, "keys are unique"
  end

  def test_front_prompts_with_combined_and_back_reveals_split
    gen.build.zip(cards).each do |e, (_key, front, back)|
      assert front.include?(e["combined_devanagari"]), "front shows the combined form"
      assert back.include?(e["word1_devanagari"]),     "back shows word1"
      assert back.include?(e["word2_devanagari"]),     "back shows word2"
      assert back.include?(e["combined_iast"]),        "back shows the combined IAST"
    end
  end

  def test_targets_the_split_deck
    assert_equal "🕉️ Sanskrit Vowel Sandhi (Splitting)", gen.deck
  end
end
