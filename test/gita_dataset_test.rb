# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/gita_dataset"

class GitaDatasetTest < Minitest::Test
  def verses
    [{ "id" => 1, "chapter_number" => 1, "verse_number" => 1,
       "text" => "धर्म", "transliteration" => "dharma", "word_meanings" => "धर्म—dharma" }]
  end

  def translations
    [
      { "verse_id" => 1, "authorName" => "Swami Gambirananda", "lang" => "english", "description" => "Literal text" },
      { "verse_id" => 1, "authorName" => "Swami Sivananda", "lang" => "english", "description" => "Devotional text" },
      { "verse_id" => 1, "authorName" => "Swami Ramsukhdas", "lang" => "hindi", "description" => "हिंदी" }
    ]
  end

  def record
    GitaDataset.build(verses, translations,
                      literal_author: "Swami Gambirananda",
                      devotional_author: "Swami Sivananda").first
  end

  def test_basic_fields
    assert_equal 1, record["chapter"]
    assert_equal 1, record["verse"]
    assert_equal "धर्म", record["devanagari"]
    assert_equal "dharma", record["transliteration"]
    assert_equal "धर्म—dharma", record["word_meanings"]
  end

  def test_selects_named_english_translations
    assert_equal "Literal text", record["translations"]["literal"]
    assert_equal "Devotional text", record["translations"]["devotional"]
  end

  def test_audio_filename
    assert_equal "gita_1_1.mp3", record["audio_file"]
  end
end
