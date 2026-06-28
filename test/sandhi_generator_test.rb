# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/sandhi"

class SandhiGeneratorTest < Minitest::Test
  def gen = Generators::Sandhi.new([], {})

  def test_deck_is_sandhi
    assert_equal Anki::SANDHI_DECK, gen.deck
  end

  def test_does_not_require_letters
    refute Generators::Sandhi.requires_letters?
  end

  def test_no_audio
    assert_empty gen.audio_files(gen.build)
  end

  def test_build_computes_every_pair
    data = gen.build
    refute_empty data
    entry = data.find { |e| e["word1_iast"] == "deva" && e["word2_iast"] == "indra" }
    refute_nil entry
    assert_equal "guna", entry["type"]
    assert_equal "devendra", entry["combined_iast"]
    assert_equal "देवेन्द्र", entry["combined_devanagari"]
    assert_equal "देव", entry["word1_devanagari"]
    assert_equal "इन्द्र", entry["word2_devanagari"]
    assert_equal "compound", entry["context"] # devendra is a samāsa, not two free words
  end

  def test_context_matches_the_sandhi_kind
    # The deck spans three contexts; the two context-bound rules must line up:
    # ayādi's ay/av forms are internal/derivational, avagraha is between words.
    data = gen.build
    data.select { |e| e["type"] == "ayadi" }.each { |e| assert_equal "internal", e["context"] }
    data.select { |e| e["type"] == "avagraha" }.each { |e| assert_equal "external", e["context"] }
  end

  def test_card_front_is_two_devanagari_words
    entry = gen.build.find { |e| e["combined_iast"] == "devendra" }
    key, front, back = gen.card(entry)

    assert_equal "sandhi:guna:deva+indra", key
    assert_includes front, "देव इन्द्र"
    refute_includes front, "style="

    assert_includes back, "देवेन्द्र"            # combined glyph
    assert_includes back, "deva + indra → devendra" # IAST line
    assert_includes back, "Guṇa"                  # which sandhi
    assert_includes back, "गुण"
    assert_includes back, "guṇa vowel"            # rule explanation
    assert_includes back, "compound"              # context label
    refute_includes back, "style="
  end

  def test_all_pairs_have_valid_sandhi
    # build must not raise — every curated pair's label matches its junction.
    assert(gen.build.all? { |e| e["combined_iast"].is_a?(String) })
  end
end
