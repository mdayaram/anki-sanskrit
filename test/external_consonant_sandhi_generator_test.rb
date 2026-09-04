# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/external_consonant_sandhi"

class ExternalConsonantSandhiGeneratorTest < Minitest::Test
  def gen = Generators::ExternalConsonantSandhi.new([], {})

  def find(iast) = gen.build.find { |e| e["combined"].first["iast"] == iast }

  def test_deck_is_external_consonant_sandhi
    assert_equal Anki::EXTERNAL_CONSONANT_SANDHI_DECK, gen.deck
    refute_includes gen.deck, "(" # "(...)" is reserved for a splitting deck
  end

  def test_does_not_require_letters
    refute Generators::ExternalConsonantSandhi.requires_letters?
  end

  def test_no_audio
    assert_empty gen.audio_files(gen.build)
  end

  def test_build_loads_every_record
    data = gen.build
    refute_empty data
    entry = find("vāgdevī")
    refute_nil entry
    assert_equal "hc_voicing", entry["type"]
    assert_equal 1, entry["rule_number"]
    assert_equal "वाक्", entry["word1_devanagari"]
    assert_equal "देवी", entry["word2_devanagari"]
  end

  def test_card_front_is_the_word_pair_and_back_is_the_joined_form
    key, front, back = gen.card(find("vāgdevī"))

    assert_equal "external_consonant_sandhi:hc_voicing:vāk+devī", key
    assert_includes front, "वाक् देवी"     # the two parts, space-separated
    refute_includes front, "वाग्देवी"       # the answer must not leak onto the front
    refute_includes front, "style="

    assert_includes back, "वाग्देवी"                  # joined, as the handout writes it
    assert_includes back, "vāk + devī → vāgdevī"      # IAST analysis line
    assert_includes back, "voiced consonant of its own class"
    refute_includes back, "style="
  end

  # word1's citation form is shown only where the padānta reduction changed it:
  # वाक् comes from वाच्, but तत् + च needs no such note.
  def test_underlying_form_is_shown_only_when_present
    _, with_underlying, = gen.card(find("vāgdevī"))
    assert_includes with_underlying, "वाक् ← वाच्"

    entry = find("tāṃstitikṣasva")
    assert_nil entry["word1_underlying_devanagari"]
    _, without_underlying, = gen.card(entry)
    refute_includes without_underlying, "←"
  end

  # A junction with several accepted outcomes shows all of them on the back.
  def test_multiple_accepted_outcomes_are_all_rendered
    entry = find("taddhi")
    assert_equal 2, entry["combined"].size

    _, _, back = gen.card(entry)
    assert_includes back, "तद्धि"
    assert_includes back, "तद् हि"
    assert_includes back, "taddhi / tad hi"
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
