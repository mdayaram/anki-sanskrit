# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/visarga_sandhi_split"
require_relative "../lib/visarga_sandhi_deck"

# Rendering check on the visarga-sandhi splitting generator. The card DATA is
# already validated by test/visarga_sandhi_deck_test.rb; this only covers the
# inverse rendering transform (front = primary combined form, back = the split +
# underlying form + alternates + rule).
class VisargaSandhiSplitDeckTest < Minitest::Test
  def gen     = @gen     ||= Generators::VisargaSandhiSplit.new([], {})
  def entries = @entries ||= VisargaSandhiDeck.load
  def cards   = @cards   ||= gen.build.map { |e| gen.card(e) }

  def test_one_card_per_record
    assert_equal entries.size, cards.size
  end

  def test_keys_unique_and_prefixed
    keys = cards.map { |k, _f, _b| k }
    assert keys.all? { |k| k.start_with?("visarga_sandhi_split:") }, "every key uses the split prefix"
    assert_equal keys.size, keys.uniq.size, "keys are unique"
  end

  def test_front_prompts_with_primary_combined_form
    gen.build.zip(cards).each do |e, (_key, front, _back)|
      assert front.include?(e["combined"].first["devanagari"]), "front shows the primary combined form"
    end
  end

  def test_back_reveals_split_and_underlying
    gen.build.zip(cards).each do |e, (_key, _front, back)|
      assert back.include?(e["word1_devanagari"]),            "back shows word1"
      assert back.include?(e["word2_devanagari"]),            "back shows word2"
      assert back.include?(e["word1_underlying_devanagari"]), "back shows the underlying form"
    end
  end

  def test_back_shows_alternate_forms_when_present
    multi = gen.build.zip(cards).select { |e, _c| e["combined"].size > 1 }
    refute_empty multi, "fixture should contain multi-form records"
    multi.each do |e, (_key, _front, back)|
      e["combined"].drop(1).each do |alt|
        assert back.include?(alt["devanagari"]), "back shows alternate form #{alt['devanagari']}"
      end
    end
  end

  def test_targets_the_split_deck
    assert_equal "🕉️ Sanskrit Visarga Sandhi (Splitting)", gen.deck
  end
end
