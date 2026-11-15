# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/case_names"
require_relative "../lib/generators/case_uses"
require_relative "../lib/generators/case_examples"

# Rendering checks on the three case-function generators. The card DATA is
# validated by test/case_functions_data_test.rb.
class CaseFunctionsTest < Minitest::Test
  GENERATORS = [Generators::CaseNames, Generators::CaseUses, Generators::CaseExamples].freeze

  def data = @data ||= CaseFunctions.load
  def cards_for(klass)
    gen = klass.new([], {})
    gen.build.map { |e| gen.card(e) }
  end

  def test_three_separate_decks_under_one_parent
    decks = GENERATORS.map { |g| g.new([], {}).deck }
    assert_equal decks.size, decks.uniq.size
    decks.each { |d| assert d.start_with?("#{Anki::CASE_FUNCTIONS_PARENT}::"), d }
    GENERATORS.each { |g| refute g.requires_letters? }
  end

  def test_card_counts
    assert_equal 2 * data["cases"].size, cards_for(Generators::CaseNames).size
    assert_equal data["uses"].size, cards_for(Generators::CaseUses).size
    assert_equal data["examples"].size, cards_for(Generators::CaseExamples).size
  end

  # Each deck's keys are unique, and no key is shared across the three decks
  # (all use #guid column:1, so a shared key would merge notes on import).
  def test_keys_unique_across_all_three_decks
    keys = GENERATORS.flat_map { |g| cards_for(g).map(&:first) }
    assert_equal keys.size, keys.uniq.size
    assert cards_for(Generators::CaseNames).all? { |k, _, _| k.start_with?("case_name:") }
    assert cards_for(Generators::CaseUses).all? { |k, _, _| k.start_with?("case_use:") }
    assert cards_for(Generators::CaseExamples).all? { |k, _, _| k.start_with?("case_example:") }
  end

  def test_name_cards_do_not_spoil_their_answer
    gen = Generators::CaseNames.new([], {})
    data["cases"].each do |c|
      _k, front, back = gen.card([:sanskrit, c])
      assert_includes front, c["devanagari"]
      refute_includes front, c["english"]
      assert_includes back, c["english"]

      _k, front, back = gen.card([:english, c])
      assert_includes front, c["english"]
      refute_includes front, c["devanagari"]
      assert_includes back, c["devanagari"]
    end
  end

  def test_vocative_card_explains_it_is_not_numbered
    gen = Generators::CaseNames.new([], {})
    vocative = data["cases"].find { |c| c["id"] == "vocative" }
    _k, _f, back = gen.card([:sanskrit, vocative])
    assert_includes back, "Pāṇini"
    refute_includes back, "case 8"
  end

  def test_use_cards_hide_the_case_and_show_examples
    gen = Generators::CaseUses.new([], {})
    gen.build.each do |entry|
      _k, front, back = gen.card(entry)
      refute_includes front, entry["case"]["english"]
      assert_includes back, entry["case"]["english"]
      assert_includes back, entry["use"]["id"]
      entry["examples"].each { |e| assert_includes back, "<b>#{e['target']['devanagari']}</b>" }
    end
  end

  def test_example_cards_bold_the_target_and_hide_the_case
    gen = Generators::CaseExamples.new([], {})
    gen.build.each do |entry|
      e = entry["example"]
      _k, front, back = gen.card(entry)
      assert_includes front, "<b>#{e['target']['devanagari']}</b>"
      assert_includes front, "<u>"
      refute_includes front, entry["case"]["english"]
      refute_includes front, entry["use"]["description"]
      assert_includes back, CaseFunctions.case_label(entry["case"])
      assert_includes back, e["iast"]
      assert_includes back, e["target"]["stem_devanagari"]
    end
  end

  def test_bold_target_marks_whole_words_only
    assert_equal "<b>राम</b> रामं", CaseFunctions.bold_target("राम रामं", "राम")
    assert_equal "Rāma goes to the <u>forest</u>.", CaseFunctions.english_html("Rāma goes to the [forest].")
  end

  def test_no_inline_styles
    GENERATORS.each { |g| cards_for(g).each { |_k, f, b| refute_match(/style=/, f + b) } }
  end
end
