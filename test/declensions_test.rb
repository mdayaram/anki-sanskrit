# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/basic_endings"
require_relative "../lib/generators/shared_endings"
require_relative "../lib/generators/t_nouns"

# Rendering checks on the three declension generators. The card DATA is
# validated by test/declensions_data_test.rb.
class DeclensionsTest < Minitest::Test
  GENERATORS = [Generators::BasicEndings, Generators::SharedEndings, Generators::TNouns].freeze

  def data = @data ||= Declensions.load
  def cards_for(klass)
    gen = klass.new([], {})
    gen.build.map { |e| gen.card(e) }
  end

  def test_three_separate_decks_under_one_parent
    decks = GENERATORS.map { |g| g.new([], {}).deck }
    assert_equal decks.size, decks.uniq.size
    decks.each { |d| assert d.start_with?("#{Anki::DECLENSIONS_PARENT}::"), d }
    assert_equal decks.sort, decks, "subdecks sort in learning order"
    GENERATORS.each { |g| refute g.requires_letters? }
  end

  # 21 masculine/feminine cells + 1 vocative + 3 neuter; one card per distinct
  # ending (empty neuter ending excluded); every form of every noun.
  def test_card_counts
    assert_equal 25, cards_for(Generators::BasicEndings).size
    distinct = (data["endings"] + data["neuter_endings"]).map { |e| e["devanagari"] }.reject(&:empty?).uniq
    assert_equal distinct.size, cards_for(Generators::SharedEndings).size
    assert_equal data["nouns"].sum { |n| n["forms"].size }, cards_for(Generators::TNouns).size
  end

  def test_keys_unique_across_all_three_decks
    keys = GENERATORS.flat_map { |g| cards_for(g).map(&:first) }
    assert_equal keys.size, keys.uniq.size
    assert cards_for(Generators::BasicEndings).all? { |k, _, _| k.start_with?("basic_ending:") }
    assert cards_for(Generators::SharedEndings).all? { |k, _, _| k.start_with?("shared_ending:") }
    assert cards_for(Generators::TNouns).all? { |k, _, _| k.start_with?("t_noun:") }
  end

  def test_ending_cards_hide_the_ending_and_show_the_row
    gen = Generators::BasicEndings.new([], {})
    gen.build.select { |e| e["kind"] == "mf" }.each do |entry|
      ending = Declensions.mf_ending(data, entry["case"], entry["number"])
      _k, front, back = gen.card(entry)
      refute_includes front, Declensions.ending_html(ending)
      assert_includes back, "<b>#{Declensions.ending_html(ending)}</b>"
      assert_includes back, "मरुत्"
    end
  end

  def test_the_three_bhyam_cells_name_each_other
    _k, _f, back = cards_for(Generators::BasicEndings).find { |k, _, _| k == "basic_ending:mf:instrumental:dual" }
    assert_includes back, "dative dual, ablative dual"
  end

  def test_shared_ending_cards_list_every_cell
    gen = Generators::SharedEndings.new([], {})
    ah = gen.build.find { |e| e["ending"]["iast"] == "aḥ" }
    _k, front, back = gen.card(ah)
    refute_includes front, "nominative"
    ["nominative plural (masc./fem.)", "accusative plural (masc./fem.)", "ablative singular", "genitive singular"].each do |cell|
      assert_includes back, cell
    end
    assert_includes back, "vocative plural"
  end

  def test_locative_singular_i_also_marks_the_neuter_plural
    gen = Generators::SharedEndings.new([], {})
    i = gen.build.find { |e| e["ending"]["iast"] == "i" }
    _k, _f, back = gen.card(i)
    assert_includes back, "locative singular"
    assert_includes back, "nominative plural (neuter)"
    assert_includes back, "जगन्ति"
  end

  # The front names the stem and the cell but never the form — except where the
  # form IS the stem (मरुत् nominative singular), which is the point of that card.
  def test_noun_cards_hide_the_form
    gen = Generators::TNouns.new([], {})
    gen.build.each do |entry|
      form = entry["form"]["devanagari"]
      _k, front, back = gen.card(entry)
      assert_includes front, entry["noun"]["devanagari"]
      refute_includes front, form unless form == entry["noun"]["devanagari"]
      assert_includes back, "<b>#{form}</b>"
      assert_includes back, entry["form"]["iast"]
    end
  end

  def test_noun_cards_explain_sandhi_and_name_identical_forms
    cards = cards_for(Generators::TNouns).to_h { |k, f, b| [k, [f, b]] }
    _f, back = cards.fetch("t_noun:marut:instrumental:plural")
    assert_includes back, "मरुत् + भिः → मरुद्भिः"
    assert_includes back, data["sandhi"]["voicing"]

    _f, back = cards.fetch("t_noun:jagat:nominative:plural")
    assert_includes back, data["sandhi"]["num"]
    assert_includes back, "accusative plural, vocative plural"
  end

  def test_no_inline_styles
    GENERATORS.each { |g| cards_for(g).each { |_k, f, b| refute_match(/style=/, f + b) } }
  end
end
