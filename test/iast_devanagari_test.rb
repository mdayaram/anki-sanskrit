# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/iast_devanagari"

# IastDevanagari is a Devanagari -> IAST reader (to_iast) plus a pair validator
# (valid_pair?). to_iast canonicalises: it is many-to-one (both the anusvara and
# the explicit-conjunct spelling of a homorganic cluster map to the same IAST).
class IastDevanagariTest < Minitest::Test
  def rev(s) = IastDevanagari.to_iast(s)

  def test_independent_vowels
    assert_equal "a", rev("अ")
    assert_equal "ā", rev("आ")
    assert_equal "ai", rev("ऐ")
    assert_equal "au", rev("औ")
    assert_equal "ṛ", rev("ऋ")
  end

  def test_consonant_inherent_a
    assert_equal "ka", rev("क")
    assert_equal "na", rev("न")
  end

  def test_consonant_with_matra
    assert_equal "kī", rev("की")
    assert_equal "ko", rev("को")
  end

  def test_word_final_consonant_has_virama
    assert_equal "jagat", rev("जगत्")
  end

  def test_clusters
    assert_equal "kṣa", rev("क्ष")
    assert_equal "jña", rev("ज्ञ")
    assert_equal "mokṣaḥ", rev("मोक्षः")
  end

  def test_visarga
    assert_equal "abhāvaḥ", rev("अभावः")
  end

  def test_real_headwords
    assert_equal "jñānam", rev("ज्ञानम्")
    assert_equal "brahman", rev("ब्रह्मन्")
    assert_equal "ātmā", rev("आत्मा")
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

  def test_to_iast_canonicalises_both_spellings_of_a_homorganic_cluster
    # The explicit conjunct and the anusvara spelling read to the same IAST.
    assert_equal rev("अहङ्कारः"), rev("अहंकारः")
  end

  def test_valid_pair_accepts_anusvara_and_explicit_spellings
    assert IastDevanagari.valid_pair?("ahaṅkāraḥ", "अहंकारः")   # anusvara
    assert IastDevanagari.valid_pair?("ahaṅkāraḥ", "अहङ्कारः")  # explicit ṅ+क
  end

  def test_valid_pair_rejects_mismatched_devanagari
    refute IastDevanagari.valid_pair?("ahaṅkāraḥ", "अभावः")
  end
end
