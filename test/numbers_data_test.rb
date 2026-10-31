# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/numbers"
require_relative "../lib/iast_devanagari"

# Data-integrity check on data/numbers.json (the committed source of truth).
# Nothing in the deck is derived, so this is the only validation: every stored
# Devanagari must read as exactly its stored IAST, digits must agree with the
# values they show, and the sections must cover what the deck promises.
class NumbersDataTest < Minitest::Test
  TENS = [20, 30, 40, 50, 60, 70, 80, 90].freeze

  def data = @data ||= Numbers.load
  def cardinals = data["cardinals"]
  def cardinal(value) = cardinals.find { |c| c["value"] == value }

  # Every (label, iast, devanagari) triple in the file.
  def pairs
    out = []
    data["digits"].each { |d| out << ["digit #{d['value']}", d["iast"], d["devanagari"]] }
    cardinals.each do |c|
      label = "cardinal #{c['value']}"
      out << [label, c["iast"], c["devanagari"]]
      out << ["#{label} stem", c["stem"]["iast"], c["stem"]["devanagari"]] if c["stem"]
      (c["gender_forms"] || []).each { |f| out << ["#{label} #{f['gender']}", f["iast"], f["devanagari"]] }
      (c["alternates"] || []).each { |a| out << ["#{label} alternate", a["iast"], a["devanagari"]] }
    end
    data["ordinals"].each do |o|
      out << ["ordinal #{o['value']}", o["iast"], o["devanagari"]]
      out << ["ordinal #{o['value']} colophon", o["colophon_iast"], o["colophon_devanagari"]]
    end
    data["rules"].each do |r|
      r["examples"].each { |e| out << ["rule #{r['id']} example #{e['value']}", e["iast"], e["devanagari"]] }
    end
    out
  end

  def test_every_devanagari_reads_as_its_iast
    pairs.each do |label, iast, dev|
      assert IastDevanagari.valid_pair?(iast, dev),
             "#{label}: #{iast.inspect} vs #{dev} which reads as #{IastDevanagari.to_iast(dev).inspect}"
    end
  end

  def test_digits_are_zero_to_nine_in_order
    assert_equal (0..9).to_a, data["digits"].map { |d| d["value"] }
    data["digits"].each do |d|
      assert_equal Numbers.to_devanagari_digits(d["value"]), d["digit"], "digit glyph for #{d['value']}"
    end
  end

  def test_digit_words_match_the_cardinals
    data["digits"].drop(1).each do |d|
      assert_equal cardinal(d["value"])["iast"], d["iast"], "digit #{d['value']} names the same word as its cardinal"
    end
  end

  def test_numerals_read_as_their_stated_value
    data["numerals"].each do |n|
      assert_equal n["reading"], Numbers.to_western_digits(n["devanagari"]).delete("॥"),
                   "#{n['devanagari']} should read #{n['reading']}"
    end
  end

  def test_cardinal_values_are_unique
    values = cardinals.map { |c| c["value"] }
    assert_equal values.size, values.uniq.size
  end

  def test_core_covers_the_building_blocks
    core = cardinals.select { |c| c["group"] == "core" }.map { |c| c["value"] }
    assert_equal [*1..10, *TENS, 100, 1000], core
  end

  def test_every_teen_is_carded
    assert_equal (11..19).to_a, cardinals.select { |c| c["group"] == "teens" }.map { |c| c["value"] }
  end

  def test_only_one_to_four_change_with_gender
    with_forms = cardinals.select { |c| c["gender_forms"] }.map { |c| c["value"] }
    assert_equal [1, 2, 3, 4], with_forms
    cardinals.select { |c| c["gender_forms"] }.each do |c|
      assert_equal %w[m f n], c["gender_forms"].map { |f| f["gender"] }
    end
  end

  def test_compounds_explain_their_parts
    cardinals.reject { |c| c["group"] == "core" }.each do |c|
      assert c["parts"], "#{c['value']} needs a parts breakdown"
      assert c["explanation"], "#{c['value']} needs an explanation"
    end
  end

  def test_ordinals_are_the_gitas_eighteen_chapters
    assert_equal (1..18).to_a, data["ordinals"].map { |o| o["value"] }
  end

  # The colophon form is the ordinal + "-o 'dhyāyaḥ" (visarga sandhi: -aḥ + a- ->
  # -o ऽ), so it must be built from the card's own ordinal stem.
  def test_colophon_is_built_from_the_ordinal
    data["ordinals"].each do |o|
      assert_equal "#{o['iast'].delete_suffix('a')}o 'dhyāyaḥ", o["colophon_iast"]
      assert_equal "#{o['devanagari']}ोऽध्यायः", o["colophon_devanagari"]
    end
  end

  # 11th-19th are the same word as the cardinal.
  def test_teen_ordinals_match_the_teen_cardinals
    data["ordinals"].select { |o| o["value"] > 10 }.each do |o|
      assert_equal cardinal(o["value"])["iast"], o["iast"]
    end
  end

  def test_rule_examples_agree_with_carded_forms
    data["rules"].each do |r|
      r["examples"].each do |e|
        c = cardinal(e["value"]) or next
        known = [c["iast"], *(c["alternates"] || []).map { |a| a["iast"] }]
        assert_includes known, e["iast"], "rule #{r['id']} example #{e['value']}"
      end
    end
  end
end
