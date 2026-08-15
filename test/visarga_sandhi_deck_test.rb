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
  RULE_KEYS = %w[type word1_iast word1_devanagari
                 word1_underlying_iast word1_underlying_devanagari
                 word2_iast word2_devanagari combined rule explanation].freeze

  def entries
    @entries ||= VisargaSandhiDeck.load
  end

  # Every string in a record, including the ones nested in `combined`.
  def strings(entry)
    entry.flat_map do |_, v|
      case v
      when String then [v]
      when Array  then v.flat_map { |c| c.is_a?(Hash) ? c.values.grep(String) : [] }
      else []
      end
    end
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
               ["word1_underlying", e["word1_underlying_iast"], e["word1_underlying_devanagari"]],
               ["word2", e["word2_iast"], e["word2_devanagari"]]]
      e["combined"].each_with_index { |c, i| pairs << ["combined[#{i}]", c["iast"], c["devanagari"]] }

      pairs.each do |part, iast, dev|
        assert IastDevanagari.valid_pair?(iast, dev),
               "#{part} of #{e['word1_iast']}+#{e['word2_iast']}: #{iast.inspect} vs " \
               "#{dev} which reads as #{IastDevanagari.to_iast(dev).inspect}"
      end
    end
  end

  def test_underlying_form_ends_in_s_or_r
    # Every word-final visarga is the pause-form of an underlying -s or -r
    # (Whitney §152), so the recovered underlying spelling must end in one of them.
    entries.each do |e|
      assert_match(/[sr]\z/, e["word1_underlying_iast"],
                   "underlying #{e['word1_underlying_iast']} should end in s or r")
    end
  end

  # Before k/kh and p/ph the visarga is retained in WRITING only: in careful
  # pronunciation it is optionally the jihvāmūlīya (velar) or upadhmānīya
  # (bilabial) respectively (Pāṇini 8.3.37), and before a sibilant retention is
  # likewise only one of two accepted outcomes (8.3.36). That is the whole point
  # of these six cards, so the explanation must keep saying it.
  RETAINED_NOTES = {
    /\Ak/  => "jihvāmūlīya",
    /\Akh/ => "jihvāmūlīya",
    /\Ap/  => "upadhmānīya",
    /\Aph/ => "upadhmānīya",
    /\A[śṣs]/ => "assimilation is the default"
  }.freeze

  def test_retained_cards_explain_the_pronunciation
    retained = entries.select { |e| e["type"] == "visarga_retained" }
    refute_empty retained

    retained.each do |e|
      word2 = e["word2_iast"]
      expected = RETAINED_NOTES.find { |pattern, _| word2.match?(pattern) }&.last
      refute_nil expected, "no pronunciation note expected for word2 #{word2.inspect} — is it really `visarga_retained`?"
      assert_includes e["explanation"], expected,
                      "explanation for #{e['word1_iast']}+#{word2} should mention #{expected.inspect}"
    end
  end

  # The Vedic Extensions block (U+1CF0-U+1CFF) holds the jihvāmūlīya (U+1CF5) and
  # upadhmānīya (U+1CF6) signs. They are the "correct" way to write these sounds
  # and they are unusable here: essentially no default font on macOS, iOS, Android
  # or Windows covers the block, so they render as tofu in Anki. Describe the
  # sounds in words instead.
  def test_no_vedic_extension_characters
    entries.each do |e|
      strings(e).each do |s|
        refute_match(/[\u{1CF0}-\u{1CFF}]/, s,
                     "#{e['word1_iast']}+#{e['word2_iast']} contains a Vedic Extensions " \
                     "character (unrenderable in most fonts): #{s.inspect}")
      end
    end
  end

  def test_keys_are_unique
    keys = entries.map { |e| "#{e['type']}:#{e['word1_iast']}+#{e['word2_iast']}" }
    assert_equal keys.size, keys.uniq.size, "duplicate card keys: #{keys.tally.select { |_, n| n > 1 }.keys}"
  end
end
