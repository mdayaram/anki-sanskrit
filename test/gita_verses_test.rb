# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/gita_verses"

class GitaVersesTest < Minitest::Test
  def entry
    {
      "chapter"         => 1,
      "verse_label"     => "4-6",
      "verses"          => [4, 5, 6],
      "devanagari"      => "अत्र शूरा\n\nधृष्टकेतु\n\nयुधामन्यु",
      "transliteration" => "atra śhūrā\ndhṛiṣhṭaketu\nyudhāmanyu",
      "translations"    => { "literal" => "Here are heroes...", "devotional" => "Behold the warriors..." },
      "word_meanings"   => ["wm4", "wm5", "wm6"],
      "audio_file"      => "gita_1_4-6.mp3"
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

  def test_card_key_uses_verse_label
    key, front, = gen.card(entry)
    assert_equal "gita_verse:1.4-6", key
    refute_includes front, "\n"
    assert_includes front, "<br>"
    assert_includes front, "अत्र शूरा"
    refute_includes front, "style="
  end

  def test_card_back_sections
    _key, _front, back = gen.card(entry)
    assert_includes back, "IAST"
    assert_includes back, "Here are heroes..."
    assert_includes back, "Behold the warriors..."
    assert_includes back, "[sound:gita_1_4-6.mp3]"
    refute_includes back, "\n"
    refute_includes back, "style="
  end

  def test_audio_files
    assert_equal ["gita_1_4-6.mp3"], gen.audio_files([entry])
  end
end
