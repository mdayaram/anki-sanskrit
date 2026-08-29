# frozen_string_literal: true

require_relative "base"
require_relative "../mantras"

module Generators
  # Mantra deck. Pure reader over data/mantras.json (the committed source of
  # truth), read via Mantras.load. Nothing is derived: the Devanagari, its
  # transliteration and the translations are all curated, and
  # test/mantras_data_test.rb checks that the Devanagari and the IAST are the same
  # text (IastDevanagari.valid_pair?, with ignore_spacing since the Devanagari is
  # sandhi-joined where the IAST separates words).
  #
  #   Front: the mantra in Devanagari, nothing else — naming it would give it away
  #   Back:  every translation (each labelled with its own attribution) and the
  #          recitation. Deliberately lean: no name/source header, no
  #          word-by-word gloss, no notes — a translation's label already carries
  #          the "source for the translation" the card needs.
  #
  # `name`, `source`, `word_meanings` and `notes` still live in data/mantras.json
  # (curatorial metadata / a possible future word deck, per the Gita's
  # word_meanings) but the card no longer renders them.
  #
  # There is deliberately NO full-line IAST on the back either: `transliteration`
  # stays in the data purely to validate the curated Devanagari
  # (test/mantras_data_test.rb).
  #
  # Audio lives in data/mantra_audio/ and is COMMITTED (one short trimmed clip per
  # mantra), so unlike the Gita deck there is no ensure_audio! download hook — see
  # bootstrap/trim_mantra_audio.sh and bootstrap/trim_pratah_smarana_audio.sh for
  # how a clip is cut from its source.
  class Mantras < Base
    KEY         = "mantras"
    DESCRIPTION = "Mantras (Devanagari -> translation + recitation)"
    OUTPUT_TXT  = "sanskrit_mantras_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::MANTRAS_DECK
    def audio_dir = Paths::MANTRA_AUDIO_DIR

    def build = ::Mantras.load

    def card(entry)
      key   = "mantra:#{entry['id']}"
      front = "<center>#{'<big>' * 2}#{br(entry['devanagari'])}#{'</big>' * 2}</center>"

      sections = entry["translations"].map { |t| "<b>#{t['label']}:</b><br>#{br(t['text'])}" }
      sections << "[sound:#{entry['audio_file']}]"

      [key, front, sections.join("<br><br>")]
    end

    def audio_files(data)
      data.map { |entry| entry["audio_file"] }.compact
    end

    private

    # Source newlines become <br> so multi-line mantras render as written; they
    # would otherwise be flattened to spaces by write_deck's row protection.
    def br(text)
      text.to_s.gsub(/\r?\n/, "<br>")
    end
  end
end
