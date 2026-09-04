# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/internal_consonant_sandhi"

class InternalConsonantSandhiGeneratorTest < Minitest::Test
  def gen = Generators::InternalConsonantSandhi.new([], {})

  def find(iast) = gen.build.find { |e| e["combined"].first["iast"] == iast }

  def test_deck_is_internal_consonant_sandhi
    assert_equal Anki::INTERNAL_CONSONANT_SANDHI_DECK, gen.deck
    refute_includes gen.deck, "(" # "(...)" is reserved for a splitting deck
  end

  def test_does_not_require_letters
    refute Generators::InternalConsonantSandhi.requires_letters?
  end

  def test_no_audio
    assert_empty gen.audio_files(gen.build)
  end

  # The parts are morphemes, not free words, so the front joins them with "+"
  # rather than a space: वि सीदति would read as two words, which they are not.
  def test_card_front_joins_the_parts_with_a_plus
    key, front, back = gen.card(find("viṣīdati"))

    assert_equal "internal_consonant_sandhi:satva:vi+sīdati", key
    assert_includes front, "वि + सीदति"
    refute_includes front, "विषीदति" # the answer must not leak onto the front

    assert_includes back, "विषीदति"
    assert_includes back, "vi + sīdati → viṣīdati"
    assert_includes back, "ष्"
  end

  def test_every_record_renders
    rows = gen.build.map { |e| gen.card(e) }
    assert_equal gen.build.size, rows.size
    rows.each do |key, front, back|
      refute_empty key
      refute_empty front
      refute_empty back
      refute_includes front, "style="
      refute_includes back, "style="
    end
  end
end
