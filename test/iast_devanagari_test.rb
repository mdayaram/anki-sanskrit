# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/iast_devanagari"

class IastDevanagariTest < Minitest::Test
  def fwd(s) = IastDevanagari.to_devanagari(s)
  def rev(s) = IastDevanagari.to_iast(s)

  def test_independent_vowels
    assert_equal "अ", fwd("a")
    assert_equal "आ", fwd("ā")
    assert_equal "ऐ", fwd("ai")
    assert_equal "औ", fwd("au")
    assert_equal "ऋ", fwd("ṛ")
  end

  def test_consonant_inherent_a
    assert_equal "क", fwd("ka")
    assert_equal "न", fwd("na")
  end

  def test_consonant_with_matra
    assert_equal "की", fwd("kī")
    assert_equal "को", fwd("ko")
  end

  def test_word_final_consonant_gets_virama
    assert_equal "जगत्", fwd("jagat")
  end

  def test_clusters
    assert_equal "क्ष", fwd("kṣa")
    assert_equal "ज्ञ", fwd("jña")
    assert_equal "मोक्षः", fwd("mokṣaḥ")
  end

  def test_anusvara_and_visarga
    assert_equal "अहंकारः", fwd("ahaṃkāraḥ")
    assert_equal "अभावः", fwd("abhāvaḥ")
  end

  def test_to_iast_anusvara_before_stop_is_homorganic
    # Anusvara realises as the nasal homorganic with the following stop.
    assert_equal "ahaṅkāraḥ", rev("अहंकारः")  # before क (guttural) -> ṅ
    assert_equal "sambandhaḥ", rev("संबन्धः")  # before ब (labial)   -> m
    assert_equal "sañjñā", rev("संज्ञा")       # before ज (palatal)  -> ñ
  end

  def test_to_iast_anusvara_before_nonstop_stays_m
    # Before a sibilant/semivowel/ha (or word boundary) it stays ṃ.
    assert_equal "saṃsāraḥ", rev("संसारः")     # before स (sibilant)
    assert_equal "saṃyogaḥ", rev("संयोगः")     # before य (semivowel)
  end

  def test_valid_pair_accepts_anusvara_and_explicit_spellings
    # Both spellings of a homorganic cluster are valid for the same IAST.
    assert IastDevanagari.valid_pair?("ahaṅkāraḥ", "अहंकारः")   # anusvara
    assert IastDevanagari.valid_pair?("ahaṅkāraḥ", "अहङ्कारः")  # explicit ṅ+क
  end

  def test_valid_pair_rejects_mismatched_devanagari
    refute IastDevanagari.valid_pair?("ahaṅkāraḥ", "अभावः")
  end

  def test_real_headwords
    assert_equal "ज्ञानम्", fwd("jñānam")
    assert_equal "ब्रह्मन्", fwd("brahman")
    assert_equal "आत्मा", fwd("ātmā")
  end

  def test_round_trip
    %w[abhāvaḥ mokṣaḥ jñānam ātmā ahaṅkāraḥ jagat brahman vivekaḥ saṃsāraḥ].each do |w|
      assert_equal w, rev(fwd(w)), "round-trip failed for #{w}"
    end
  end
end
