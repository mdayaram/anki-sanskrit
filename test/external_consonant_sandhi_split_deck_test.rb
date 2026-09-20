# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/external_consonant_sandhi_split"
require_relative "../lib/external_consonant_sandhi_deck"

# Rendering check on the external consonant-sandhi splitting generator. The card
# DATA is already validated by test/external_consonant_sandhi_deck_test.rb; this
# only covers the inverse rendering transform (front = the joined form, back =
# the split + underlying form + alternates + rule).
class ExternalConsonantSandhiSplitDeckTest < Minitest::Test
  def gen     = @gen     ||= Generators::ExternalConsonantSandhiSplit.new([], {})
  def records = @records ||= ExternalConsonantSandhiDeck.load
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
    assert keys.all? { |k| k.start_with?("external_consonant_sandhi_split:") }, "every key uses the split prefix"
    assert_equal keys.size, keys.uniq.size, "keys are unique"
  end

  # The prompt is the joined form and nothing else. It necessarily CONTAINS the
  # two words (that is what joining them means), so what must not leak is the
  # split itself — the "+" that marks the seam — and the rule that made it.
  def test_front_prompts_with_the_joined_form_only
    gen.build.zip(cards).each do |e, (_key, front, _back)|
      assert_includes front, e["combined"].first["devanagari"]
      refute_includes front, " + "
      refute_includes front, e["rule"]
    end
  end

  def test_back_reveals_the_split
    key, _front, back = gen.card(find("vāgdevī"))

    assert_equal "external_consonant_sandhi_split:hc_voicing:vāk+devī", key
    assert_includes back, "वाक् + देवी"
    assert_includes back, "vāgdevī → vāk + devī"
    assert_includes back, "voiced consonant of its own class"
  end

  # word1's citation form is shown only where the padānta reduction changed it:
  # वाक् comes from वाच्, but तत् + च needs no such note.
  def test_underlying_form_is_shown_only_when_present
    _, _, with_underlying = gen.card(find("vāgdevī"))
    assert_includes with_underlying, "वाक् ← वाच्"

    entry = find("tāṃstitikṣasva")
    assert_nil entry["word1_underlying_devanagari"]
    _, _, without_underlying = gen.card(entry)
    refute_includes without_underlying, "←"
  end

  # A record can list several accepted outcomes; the card prompts on the primary
  # one and names the rest on the back, so an alternate spelling is still
  # recognised as the same junction.
  def test_alternate_forms_are_named_on_the_back
    entry = find("taddhi")
    assert_equal 2, entry["combined"].size

    _, front, back = gen.card(entry)
    assert_includes front, "तद्धि"
    refute_includes front, "तद् हि"
    assert_includes back, "तद् हि"
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
    assert_equal "🕉️ Sanskrit External Consonant Sandhi (Splitting)", gen.deck
  end

  def test_does_not_require_letters
    refute Generators::ExternalConsonantSandhiSplit.requires_letters?
  end

  def test_no_audio
    assert_empty gen.audio_files(gen.build)
  end
end
