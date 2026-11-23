# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/case_names"

# Rendering checks on the cases deck (the first declension subdeck). The card
# DATA is validated by test/case_functions_data_test.rb (names, uses) and
# test/declensions_data_test.rb (endings).
class CaseFunctionsTest < Minitest::Test
  def data = @data ||= CaseFunctions.load
  def declensions = @declensions ||= Declensions.load
  def gen = @gen ||= Generators::CaseNames.new([], {})
  def cards = @cards ||= gen.build.map { |e| [e, gen.card(e)] }

  def test_first_subdeck_of_the_declensions
    assert_equal "#{Anki::DECLENSIONS_PARENT}::1. Cases", gen.deck
    refute Generators::CaseNames.requires_letters?
  end

  def test_one_card_per_case_english_to_sanskrit_only
    assert_equal data["cases"].size, cards.size
    keys = cards.map { |_e, (k, _, _)| k }
    assert_equal keys.size, keys.uniq.size
    assert keys.all? { |k| k.start_with?("case_name:english:") }
  end

  def test_name_cards_do_not_spoil_their_answer
    cards.each do |entry, (_k, front, back)|
      c = entry["case"]
      assert_includes front, c["english"]
      refute_includes front, c["devanagari"]
      assert_includes back, c["devanagari"]
    end
  end

  # Every handout use appears on exactly its own case's card, numbered, and
  # never on the front.
  def test_name_cards_list_every_use_of_their_case
    shown = cards.flat_map do |entry, (_k, front, back)|
      entry["uses"].each do |u|
        assert_equal entry["case"]["id"], u["case"]
        assert_includes back, "<b>#{u['id']}</b> #{u['description']}"
        refute_includes front, u["description"]
      end
      entry["uses"].map { |u| u["id"] }
    end
    assert_equal data["uses"].map { |u| u["id"] }.sort, shown.sort
  end

  # The back carries the case's own endings row (and the neuter's own row where
  # it has one), never another case's, and the front never shows an ending.
  def test_name_cards_show_their_own_endings
    cards.each do |entry, (_k, front, back)|
      kase = entry["case"]["id"]
      genders = Declensions::NEUTER_CASES.include?(kase) ? %w[m n] : %w[m]
      genders.each do |g|
        row = Declensions::NUMBERS.map do |n|
          e = Declensions.ending(declensions, kase, n, g)
          "<td><b>#{e['devanagari'].empty? ? '—' : Declensions.ending_html(e)}</b></td>"
        end.join
        assert_includes back, row, "#{kase} #{g}"
      end
      assert_equal Declensions::NEUTER_CASES.include?(kase), back.include?("neuter</small>"), kase
      refute_includes front, "<table>"
    end
  end

  def test_instrumental_endings_row
    _e, (_k, _f, back) = cards.find { |e, _| e["case"]["id"] == "instrumental" }
    assert_includes back, "<td><small>all genders</small></td><td><b>आ</b></td><td><b>भ्याम्</b></td><td><b>भिः</b></td>"
  end

  def test_nominative_explains_the_visarga_ending
    _e, (_k, _f, back) = cards.find { |e, _| e["case"]["id"] == "nominative" }
    assert_includes back, "<b>◌ः</b>"
    assert_includes back, Declensions.mf_ending(declensions, "nominative", "singular")["note"]
  end

  def test_vocative_card_explains_it_is_not_numbered
    _e, (_k, _f, back) = cards.find { |e, _| e["case"]["id"] == "vocative" }
    assert_includes back, "Pāṇini"
    refute_includes back, "case 8"
  end

  def test_no_inline_styles
    cards.each { |_e, (_k, f, b)| refute_match(/style=/, f + b) }
  end
end
