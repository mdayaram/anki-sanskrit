# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/gita_verses"

class GitaVersesTest < Minitest::Test
  def entry
    {
      "chapter"         => 1,
      "verse"           => 1,
      "devanagari"      => "धृतराष्ट्र उवाच\nधर्मक्षेत्रे कुरुक्षेत्रे",
      "transliteration" => "dhṛitarāśhtra uvācha\ndharma-kṣhetre",
      "translations"    => { "literal" => "Literal line", "devotional" => "Devotional line" },
      "audio_file"      => "gita_1_1.mp3"
    }
  end

  def gen = Generators::GitaVerses.new([], {})

  def test_deck_is_gita
    assert_equal Anki::GITA_DECK, gen.deck
  end

  def test_audio_dir_is_gita_audio
    assert_equal Paths::GITA_AUDIO_DIR, gen.audio_dir
  end

  def test_does_not_require_letters
    refute Generators::GitaVerses.requires_letters?
  end

  def test_card_key_and_front
    key, front, = gen.card(entry)
    assert_equal "gita_verse:1.1", key
    refute_includes front, "\n"
    assert_includes front, "<br>"
    assert_includes front, "धर्मक्षेत्रे"
    refute_includes front, "style="
  end

  def test_card_back_sections
    _key, _front, back = gen.card(entry)
    assert_includes back, "IAST"
    assert_includes back, "Literal line"
    assert_includes back, "Devotional line"
    assert_includes back, "[sound:gita_1_1.mp3]"
    refute_includes back, "\n"
    refute_includes back, "style="
  end

  def test_audio_files
    assert_equal ["gita_1_1.mp3"], gen.audio_files([entry])
  end
end
