# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/mantras"

class MantrasTest < Minitest::Test
  def entry
    {
      "id" => "example",
      "name" => "Example Mantra",
      "source" => "Somewhere 1.2.3",
      "devanagari" => "ॐ नमः\nशिवाय",
      "transliteration" => "oṃ namaḥ\nśivāya",
      "translations" => [
        { "label" => "Literal", "text" => "Oṃ, homage to Śiva." },
        { "label" => "Someone (1896)", "text" => "Salutation unto Siva." }
      ],
      "word_meanings" => [
        { "devanagari" => "नमः", "iast" => "namaḥ", "meaning" => "homage" }
      ],
      "notes" => "A five-syllable mantra.",
      "audio_file" => "example.mp3",
      "audio_source" => { "url" => "https://example.invalid/x.mp3", "credit" => "Someone" }
    }
  end

  def gen = Generators::Mantras.new([], {})

  def test_deck_is_mantras
    assert_equal Anki::MANTRAS_DECK, gen.deck
  end

  def test_does_not_require_letters
    refute Generators::Mantras.requires_letters?
  end

  def test_audio_comes_from_the_mantra_audio_dir
    assert_equal Paths::MANTRA_AUDIO_DIR, gen.audio_dir
  end

  def test_audio_files_are_the_referenced_clips
    assert_equal ["example.mp3"], gen.audio_files([entry])
  end

  def test_build_loads_the_committed_mantras
    data = gen.build
    refute_empty data
    gayatri = data.find { |m| m["id"] == "gayatri" }
    refute_nil gayatri
    assert_includes gayatri["devanagari"], "प्रचोदयात्"
    assert_equal "gayatri.mp3", gayatri["audio_file"]
  end

  def test_front_is_the_devanagari_only
    _key, front, _back = gen.card(entry)

    assert_includes front, "ॐ नमः<br>शिवाय" # newlines become <br> so the lines survive the TSV
    refute_includes front, "\n"
    refute_includes front, "style="
    # The front is the prompt: naming the mantra or glossing it would give it away.
    refute_includes front, "Example Mantra"
    refute_includes front, "homage"
  end

  def test_back_omits_the_full_line_transliteration
    # The word-by-word gloss already gives every word's IAST, so a full IAST of
    # the whole mantra only repeats it and crowds the card. The transliteration
    # stays in data/mantras.json regardless: it is what validates the Devanagari
    # spelling (see test/mantras_data_test.rb).
    _key, _front, back = gen.card(entry)
    refute_includes back, "oṃ namaḥ<br>śivāya"
    refute_includes back, "IAST"
  end

  def test_back_has_the_name_translations_gloss_and_audio
    key, _front, back = gen.card(entry)

    assert_equal "mantra:example", key
    assert_includes back, "Example Mantra"
    assert_includes back, "Somewhere 1.2.3"
    assert_includes back, "Literal"
    assert_includes back, "Oṃ, homage to Śiva."
    assert_includes back, "Someone (1896)"          # every translation is rendered, whatever it is called
    assert_includes back, "Salutation unto Siva."
    assert_includes back, "नमः"                      # word-by-word gloss
    assert_includes back, "homage"
    assert_includes back, "A five-syllable mantra." # notes
    assert_includes back, "[sound:example.mp3]"
    refute_includes back, "\n"
    refute_includes back, "style="
  end

  def test_notes_are_optional
    _key, _front, back = gen.card(entry.merge("notes" => ""))
    refute_includes back, "<small></small>"
  end
end
