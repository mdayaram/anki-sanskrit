# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/case_analysis"
require_relative "../lib/case_functions"
require_relative "../lib/iast_devanagari"

# Data-integrity check on data/case_analysis.json, the committed source of truth
# for the Case Analysis deck. Nothing is derived, so this is the only validation:
# every case and handout use must be real and agree with each other, every
# Devanagari must read as exactly its stored IAST, every analysed word must occur
# in its sentence, agreeing words must match their head, and every word whose
# case use falls outside the handout must cite where its explanation comes from.
class CaseAnalysisDataTest < Minitest::Test
  WORD_FIELDS = %w[english devanagari iast stem_devanagari stem_iast case why].freeze
  NUMBERS = %w[singular dual plural].freeze
  GENDERS = ["m", "f", "n", nil].freeze
  NOMINATIVE_AGREEMENT = %w[1c 1d].freeze

  def data      = @data ||= CaseAnalysis.load
  def sentences = data["sentences"]
  def handout   = @handout ||= CaseFunctions.load
  def case_ids  = handout["cases"].map { |c| c["id"] }
  def uses      = handout["uses"].to_h { |u| [u["id"], u["case"]] }
  def words     = sentences.flat_map { |s| s["words"].map { |w| [s, w] } }

  def test_label_notation
    assert_equal "mAp", CaseAnalysis.label("m", "accusative", "plural")
    assert_equal "Ns", CaseAnalysis.label(nil, "nominative", "singular")
    assert_equal "fAbs", CaseAnalysis.label("f", "ablative", "singular")
    assert_equal "nGd", CaseAnalysis.label("n", "genitive", "dual")
  end

  def test_records_have_every_field
    refute_empty sentences
    sentences.each do |s|
      %w[id source english devanagari iast].each { |f| refute_empty s[f].to_s, "#{s['id']} missing #{f}" }
      refute_empty s["words"], "#{s['id']} has no words"
    end
    words.each do |s, w|
      WORD_FIELDS.each { |f| refute_empty w[f].to_s, "#{s['id']} / #{w['devanagari']} missing #{f}" }
      %w[use agrees_with reference alternatives].each { |f| assert w.key?(f), "#{s['id']} / #{w['devanagari']} missing #{f}" }
    end
  end

  def test_ids_unique
    ids = sentences.map { |s| s["id"] }
    assert_equal ids.size, ids.uniq.size, "duplicate ids: #{ids.tally.select { |_, n| n > 1 }.keys}"
  end

  def test_case_and_use_agree
    words.each do |s, w|
      where = "#{s['id']} / #{w['devanagari']}"
      assert_includes case_ids, w["case"], where
      assert_includes GENDERS, w["gender"], where
      assert_includes NUMBERS, w["number"], where
      assert_equal w["case"], uses.fetch(w["use"]), "#{where}: use #{w['use']} is not a #{w['case']} use" if w["use"]
      w["alternatives"].each do |alt|
        assert_includes case_ids, alt["case"], where
        refute_empty alt["why"].to_s, where
        assert_equal alt["case"], uses.fetch(alt["use"]), "#{where}: alternative use #{alt['use']}" if alt["use"]
      end
    end
  end

  def test_beyond_handout_rows_cite_a_reference
    words.each do |s, w|
      next if w["use"]

      refute_empty w["reference"].to_s, "#{s['id']} / #{w['devanagari']}: use outside the handout needs a reference"
    end
  end

  def test_sentences_read_as_their_iast
    sentences.each do |s|
      assert_pair s["iast"], s["devanagari"], s["id"]
      s["words"].each do |w|
        assert_pair w["iast"], w["devanagari"], s["id"]
        assert_pair w["stem_iast"], w["stem_devanagari"], s["id"]
      end
    end
  end

  def test_each_form_occurs_in_its_sentence
    sentences.each do |s|
      %w[devanagari iast].each do |script|
        tokens = s[script].gsub(/[!?.,;।॥“”‘’]/, " ").split
        s["words"].group_by { |w| w[script] }.each do |form, rows|
          assert tokens.count(form) >= rows.size,
                 "#{s['id']}: #{form} appears #{tokens.count(form)}× in the #{script} sentence, analysed #{rows.size}×"
        end
      end
    end
  end

  def test_agreeing_words_match_their_head
    sentences.each do |s|
      s["words"].each do |w|
        next unless w["agrees_with"]

        head = s["words"].find { |h| !h.equal?(w) && h["devanagari"] == w["agrees_with"] }
        where = "#{s['id']} / #{w['devanagari']}"
        refute_nil head, "#{where}: agrees_with #{w['agrees_with']} is not a word in the sentence"
        assert_equal head["case"], w["case"], where
        assert_equal head["number"], w["number"], where
        # In the nominative the handout has its own uses for agreeing words
        # (1c apposition, 1d adjective); elsewhere they take their head's use.
        nominative_own = w["case"] == "nominative" && NOMINATIVE_AGREEMENT.include?(w["use"])
        assert nominative_own || head["use"] == w["use"],
               "#{where}: use #{w["use"].inspect} differs from its head (#{head["use"].inspect})"
        assert_equal head["gender"], w["gender"], where if head["gender"] && w["gender"]
      end
    end
  end

  def test_text_hygiene
    sentences.each do |s|
      texts = [s["english"]] + s["words"].flat_map { |w| [w["english"], w["why"], w["reference"]] + w["alternatives"].map { |a| a["why"] } }
      texts.compact.each do |t|
        refute_match(/["\t<>]/, t, "#{s['id']}: ASCII quote, tab or markup in #{t.inspect}")
      end
    end
  end

  private

  def assert_pair(iast, dev, where)
    assert IastDevanagari.valid_pair?(iast, dev),
           "#{where}: #{iast} vs #{dev} (reads #{IastDevanagari.to_iast(dev)})"
  end
end
