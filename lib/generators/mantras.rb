# frozen_string_literal: true

require_relative "base"
require_relative "../mantras"

module Generators
  # Mantra deck. Pure reader over data/mantras.json (the committed source of
  # truth), read via Mantras.load. Nothing is derived: the Devanagari, its
  # transliteration, the translations and the word gloss are all curated, and
  # test/mantras_data_test.rb checks that the Devanagari and the IAST are the same
  # text (IastDevanagari.valid_pair?, with ignore_spacing since the Devanagari is
  # sandhi-joined where the IAST separates words).
  #
  #   Front: the mantra in Devanagari, nothing else — naming it would give it away
  #   Back:  what it is and where it is from, every translation, the word-by-word
  #          gloss, any notes, and the recitation.
  #
  # There is deliberately NO full-line IAST on the back: the gloss already gives
  # every word's transliteration, so repeating the whole mantra in IAST only
  # crowds the card. `transliteration` stays in the data all the same — it is what
  # validates the curated Devanagari (test/mantras_data_test.rb).
  #
  # Audio lives in data/mantra_audio/ and is COMMITTED (one short trimmed clip per
  # mantra), so unlike the Gita deck there is no ensure_audio! download hook — see
  # bootstrap/trim_mantra_audio.sh for how a clip is cut from its source.
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

      sections = [
        "<center><b>#{entry['name']}</b><br><small>#{entry['source']}</small></center>",
        *entry["translations"].map { |t| "<b>#{t['label']}:</b><br>#{br(t['text'])}" },
        "<b>Word by word:</b><ul>#{gloss(entry['word_meanings'])}</ul>"
      ]
      sections << "<small>#{br(entry['notes'])}</small>" unless entry["notes"].to_s.empty?
      sections << "[sound:#{entry['audio_file']}]"

      [key, front, sections.join("<br><br>")]
    end

    def audio_files(data)
      data.map { |entry| entry["audio_file"] }.compact
    end

    private

    def gloss(words)
      words.map { |w| "<li>#{w['devanagari']} <i>#{w['iast']}</i> — #{w['meaning']}</li>" }.join
    end

    # Source newlines become <br> so multi-line mantras render as written; they
    # would otherwise be flattened to spaces by write_deck's row protection.
    def br(text)
      text.to_s.gsub(/\r?\n/, "<br>")
    end
  end
end
