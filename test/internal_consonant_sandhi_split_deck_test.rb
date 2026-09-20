# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/internal_consonant_sandhi_split"
require_relative "../lib/internal_consonant_sandhi_deck"

# Rendering check on the internal consonant-sandhi splitting generator. The card
# DATA is already validated by test/internal_consonant_sandhi_deck_test.rb; this
# only covers the inverse rendering transform (front = the combined word, back =
# the morphemes it was built from + rule + analysis).
class InternalConsonantSandhiSplitDeckTest < Minitest::Test
  def gen     = @gen     ||= Generators::InternalConsonantSandhiSplit.new([], {})
  def records = @records ||= InternalConsonantSandhiDeck.load
  def cards   = @cards   ||= gen.build.map { |e| gen.card(e) }

  def find(iast) = gen.build.find { |e| e["combined"].first["iast"] == iast }

  # A contrast record shows a junction where the rule deliberately does NOT fire.
  # Splitting मरुत्सु at its obvious seam teaches nothing the forward card didn't,
  # so those records are left out of this direction.
  def test_contrast_records_are_not_carded
    assert records.any? { |r| r["contrast"] }, "fixture should contain contrast records"
    refute gen.build.any? { |e| e["contrast"] }, "no contrast record is carded"
    assert_equal records.count { |r| !r["contrast"] }, cards.size
  end

  def test_keys_unique_and_prefixed
    keys = cards.map { |k, _f, _b| k }
    assert keys.all? { |k| k.start_with?("internal_consonant_sandhi_split:") }, "every key uses the split prefix"
    assert_equal keys.size, keys.uniq.size, "keys are unique"
  end

  def test_front_prompts_with_the_combined_word_only
    gen.build.zip(cards).each do |e, (_key, front, _back)|
      assert_includes front, e["combined"].first["devanagari"]
      refute_includes front, " + " # the morpheme split must not leak onto the front
    end
  end

  def test_back_reveals_the_morphemes
    key, _front, back = gen.card(find("viṣīdati"))

    assert_equal "internal_consonant_sandhi_split:satva:vi+sīdati", key
    assert_includes back, "वि + सीदति"
    assert_includes back, "viṣīdati → vi + sīdati"
    assert_includes back, "स् becomes ष्"
  end

  # The analysis line names the trigger, which is exactly what tells the reader
  # that the ष् they are looking at is an underlying स्.
  def test_analysis_is_rendered
    _, _, back = gen.card(find("viṣīdati"))
    assert_includes back, "trigger इ"
  end

  def test_every_card_renders_without_inline_styles
    cards.each do |key, front, back|
      refute_empty key
      refute_empty front
      refute_empty back
      refute_includes front, "style="
      refute_includes back, "style="
    end
  end

  def test_targets_the_split_deck
    assert_equal "🕉️ Sanskrit Internal Consonant Sandhi (Splitting)", gen.deck
  end

  def test_does_not_require_letters
    refute Generators::InternalConsonantSandhiSplit.requires_letters?
  end

  def test_no_audio
    assert_empty gen.audio_files(gen.build)
  end
end
