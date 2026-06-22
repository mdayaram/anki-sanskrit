# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/vedanta"

class VedantaTest < Minitest::Test
  def entry
    { "iast" => "mokṣaḥ", "devanagari" => "मोक्षः", "definition" => "Liberation; release." }
  end

  def gen = Generators::Vedanta.new([], {})

  def test_deck_is_vedanta
    assert_equal Anki::VEDANTA_DECK, gen.deck
  end

  def test_does_not_require_letters
    refute Generators::Vedanta.requires_letters?
  end

  def test_no_audio
    assert_empty gen.audio_files([entry])
  end

  def test_card_key_front_back
    key, front, back = gen.card(entry)
    assert_equal "vedanta:mokṣaḥ", key
    assert_includes front, "मोक्षः"
    refute_includes front, "style="
    assert_includes back, "mokṣaḥ"
    assert_includes back, "Liberation; release."
    refute_includes back, "\n"
  end
end
