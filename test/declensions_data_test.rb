# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/declensions"
require_relative "../lib/iast_devanagari"

# Data-integrity check on data/declensions.json, the committed source of truth
# for the declension decks. The endings must be exactly the Arsha Bodha "Basic
# Terminations" handout, and every noun form is RE-DERIVED here from its stem,
# the handout's ending for that cell and gender, and its sandhi tag — so a typo
# in a form, a wrong tag, or a wrong ending all fail. Every stored Devanagari
# must also read as exactly its stored IAST.
class DeclensionsDataTest < Minitest::Test
  # The handout's masculine/feminine table, row by row (case: sg, du, pl).
  HANDOUT = {
    "nominative" => %w[ḥ au aḥ], "accusative" => %w[am au aḥ],
    "instrumental" => %w[ā bhyām bhiḥ], "dative" => %w[e bhyām bhyaḥ],
    "ablative" => %w[aḥ bhyām bhyaḥ], "genitive" => %w[aḥ oḥ ām],
    "locative" => %w[i oḥ su], "vocative" => %w[ḥ au aḥ]
  }.freeze
  # The neuter's own nominative/accusative/vocative: − ई इ.
  HANDOUT_NEUTER = ["", "ī", "i"].freeze

  SANDHI_TAGS = %w[s_dropped no_ending voicing hard_su num].freeze

  def data  = @data ||= Declensions.load
  def nouns = data["nouns"]

  def test_endings_are_the_handout_table
    expected = HANDOUT.flat_map { |c, row| Declensions::NUMBERS.zip(row).map { |n, i| [c, n, i] } }
    assert_equal expected, data["endings"].map { |e| [e["case"], e["number"], e["iast"]] }
  end

  def test_neuter_endings_are_the_handout_row
    expected = Declensions::NEUTER_CASES.flat_map { |c| Declensions::NUMBERS.zip(HANDOUT_NEUTER).map { |n, i| [c, n, i] } }
    assert_equal expected, data["neuter_endings"].map { |e| [e["case"], e["number"], e["iast"]] }
  end

  def test_endings_read_as_their_iast
    (data["endings"] + data["neuter_endings"]).each do |e|
      next if e["iast"].empty? && e["devanagari"].empty?

      assert IastDevanagari.valid_pair?(e["iast"], e["devanagari"]), "#{e['case']} #{e['number']}: #{e['devanagari']}"
    end
  end

  def test_case_ids_match_the_case_functions_data
    assert_equal Declensions::CASES.sort, Declensions.case_names.keys.sort
  end

  def test_sandhi_texts_exist_for_every_tag
    assert_equal SANDHI_TAGS.sort, data["sandhi"].keys.sort
    data["sandhi"].each_value { |t| refute_empty t }
  end

  def test_nouns_are_complete_paradigms
    refute_empty nouns
    assert_equal nouns.size, nouns.map { |n| n["iast"] }.uniq.size
    nouns.each do |n|
      assert_includes Declensions::GENDERS.keys, n["gender"], n["iast"]
      refute_empty n["meaning"].to_s, n["iast"]
      refute_empty n["source"].to_s, n["iast"]
      assert n["iast"].end_with?("t"), "#{n['iast']} is not a त्-stem"
      assert IastDevanagari.valid_pair?(n["iast"], n["devanagari"]), n["iast"]
      assert_equal Declensions::CASES.product(Declensions::NUMBERS), n["forms"].map { |f| [f["case"], f["number"]] }, n["iast"]
    end
  end

  def test_every_gender_is_represented
    assert_equal %w[f m n], nouns.map { |n| n["gender"] }.uniq.sort
  end

  def test_forms_read_as_their_iast
    nouns.each do |n|
      n["forms"].each do |f|
        assert IastDevanagari.valid_pair?(f["iast"], f["devanagari"]),
               "#{n['iast']} #{f['case']} #{f['number']}: #{f['iast']} vs #{f['devanagari']} " \
               "(reads #{IastDevanagari.to_iast(f['devanagari'])})"
      end
    end
  end

  # stem + the handout ending for this cell and gender, through the tagged change.
  def test_every_form_is_its_stem_plus_its_ending
    nouns.each do |n|
      stem = n["iast"]
      n["forms"].each do |f|
        ending = Declensions.ending(data, f["case"], f["number"], n["gender"])["iast"]
        assert_equal expected_sandhi(n["gender"], f, ending).to_s, f["sandhi"].to_s, "#{stem} #{f['case']} #{f['number']} tag"
        expected =
          case f["sandhi"]
          when "s_dropped", "no_ending" then stem
          when "voicing" then "#{stem.chomp('t')}d#{ending}"
          when "num" then "#{stem.chomp('t')}nt#{ending}"
          else stem + ending
          end
        assert_equal expected, f["iast"], "#{stem} #{f['case']} #{f['number']}"
      end
    end
  end

  # Data is rendered straight into TSV: no tabs, markup or ASCII double quotes.
  def test_no_tabs_markup_or_ascii_quotes
    strings = []
    walk = lambda do |node|
      case node
      when Hash then node.each_value { |v| walk.call(v) }
      when Array then node.each { |v| walk.call(v) }
      when String then strings << node
      end
    end
    walk.call(data)
    strings.each do |s|
      refute_includes s, "\t"
      refute_includes s, '"', "ASCII quote in #{s.inspect}"
      refute_match(/<[a-z]/i, s)
    end
  end

  private

  # Which change a त्-stem undergoes with this ending.
  def expected_sandhi(gender, form, ending)
    neuter_cell = gender == "n" && Declensions::NEUTER_CASES.include?(form["case"])
    return "no_ending" if neuter_cell && ending.empty?
    return "num" if neuter_cell && form["number"] == "plural"
    return "s_dropped" if ending == "ḥ"
    return "voicing" if ending.start_with?("bh")
    return "hard_su" if ending == "su"

    nil
  end
end
