# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/case_functions"
require_relative "../lib/iast_devanagari"

# Data-integrity check on data/case_functions.json, the committed source of truth
# for the cases deck (names and uses) and for the example sentences, which no
# deck renders yet but are kept for a later one. Nothing is derived,
# so this is the only validation: the cases and uses must match the Arsha Bodha
# "Sanskrit Case Functions" handout's numbering, every example must point at a
# real use, and every stored Devanagari must read as exactly its stored IAST.
class CaseFunctionsDataTest < Minitest::Test
  CASE_IDS = %w[nominative accusative instrumental dative ablative genitive locative vocative].freeze

  # The handout's sub-use letters per case number (1a-1e, 2a-2d, ...).
  HANDOUT_USES = {
    1 => "a".."e", 2 => "a".."d", 3 => "a".."j", 4 => "a".."f",
    5 => "a".."e", 6 => "a".."e", 7 => "a".."d", 8 => "a".."a"
  }.freeze

  def data     = @data ||= CaseFunctions.load
  def cases    = data["cases"]
  def uses     = data["uses"]
  def examples = data["examples"]

  def test_eight_cases_in_handout_order
    assert_equal CASE_IDS, cases.map { |c| c["id"] }
    assert_equal (1..8).to_a, cases.map { |c| c["number"] }
    cases.each do |c|
      %w[english devanagari iast literal sense cue].each do |field|
        refute_empty c[field].to_s, "#{c['id']} missing #{field}"
      end
    end
  end

  def test_case_names_read_as_their_iast
    cases.each do |c|
      assert IastDevanagari.valid_pair?(c["iast"], c["devanagari"]),
             "#{c['id']}: #{c['iast']} vs #{c['devanagari']} (reads #{IastDevanagari.to_iast(c['devanagari'])})"
    end
  end

  # The uses are exactly the handout's numbered list, so a card's "2c" means the
  # same thing as the learner's handout.
  def test_uses_match_the_handout_numbering
    expected = HANDOUT_USES.flat_map { |n, letters| letters.map { |l| "#{n}#{l}" } }
    assert_equal expected, uses.map { |u| u["id"] }
  end

  def test_each_use_belongs_to_the_case_its_number_names
    uses.each do |u|
      number = u["id"].to_i
      assert_equal CASE_IDS[number - 1], u["case"], "use #{u['id']}"
      refute_empty u["description"].to_s, "use #{u['id']} description"
      refute_empty u["question"].to_s, "use #{u['id']} question"
    end
  end

  # A use card's front must not name the case it is asking for.
  def test_use_questions_do_not_name_their_case
    uses.each do |u|
      c = cases.find { |x| x["id"] == u["case"] }
      [c["english"], c["devanagari"]].each do |name|
        refute_includes u["question"].downcase, name.downcase, "use #{u['id']} question names its case"
      end
    end
  end

  def test_example_ids_unique_and_uses_exist
    ids = examples.map { |e| e["id"] }
    assert_equal ids.size, ids.uniq.size, "duplicate example ids"
    use_ids = uses.map { |u| u["id"] }
    examples.each { |e| assert_includes use_ids, e["use"], "example #{e['id']}" }
  end

  def test_every_case_has_an_example
    covered = examples.map { |e| CaseFunctions.use(data, e["use"])["case"] }.uniq
    assert_equal CASE_IDS.sort, covered.sort
  end

  def test_no_duplicate_example_sentences
    sentences = examples.map { |e| e["devanagari"] }
    assert_equal sentences.size, sentences.uniq.size
  end

  def test_every_devanagari_reads_as_its_iast
    examples.each do |e|
      t = e["target"]
      [
        ["sentence", e["iast"], e["devanagari"]],
        ["target", t["iast"], t["devanagari"]],
        ["stem", t["stem_iast"], t["stem_devanagari"]]
      ].each do |label, iast, dev|
        assert IastDevanagari.valid_pair?(iast, dev),
               "#{e['id']} #{label}: #{iast.inspect} vs #{dev} (reads #{IastDevanagari.to_iast(dev).inspect})"
      end
    end
  end

  # The bolded word must be exactly one word of the sentence, in both scripts, so
  # the generator can mark it and the IAST line agrees with the Devanagari.
  def test_target_is_exactly_one_word_of_the_sentence
    examples.each do |e|
      t = e["target"]
      assert_equal 1, e["devanagari"].split.count(t["devanagari"]), "#{e['id']}: target Devanagari"
      assert_equal 1, e["iast"].split.count(t["iast"]), "#{e['id']}: target IAST"
    end
  end

  def test_english_marks_exactly_one_target
    examples.each do |e|
      assert_equal 1, e["english"].scan(/\[[^\]]+\]/).size, "#{e['id']}: #{e['english']}"
    end
  end

  def test_target_grammar_fields
    examples.each do |e|
      t = e["target"]
      assert_includes %w[m f n], t["gender"], e["id"]
      assert_includes %w[singular dual plural], t["number"], e["id"]
      refute_empty t["meaning"].to_s, e["id"]
      refute_empty e["source"].to_s, e["id"]
    end
  end

  # Sandhi is broken in every example (as in the handout), so no target may end
  # in a sandhi-altered visarga: an -o or -aś for -aḥ would hide the ending.
  def test_sandhi_is_broken
    examples.each do |e|
      refute_match(/ऽ/, e["devanagari"], "#{e['id']}: avagraha means sandhi was applied")
    end
  end

  # Data is rendered straight into TSV, so no field may hold a tab, markup, or an
  # ASCII double quote (a field opening with " is read as a quoted TSV field;
  # quotes are curly, as in the sandhi decks' meanings).
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
end
