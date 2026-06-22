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

  def test_real_headwords
    assert_equal "ज्ञानम्", fwd("jñānam")
    assert_equal "ब्रह्मन्", fwd("brahman")
    assert_equal "आत्मा", fwd("ātmā")
  end

  def test_round_trip
    %w[abhāvaḥ mokṣaḥ jñānam ātmā ahaṃkāraḥ jagat brahman vivekaḥ saṃsāraḥ].each do |w|
      assert_equal w, rev(fwd(w)), "round-trip failed for #{w}"
    end
  end
end
