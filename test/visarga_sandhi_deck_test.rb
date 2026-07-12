# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/visarga_sandhi_deck"
require_relative "../lib/iast_devanagari"

# Data-integrity check on data/visarga_sandhi.json (the committed source of truth).
# There is no derivation engine for visarga sandhi (the outcomes are curated by
# hand from the sources), so the test's job is to guarantee the spelling of every
# stored form: each word and each combined alternative must have Devanagari that
# reads (IastDevanagari.to_iast) to exactly its stored IAST, and the structure must
# be well formed.
class VisargaSandhiDeckTest < Minitest::Test
  RULE_KEYS = %w[type word1_iast word1_devanagari word2_iast word2_devanagari
                 combined rule explanation].freeze

  def entries
    @entries ||= VisargaSandhiDeck.load
  end

  def test_not_empty
    refute_empty entries
  end

  def test_every_record_is_well_formed
    entries.each do |e|
      RULE_KEYS.each { |k| assert e.key?(k), "missing #{k} in #{e.inspect}" }
      assert_kind_of Array, e["combined"]
      refute_empty e["combined"], "no combined form for #{e['word1_iast']} + #{e['word2_iast']}"
      e["combined"].each do |c|
        assert c.key?("iast") && c.key?("devanagari"), "combined needs iast+devanagari: #{c.inspect}"
      end
    end
  end

  def test_every_devanagari_field_is_a_valid_spelling
    entries.each do |e|
      pairs = [["word1", e["word1_iast"], e["word1_devanagari"]],
               ["word2", e["word2_iast"], e["word2_devanagari"]]]
      e["combined"].each_with_index { |c, i| pairs << ["combined[#{i}]", c["iast"], c["devanagari"]] }

      pairs.each do |part, iast, dev|
        assert IastDevanagari.valid_pair?(iast, dev),
               "#{part} of #{e['word1_iast']}+#{e['word2_iast']}: #{iast.inspect} vs " \
               "#{dev} which reads as #{IastDevanagari.to_iast(dev).inspect}"
      end
    end
  end

  def test_keys_are_unique
    keys = entries.map { |e| "#{e['type']}:#{e['word1_iast']}+#{e['word2_iast']}" }
    assert_equal keys.size, keys.uniq.size, "duplicate card keys: #{keys.tally.select { |_, n| n > 1 }.keys}"
  end
end
