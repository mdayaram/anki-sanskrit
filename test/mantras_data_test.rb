# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/mantras"
require_relative "../lib/iast_devanagari"
require_relative "../lib/paths"

# Integrity check on data/mantras.json, the committed source of truth for the
# mantra deck. There is nothing derived here — the Devanagari, the IAST and the
# translations are all curated — so the test's whole job is to guarantee that the
# stored Devanagari and the stored IAST are the same text: every line of the
# mantra, and every word in the gloss, must read (IastDevanagari.to_iast) to
# exactly its stored transliteration.
class MantrasDataTest < Minitest::Test
  KEYS = %w[id name source devanagari transliteration translations
            word_meanings notes audio_file audio_source].freeze

  def entries
    @entries ||= Mantras.load
  end

  def test_not_empty
    refute_empty entries
  end

  def test_every_record_is_well_formed
    entries.each do |m|
      KEYS.each { |k| assert m.key?(k), "#{m['id']}: missing #{k}" }
      # An ordered list rather than a hash so each translation carries its own
      # attribution as the label the card shows, and the card renders any number
      # of them without the generator knowing their names.
      assert_kind_of Array, m["translations"]
      refute_empty m["translations"], "#{m['id']}: needs at least one translation"
      m["translations"].each do |t|
        %w[label text].each { |k| assert t.key?(k), "#{m['id']}: translation missing #{k}: #{t.inspect}" }
      end

      # word_meanings/notes are curatorial metadata only (not rendered on the
      # card — see lib/generators/mantras.rb), so an entry may leave them empty.
      assert_kind_of Array, m["word_meanings"]
      m["word_meanings"].each do |w|
        %w[devanagari iast meaning].each { |k| assert w.key?(k), "#{m['id']}: gloss entry missing #{k}: #{w.inspect}" }
      end
      assert m.dig("audio_source", "url"), "#{m['id']}: audio needs a source URL to be traceable"
      assert m.dig("audio_source", "credit"), "#{m['id']}: audio needs a credit"
    end
  end

  def test_ids_are_unique
    ids = entries.map { |m| m["id"] }
    assert_equal ids.size, ids.uniq.size, "duplicate ids: #{ids.tally.select { |_, n| n > 1 }.keys}"
  end

  def test_devanagari_and_transliteration_agree_line_for_line
    # Compared per line so a mismatch points at the line that is wrong, and with
    # ignore_spacing because the Devanagari is written sandhi-joined
    # (तत्सवितुर्वरेण्यं) while the IAST separates the words for the reader.
    entries.each do |m|
      dev = m["devanagari"].split("\n")
      iast = m["transliteration"].split("\n")
      assert_equal dev.size, iast.size, "#{m['id']}: #{dev.size} Devanagari lines vs #{iast.size} IAST lines"

      dev.zip(iast).each_with_index do |(d, i), n|
        assert IastDevanagari.valid_pair?(i, d, ignore_spacing: true),
               "#{m['id']} line #{n + 1}: #{i.inspect} vs #{d} which reads as " \
               "#{IastDevanagari.to_iast(d).inspect}"
      end
    end
  end

  def test_every_glossed_word_is_a_valid_spelling
    # The gloss lists citation forms, not the sandhi-joined forms in the text, so
    # each is a single word and spacing is compared strictly.
    entries.each do |m|
      m["word_meanings"].each do |w|
        assert IastDevanagari.valid_pair?(w["iast"], w["devanagari"]),
               "#{m['id']} gloss #{w['iast'].inspect} vs #{w['devanagari']} which reads as " \
               "#{IastDevanagari.to_iast(w['devanagari']).inspect}"
      end
    end
  end

  def test_audio_is_committed
    # Unlike the Gita recitations, mantra audio is committed (one small trimmed
    # clip per mantra), so the referenced file must actually be in the repo.
    entries.each do |m|
      path = File.join(Paths::MANTRA_AUDIO_DIR, m["audio_file"])
      assert File.exist?(path), "#{m['id']}: missing audio #{path}"
    end
  end

  def test_no_vedic_accent_marks
    # Sources often print the mantra with svara marks (U+0951 udātta, U+0952
    # anudātta). They do not survive the transliteration round-trip and render
    # inconsistently, so the curated text stays unaccented.
    entries.each do |m|
      refute_match(/[॒॑]/, m["devanagari"], "#{m['id']}: Devanagari carries Vedic accent marks")
    end
  end
end
