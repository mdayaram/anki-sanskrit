# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/external_consonant_sandhi_deck"
require_relative "../lib/iast_devanagari"

# Data-integrity check on data/external_consonant_sandhi.json (the committed source
# of truth). There is no derivation engine for consonant sandhi — the outcomes are
# curated from the Arsha Bodha handout and cross-checked against Whitney, Ruppel
# and learnsanskrit.org — so the test's job is to guarantee the spelling of every
# stored form: each word and each combined alternative must have Devanagari that
# reads (IastDevanagari.to_iast) to exactly its stored IAST, and the structure must
# be well formed.
class ExternalConsonantSandhiDeckTest < Minitest::Test
  RULE_KEYS = %w[type rule_number word1_iast word1_devanagari
                 word1_underlying_iast word1_underlying_devanagari
                 word2_iast word2_devanagari combined rule explanation source].freeze

  # The handout's 12 external rules. Rule 3 covers palatals and cerebrals on one
  # line and is carded as two types, so 12 rules -> 13 types. Every one must stay
  # populated: a rule silently losing all its cards is the failure this catches.
  TYPES_TO_RULE_NUMBER = {
    "hc_voicing" => 1, "hc_nasal" => 2,
    "t_palatal" => 3, "t_cerebral" => 3,
    "t_l" => 4, "t_sha" => 5, "m_anusvara" => 6,
    "n_nasal" => 7, "n_anusvara_sibilant" => 8, "n_l" => 9,
    "nasal_doubling" => 10, "stop_ha" => 11, "cha_doubling" => 12
  }.freeze

  def entries
    @entries ||= ExternalConsonantSandhiDeck.load
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
      if e["word1_underlying_iast"]
        pairs << ["word1_underlying", e["word1_underlying_iast"], e["word1_underlying_devanagari"]]
      end
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
      assert_equal expected, e["rule_number"],
                   "#{label(e)} is type #{e['type']} (handout rule #{expected}) " \
                   "but claims rule_number #{e['rule_number']}"
    end
  end

  def test_every_rule_of_the_handout_is_carded
    covered = entries.map { |e| e["type"] }.uniq
    missing = TYPES_TO_RULE_NUMBER.keys - covered
    assert_empty missing, "handout rules with no cards: #{missing.join(', ')}"
  end

  # The underlying form is word1's citation form, shown under the front so the
  # padānta reduction that produced the sandhi-final consonant is visible. It is
  # only meaningful when it actually differs; storing an identical pair would put a
  # pointless "(वाक् ← वाक्)" on the card.
  def test_underlying_form_differs_when_present
    entries.each do |e|
      iast, dev = e["word1_underlying_iast"], e["word1_underlying_devanagari"]
      assert_equal iast.nil?, dev.nil?,
                   "#{label(e)}: underlying IAST and Devanagari must both be set or both be null"
      next if iast.nil?

      refute_equal e["word1_iast"], iast,
                   "#{label(e)}: underlying form #{iast} is identical to word1 — it should be null"
    end
  end

  # A contrast card shows a junction where the rule does NOT fire (एतान् + इह has a
  # long vowel, so its न् does not double), so it must carry its own rule and
  # explanation — the type's default text would state a rule its own answer
  # contradicts.
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

  # Every non-contrast card of a type shares that type's rule text, so a card
  # filed under the wrong rule is visible.
  def test_non_contrast_cards_of_a_type_share_its_rule_text
    entries.reject { |e| e["contrast"] }.group_by { |e| e["type"] }.each do |type, es|
      assert_equal 1, es.map { |e| e["rule"] }.uniq.size,
                   "type #{type} has more than one rule text: #{es.map { |e| e['rule'] }.uniq}"
    end
  end

  def test_keys_are_unique
    keys = entries.map { |e| "#{e['type']}:#{label(e)}" }
    assert_equal keys.size, keys.uniq.size, "duplicate card keys: #{keys.tally.select { |_, n| n > 1 }.keys}"
  end
end
