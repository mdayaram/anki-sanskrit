# frozen_string_literal: true

require_relative "../paths"
require_relative "../anki"

module Generators
  # Common run loop for a category. A subclass declares its constants (KEY,
  # DESCRIPTION, OUTPUT_TXT, optional OUTPUT_JSON) and implements:
  #
  #   build            -> the array of entries (also written to OUTPUT_JSON if set)
  #   card(entry)      -> [key, front, back] for the Anki row
  #   audio_files(data)-> referenced audio filenames (default none)
  #
  # `run` writes the JSON intermediate (when OUTPUT_JSON is set) and the Anki
  # import file, returning a summary hash for main.rb's consolidated report.
  class Base
    # Subclasses with a JSON intermediate override this with a filename.
    OUTPUT_JSON = nil

    # Whether main.rb must load data/letters.json before this generator runs.
    # Generators that read a different data source override this with false.
    def self.requires_letters? = true

    def initialize(letters, letters_by_id)
      @letters = letters
      @letters_by_id = letters_by_id
    end

    def key = self.class::KEY
    def description = self.class::DESCRIPTION

    # The Anki deck these cards belong to. Override for a different deck.
    def deck = Anki::DECK

    # Directory holding this generator's audio sources. Override for a different folder.
    def audio_dir = Paths::AUDIO_DIR

    # Hook to make this generator's audio sources present on disk before they are
    # copied into Anki (e.g. download a release archive). Default: nothing to do,
    # since most decks' audio is committed. Called only when files are missing and
    # the user has confirmed the copy. Override to populate audio_dir.
    def ensure_audio!; end

    def run
      data = build

      json_path = nil
      if self.class::OUTPUT_JSON
        json_path = Paths.data(self.class::OUTPUT_JSON)
        Anki.write_json(json_path, data)
      end

      rows = data.map { |entry| card(entry) }
      txt_path = Paths.output(self.class::OUTPUT_TXT)
      Anki.write_deck(txt_path, rows, deck: deck)

      {
        key: key,
        cards: rows.size,
        txt: txt_path,
        json: json_path,
        deck: deck,
        audio_files: audio_files(data),
        audio_dir: audio_dir,
        ensure_audio: method(:ensure_audio!)
      }
    end

    # Categories that reference [sound:...] override this.
    def audio_files(_data) = []
  end
end
