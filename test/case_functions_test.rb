# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/case_names"
require_relative "../lib/generators/case_examples"

# Rendering checks on the two case-function generators. The card DATA is
# validated by test/case_functions_data_test.rb.
class CaseFunctionsTest < Minitest::Test
  GENERATORS = [Generators::CaseNames, Generators::CaseExamples].freeze

  def data = @data ||= CaseFunctions.load
  def cards_for(klass)
    gen = klass.new([], {})
    gen.build.map { |e| gen.card(e) }
  end

  def test_separate_decks_under_one_parent
    decks = GENERATORS.map { |g| g.new([], {}).deck }
    assert_equal decks.size, decks.uniq.size
    decks.each { |d| assert d.start_with?("#{Anki::CASE_FUNCTIONS_PARENT}::"), d }
    GENERATORS.each { |g| refute g.requires_letters? }
  end

  def test_card_counts
    assert_equal data["cases"].size, cards_for(Generators::CaseNames).size
    assert_equal data["examples"].size, cards_for(Generators::CaseExamples).size
  end

  # Each deck's keys are unique, and no key is shared across the decks
  # (all use #guid column:1, so a shared key would merge notes on import).
  def test_keys_unique_across_decks
    keys = GENERATORS.flat_map { |g| cards_for(g).map(&:first) }
    assert_equal keys.size, keys.uniq.size
    assert cards_for(Generators::CaseNames).all? { |k, _, _| k.start_with?("case_name:") }
    assert cards_for(Generators::CaseExamples).all? { |k, _, _| k.start_with?("case_example:") }
  end

  def test_name_cards_do_not_spoil_their_answer
    gen = Generators::CaseNames.new([], {})
    gen.build.each do |entry|
      c = entry["case"]
      _k, front, back = gen.card(entry)
      assert_includes front, c["english"]
      refute_includes front, c["devanagari"]
      assert_includes back, c["devanagari"]
    end
  end

  # Only English -> Sanskrit is carded (the class works with the English names).
  def test_name_cards_are_english_to_sanskrit_only
    assert cards_for(Generators::CaseNames).all? { |k, _, _| k.start_with?("case_name:english:") }
  end

  # Every handout use appears on exactly its own case's card, numbered, and
  # never on the front.
  def test_name_cards_list_every_use_of_their_case
    gen = Generators::CaseNames.new([], {})
    shown = gen.build.flat_map do |entry|
      _k, front, back = gen.card(entry)
      entry["uses"].each do |u|
        assert_equal entry["case"]["id"], u["case"]
        assert_includes back, "<b>#{u['id']}</b> #{u['description']}"
        refute_includes front, u["description"]
      end
      entry["uses"].map { |u| u["id"] }
    end
    assert_equal data["uses"].map { |u| u["id"] }.sort, shown.sort
  end

  def test_vocative_card_explains_it_is_not_numbered
    gen = Generators::CaseNames.new([], {})
    vocative = gen.build.find { |e| e["case"]["id"] == "vocative" }
    _k, _f, back = gen.card(vocative)
    assert_includes back, "Pāṇini"
    refute_includes back, "case 8"
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
