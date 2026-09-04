# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/internal_consonant_sandhi_deck"
require_relative "../lib/iast_devanagari"

# Data-integrity check on data/internal_consonant_sandhi.json — the handout's two
# internal rules (ṣatva, ṇatva). Same job as the external deck's test: guarantee
# that every stored Devanagari reads to exactly its stored IAST.
class InternalConsonantSandhiDeckTest < Minitest::Test
  RULE_KEYS = %w[type rule_number word1_iast word1_devanagari
                 word2_iast word2_devanagari combined rule explanation source].freeze

  TYPES_TO_RULE_NUMBER = { "satva" => 1, "natva" => 2 }.freeze

  def entries
    @entries ||= InternalConsonantSandhiDeck.load
  end

  def label(entry) = "#{entry['word1_iast']}+#{entry['word2_iast']}"

  def test_not_empty
    refute_empty entries
  end

  def test_every_record_is_well_formed
    entries.each do |e|
      RULE_KEYS.each { |k| assert e.key?(k), "missing #{k} in #{e.inspect}" }
      assert_kind_of Array, e["combined"]
      refute_empty e["combined"], "no combined form for #{label(e)}"
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
               "#{part} of #{label(e)}: #{iast.inspect} vs " \
               "#{dev} which reads as #{IastDevanagari.to_iast(dev).inspect}"
      end
    end
  end

  def test_type_and_rule_number_agree
    entries.each do |e|
      expected = TYPES_TO_RULE_NUMBER[e["type"]]
      refute_nil expected, "unknown type #{e['type'].inspect} in #{label(e)}"
      assert_equal expected, e["rule_number"], "#{label(e)}: wrong rule_number for #{e['type']}"
    end
  end

  def test_both_rules_are_carded
    missing = TYPES_TO_RULE_NUMBER.keys - entries.map { |e| e["type"] }.uniq
    assert_empty missing, "handout internal rules with no cards: #{missing.join(', ')}"
  end

  # Both rules are retroflexions, so in every card except a deliberate contrast
  # card the combined form must actually contain the retroflex the rule produces.
  RETROFLEX = { "satva" => "ष", "natva" => "ण" }.freeze

  def test_the_retroflexion_actually_happened
    entries.reject { |e| e["contrast"] }.each do |e|
      produced = RETROFLEX.fetch(e["type"])
      e["combined"].each do |c|
        assert_includes c["devanagari"], produced,
                        "#{label(e)} is type #{e['type']} but its result #{c['devanagari']} has no #{produced}"
      end
    end
  end

  # A contrast card shows a junction where the rule does NOT fire, so it must
  # carry its own rule/explanation — the type's default text would state a rule
  # its own answer contradicts.
  def test_contrast_cards_have_their_own_rule_text
    contrast = entries.select { |e| e["contrast"] }
    refute_empty contrast

    defaults = entries.reject { |e| e["contrast"] }.group_by { |e| e["type"] }
    contrast.each do |e|
      default = defaults.fetch(e["type"]).first
      refute_equal default["rule"], e["rule"],
                   "contrast card #{label(e)} reuses the default rule text for #{e['type']}"
      refute_equal default["explanation"], e["explanation"],
                   "contrast card #{label(e)} reuses the default explanation for #{e['type']}"
    end
  end

  def test_keys_are_unique
    keys = entries.map { |e| "#{e['type']}:#{label(e)}" }
    assert_equal keys.size, keys.uniq.size, "duplicate card keys: #{keys.tally.select { |_, n| n > 1 }.keys}"
  end
end
