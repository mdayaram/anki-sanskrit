# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/sandhi_deck"
require_relative "../lib/sandhi"
require_relative "../lib/iast_devanagari"

# Data-integrity check on data/sandhi.json (the committed source of truth). The
# sandhi engine and valid_pair? that used to run at generation time now validate
# every stored entry here: the curated combined form matches the rule, the type
# label matches the junction (Sandhi.join raises otherwise), and each Devanagari
# field is a valid spelling of its IAST.
class SandhiDeckTest < Minitest::Test
  def entries
    @entries ||= SandhiDeck.load
  end

  def test_engine_reproduces_every_stored_derivation
    entries.each do |e|
      r = Sandhi.join(e["word1_iast"], e["word2_iast"], e["type"].to_sym)
      label = "#{e['word1_iast']} + #{e['word2_iast']} (#{e['type']})"
      assert_equal e["combined_iast"],     r[:combined],        "combined_iast for #{label}"
      assert_equal e["sandhi_name"],       r[:name],            "sandhi_name for #{label}"
      assert_equal e["sandhi_devanagari"], r[:devanagari_name], "sandhi_devanagari for #{label}"
      assert_equal e["explanation"],       r[:explanation],     "explanation for #{label}"
    end
  end

  def test_every_devanagari_field_is_a_valid_spelling
    entries.each do |e|
      %w[word1 word2 combined].each do |part|
        iast = e["#{part}_iast"]
        dev  = e["#{part}_devanagari"]
        assert IastDevanagari.valid_pair?(iast, dev),
               "#{part}: #{iast} / #{dev} reads as #{IastDevanagari.to_iast(dev)}"
      end
    end
  end

  def test_context_bound_rules_are_consistent
    entries.select { |e| e["type"] == "ayadi" }.each    { |e| assert_equal "internal", e["context"] }
    entries.select { |e| e["type"] == "avagraha" }.each { |e| assert_equal "external", e["context"] }
  end
end
