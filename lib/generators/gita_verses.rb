# frozen_string_literal: true

require_relative "base"
require_relative "../gita"
require_relative "../gita_audio_archive"

module Generators
  # Bhagavad Gita verses. Pure transform over data/gita.json (produced by
  # fetch_gita.rb). Targets its own deck (Anki::GITA_DECK), separate from the
  # alphabet. Each card:
  #   Front: the Devanagari shloka (large, centered)
  #   Back:  IAST transliteration + literal + devotional translation + recitation
  #
  # No OUTPUT_JSON: data/gita.json already is the structured intermediate, so a
  # second JSON file would just duplicate it.
  class GitaVerses < Base
    KEY         = "gita-verses"
    DESCRIPTION = "Bhagavad Gita verses (Devanagari -> IAST + translations + audio)"
    OUTPUT_TXT  = "sanskrit_gita_verses_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::GITA_DECK
    def audio_dir = Paths::GITA_AUDIO_DIR

    # The Gita mp3s are not committed (~289 MB); pull them from the GitHub release
    # on demand so `--gita-verses` works without running fetch_gita.rb first.
    def ensure_audio! = GitaAudioArchive.ensure_present!

    def build = Gita.load

    def card(entry)
      chapter = entry["chapter"]
      label   = entry["verse_label"]
      key     = "gita_verse:#{chapter}.#{label}"

      front = "<center><big>#{br(entry['devanagari'])}</big></center>"

      back = [
        "<b>IAST:</b><br>#{br(entry['transliteration'])}",
        "<b>Literal — Gambirananda:</b><br>#{br(entry.dig('translations', 'literal').to_s)}",
        "<b>Devotional — Sivananda:</b><br>#{br(entry.dig('translations', 'devotional').to_s)}",
        "[sound:#{entry['audio_file']}]"
      ].join("<br><br>")

      [key, front, back]
    end

    def audio_files(data)
      data.map { |entry| entry["audio_file"] }.compact
    end

    private

    # Convert source newlines to <br> so multi-line verses/prose render correctly
    # and never break the TSV row. (write_deck also flattens stray newlines.)
    def br(text)
      text.to_s.gsub(/\r?\n/, "<br>")
    end
  end
end
