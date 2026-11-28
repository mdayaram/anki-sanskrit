# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/case_analysis"
require_relative "../lib/case_functions"

# Rendering of the Case Analysis deck: the front is the English sentence and
# nothing else; the back is the Sanskrit sentence plus, for every declined word,
# its class label (mAp) and the reason it takes that case. Handout use numbers
# (2c, 1d …) and Sanskrit case names are never shown.
class CaseAnalysisTest < Minitest::Test
  def gen       = @gen ||= Generators::CaseAnalysis.new([], {})
  def sentences = @sentences ||= gen.build
  def cards     = @cards ||= sentences.map { |s| [s, *gen.card(s)] }

  def test_deck_key_and_file
    assert_equal "#{Anki::DECLENSIONS_PARENT}::2. Case Analysis", gen.deck
    assert_equal "sanskrit_declensions_2_case_analysis_anki.txt", Generators::CaseAnalysis::OUTPUT_TXT
    refute Generators::CaseAnalysis.requires_letters?
    cards.each { |s, key, _, _| assert_equal "case_analysis:#{s['id']}", key }
  end

  def test_front_is_english_only
    cards.each do |s, _, front, _|
      assert_includes front, s["english"]
      refute_match(/[ऀ-ॿ]/, front, s["id"])
      s["words"].each { |w| refute_includes front, label(w), s["id"] }
    end
  end

  def test_back_shows_every_word_label_and_reason
    cards.each do |s, _, _, back|
      assert_includes back, s["devanagari"]
      assert_includes back, s["iast"]
      s["words"].each do |w|
        assert_includes back, w["devanagari"], s["id"]
        assert_includes back, "<b>#{label(w)}</b>", s["id"]
        assert_includes back, w["why"], s["id"]
      end
    end
  end

  def test_back_hides_handout_numbers_and_sanskrit_case_names
    sanskrit_names = CaseFunctions.load["cases"].map { |c| c["devanagari"] }
    cards.each do |s, _, _, back|
      refute_match(/\b[1-8][a-j]\b/, back, s["id"])
      sanskrit_names.each { |n| refute_includes back, n, s["id"] }
    end
  end

  def test_alternative_uses_its_own_case
    s, _, _, back = cards.find { |c, *| c["id"] == "laksmana-rama-padbhyam-vanam" }
    promise = s["words"].find { |w| w["english"] == "promise" }
    assert_includes back, "or <b>fGs</b> — #{promise['alternatives'][0]['why']}"
  end

  def test_beyond_handout_note
    _, _, _, back = cards.find { |c, *| c["id"] == "rama-caturdasa-varsani" }
    assert_includes back, "(beyond the handout) How long the action lasts."
  end

  private

  def label(w) = CaseAnalysis.label(w["gender"], w["case"], w["number"])
end
