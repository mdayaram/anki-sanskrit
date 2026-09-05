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

  # Both rules turn on three conditions — a trigger, a restriction on the target
  # sound, and a limited set of sounds that may intervene:
  #
  #   ṇatva  (Pāṇini 8.4.1-8.4.2, Whitney §189): trigger र्/ऋ/ॠ/ष्; the न् followed
  #          by a vowel or न् म् य् व्; vowels, क-varga, प-varga, य् व् ह् or
  #          anusvāra may intervene.
  #   ṣatva  (Pāṇini 8.3.57-8.3.59, Whitney §§180-181): trigger a vowel other than
  #          अ/आ, or क-varga, र्, ल्; the स् neither word-final nor before र्; only
  #          anusvāra, visarga or a sibilant may intervene.
  #
  # The card set is meant to exercise every trigger and every permitted intervening
  # class of BOTH rules, plus each way a rule can fail. Every record tags what it
  # demonstrates in `covers`, and this test is what keeps that coverage from
  # silently eroding if an example is ever swapped out.
  REQUIRED_COVERAGE = {
    "natva" => %w[
      trigger_ra trigger_ri trigger_sha
      via_vowel via_kavarga via_pavarga via_ya via_va via_ha via_anusvara
      before_vowel
      blocked_intervener blocked_follower
    ],
    "satva" => %w[
      s_trigger_i s_trigger_u s_trigger_ri s_trigger_o s_trigger_ka s_trigger_ra
      s_via_none s_via_visarga s_via_anusvara
      s_blocked_trigger
    ]
  }.freeze

  # Which tags mark a card where the rule deliberately does NOT fire.
  FAILURE_TAGS = %w[blocked_intervener blocked_follower s_blocked_trigger].freeze

  def test_every_card_states_its_analysis
    entries.each do |e|
      refute_nil e["analysis"], "#{label(e)} has no analysis line"
      refute_empty e["analysis"]
      assert_kind_of Array, e["covers"]
      refute_empty e["covers"], "#{label(e)} tags no coverage"
    end
  end

  def test_examples_cover_every_condition_of_both_rules
    REQUIRED_COVERAGE.each do |type, required|
      covered = entries.select { |e| e["type"] == type }.flat_map { |e| e["covers"] }.uniq
      missing = required - covered
      assert_empty missing, "no #{type} example demonstrates: #{missing.join(', ')}"

      unknown = covered - required
      assert_empty unknown, "unknown #{type} coverage tags: #{unknown.join(', ')}"
    end
  end

  # Each failure mode is a contrast card, and every contrast card is one of them.
  def test_every_failure_mode_is_a_contrast_card
    entries.select { |e| e["contrast"] }.each do |e|
      assert (e["covers"] & FAILURE_TAGS).any?,
             "contrast card #{label(e)} does not say which condition fails"
    end
    FAILURE_TAGS.each do |tag|
      card = entries.find { |e| e["covers"].include?(tag) }
      refute_nil card, "no card for #{tag}"
      assert card["contrast"], "#{label(card)} demonstrates #{tag} but is not flagged contrast"
    end
  end

  def test_keys_are_unique
    keys = entries.map { |e| "#{e['type']}:#{label(e)}" }
    assert_equal keys.size, keys.uniq.size, "duplicate card keys: #{keys.tally.select { |_, n| n > 1 }.keys}"
  end
end
