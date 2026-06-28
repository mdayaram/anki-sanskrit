# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/sandhi"

class SandhiTest < Minitest::Test
  def combined(w1, w2, type) = Sandhi.join(w1, w2, type).fetch(:combined)

  def test_savarna_dirgha
    assert_equal "devālaya",   combined("deva", "ālaya", :dirgha)   # a + ā
    assert_equal "vidyārtha",  combined("vidyā", "artha", :dirgha)  # ā + a
    assert_equal "mahātman",   combined("mahā", "ātman", :dirgha)   # ā + ā
    assert_equal "ravīndra",   combined("ravi", "indra", :dirgha)   # i + i
    assert_equal "kavīśvara",  combined("kavi", "īśvara", :dirgha)  # i + ī
    assert_equal "gurūpadeśa", combined("guru", "upadeśa", :dirgha) # u + u
    assert_equal "vadhūtsava", combined("vadhū", "utsava", :dirgha) # ū + u
  end

  def test_guna
    assert_equal "devendra",   combined("deva", "indra", :guna)    # a + i → e
    assert_equal "gaṇeśa",     combined("gaṇa", "īśa", :guna)      # a + ī → e
    assert_equal "mahendra",   combined("mahā", "indra", :guna)    # ā + i → e
    assert_equal "sūryodaya",  combined("sūrya", "udaya", :guna)   # a + u → o
    assert_equal "mahotsava",  combined("mahā", "utsava", :guna)   # ā + u → o
    assert_equal "hitopadeśa", combined("hita", "upadeśa", :guna)  # a + u → o
    assert_equal "devarṣi",    combined("deva", "ṛṣi", :guna)      # a + ṛ → ar
    assert_equal "maharṣi",    combined("mahā", "ṛṣi", :guna)      # ā + ṛ → ar
  end

  def test_vrddhi
    assert_equal "ekaika",     combined("eka", "eka", :vrddhi)     # a + e → ai
    assert_equal "sadaiva",    combined("sadā", "eva", :vrddhi)    # ā + e → ai
    assert_equal "tathaiva",   combined("tathā", "eva", :vrddhi)   # ā + e → ai
    assert_equal "naiva",      combined("na", "eva", :vrddhi)      # a + e → ai
    assert_equal "jalaugha",   combined("jala", "ogha", :vrddhi)   # a + o → au
    assert_equal "mahauṣadhi", combined("mahā", "oṣadhi", :vrddhi) # ā + o → au
  end

  def test_yan
    assert_equal "pratyakṣa",  combined("prati", "akṣa", :yan)     # i → y
    assert_equal "ityādi",     combined("iti", "ādi", :yan)        # i → y
    assert_equal "pratyeka",   combined("prati", "eka", :yan)      # i → y (before e)
    assert_equal "svalpa",     combined("su", "alpa", :yan)        # u → v
    assert_equal "svāgata",    combined("su", "āgata", :yan)       # u → v
    assert_equal "anvaya",     combined("anu", "aya", :yan)        # u → v
    assert_equal "nanveva",    combined("nanu", "eva", :yan)       # u → v (before e)
    assert_equal "pitrartha",  combined("pitṛ", "artha", :yan)     # ṛ → r
  end

  def test_ayadi
    assert_equal "nayana",  combined("ne", "ana", :ayadi)   # e → ay
    assert_equal "gāyaka",  combined("gai", "aka", :ayadi)  # ai → āy
    assert_equal "bhavana", combined("bho", "ana", :ayadi)  # o → av
    assert_equal "nāvika",  combined("nau", "ika", :ayadi)  # au → āv
  end

  def test_avagraha
    assert_equal "te'pi",    combined("te", "api", :avagraha)    # e + a → e'
    assert_equal "vane'sti", combined("vane", "asti", :avagraha) # e + a → e'
    assert_equal "so'pi",    combined("so", "api", :avagraha)    # o + a → o'
    assert_equal "rāmo'pi",  combined("rāmo", "api", :avagraha)  # o + a → o'
  end

  def test_result_carries_metadata
    r = Sandhi.join("deva", "indra", :guna)
    assert_equal :guna, r.fetch(:type)
    assert_equal "deva", r.fetch(:word1)
    assert_equal "indra", r.fetch(:word2)
    assert_equal "devendra", r.fetch(:combined)
    refute_empty r.fetch(:name)
    refute_empty r.fetch(:devanagari_name)
    refute_empty r.fetch(:explanation)
  end

  def test_mislabeled_type_is_rejected
    # deva + indra is guṇa, not vṛddhi — the engine should reject a wrong label
    assert_raises(ArgumentError) { Sandhi.join("deva", "indra", :vrddhi) }
    # ravi + indra is i+i (dīrgha), so yaṇ is wrong
    assert_raises(ArgumentError) { Sandhi.join("ravi", "indra", :yan) }
  end

  def test_word1_must_end_in_a_vowel
    assert_raises(ArgumentError) { Sandhi.join("rājan", "indra", :guna) }
  end
end
