# frozen_string_literal: true

require "json"

# Shared Anki card primitives and every deck name. All generators write the same
# tab-separated import format, so the header and field handling live here once.
#
# Card HTML avoids inline style="..." attributes: semicolons inside styles
# collide with parsers that read the TSV as semicolon-separated. Use <big>,
# <center>, <b>, <ul> instead.
module Anki
  # The alphabet: one parent deck with numbered subdecks (Anki's "::"), numbered
  # so Anki's alphabetical sort gives the learning order. The basic alphabet file
  # holds both vowels and consonants, so it sets each row's deck in a Deck column
  # (see write_deck); the other alphabet files each target one subdeck.
  DECK = "🕉️ Sanskrit Alphabet"
  ALPHABET_VOWELS_DECK       = "#{DECK}::1. Vowels"
  ALPHABET_CONSONANTS_DECK   = "#{DECK}::2. Consonants"
  ALPHABET_COMBINATIONS_DECK = "#{DECK}::3. Combinations"
  ALPHABET_CONJUNCTS_DECK    = "#{DECK}::4. Conjuncts"
  ALPHABET_ANUSVARA_DECK     = "#{DECK}::5. Anusvāra"

  # The Bhagavad Gita verse deck (a separate deck from the alphabet).
  GITA_DECK = "🕉️ Bhagavad Gita"

  # The Vedanta glossary word deck (a separate deck).
  VEDANTA_DECK = "🕉️ Vedanta Glossary"

  # The eight sandhi decks, nested with Anki's "::" under two parents so they
  # collapse in the deck list: one for JOINING (two parts -> combined form) and
  # one for SPLITTING (combined form -> its parts, vigraha). Each parent holds the
  # same four families, numbered so Anki's alphabetical sort shows them in the
  # order they are learned: vowel (svara), visarga, then consonant (vyañjana)
  # sandhi split the way its Arsha Bodha handout splits it — external (between
  # two words) and internal (within one word: ṣatva/ṇatva).
  #
  # Joining and splitting are separate decks, not one "Basic (and reversed)"
  # note type, because the joining card's back is a rich teaching panel that
  # would spoil the prompt on a native reverse.
  SANDHI_JOINING_PARENT   = "🕉️ Sanskrit Sandhi Joining"
  SANDHI_SPLITTING_PARENT = "🕉️ Sanskrit Sandhi Splitting"

  VOWEL_SANDHI_DECK              = "#{SANDHI_JOINING_PARENT}::1. Vowel"
  VISARGA_SANDHI_DECK            = "#{SANDHI_JOINING_PARENT}::2. Visarga"
  EXTERNAL_CONSONANT_SANDHI_DECK = "#{SANDHI_JOINING_PARENT}::3. External Consonant"
  INTERNAL_CONSONANT_SANDHI_DECK = "#{SANDHI_JOINING_PARENT}::4. Internal Consonant"

  VOWEL_SANDHI_SPLIT_DECK              = "#{SANDHI_SPLITTING_PARENT}::1. Vowel"
  VISARGA_SANDHI_SPLIT_DECK            = "#{SANDHI_SPLITTING_PARENT}::2. Visarga"
  EXTERNAL_CONSONANT_SANDHI_SPLIT_DECK = "#{SANDHI_SPLITTING_PARENT}::3. External Consonant"
  INTERNAL_CONSONANT_SANDHI_SPLIT_DECK = "#{SANDHI_SPLITTING_PARENT}::4. Internal Consonant"

  # The mantra deck: whole mantras (Devanagari -> translation + recitation), the
  # only deck besides the alphabet and the Gita that carries audio.
  MANTRAS_DECK = "🕉️ Sanskrit Mantras"

  # The numbers deck: Devanagari digits, number words (both directions), the
  # ordinals as they appear in Gita colophons, and the compounding rules.
  NUMBERS_DECK = "🕉️ Sanskrit Numbers"

  # The declension decks. First the eight cases themselves (English name ->
  # Sanskrit name, with the case's uses from the "Sanskrit Case Functions"
  # handout and its endings from the "Basic Terminations" handout), then one
  # subdeck per noun paradigm, paradigm first: each paradigm holds one subdeck
  # per case, numbered by the case's own Sanskrit number (prathamā = 1), so a
  # case can be practised on its own. Each later model-noun handout (रामः/फलम्,
  # शाला/दासी, …) joins as the next numbered paradigm with the same 8 subdecks.
  DECLENSIONS_PARENT = "🕉️ Sanskrit Declensions"
  CASE_NAMES_DECK    = "#{DECLENSIONS_PARENT}::1. Cases"
  T_NOUNS_DECK       = "#{DECLENSIONS_PARENT}::3. त्-Ending Nouns"

  # "<paradigm>::3. Instrumental" — a paradigm's subdeck for one case.
  def self.case_subdeck(paradigm, number, english) = "#{paradigm}::#{number}. #{english}"

  # A large centered glyph: the text wrapped in five nested <big> tags.
  def self.glyph_front(text)
    "<center>#{'<big>' * 5}#{text}#{'</big>' * 5}</center>"
  end

  # Write an Anki import file: the standard 6-line header followed by one row per
  # entry. `rows` is an array of [key, front, back]; `deck:` sets the #deck header
  # (defaults to DECK). A row may instead be [key, front, back, deck] to put that
  # card in its own deck: then EVERY row must carry one, and the file gets a Deck
  # column (#deck column:4) instead of a #deck header. Tabs and newlines inside a
  # field would break the row/column split, so both are flattened to spaces.
  # Returns the row count.
  def self.write_deck(path, rows, deck: DECK)
    per_row = rows.any? { |row| row.size > 3 }
    raise ArgumentError, "either every row names its deck or none does" if per_row && !rows.all? { |row| row.size == 4 }

    File.open(path, "w:UTF-8") do |f|
      f.puts "#separator:Tab"
      f.puts "#html:true"
      f.puts per_row ? "#deck column:4" : "#deck:#{deck}"
      f.puts "#notetype:Basic"
      f.puts per_row ? "#columns:Key\tFront\tBack\tDeck" : "#columns:Key\tFront\tBack"
      f.puts "#guid column:1"

      rows.each do |row|
        f.puts row.map { |field| field.to_s.gsub(/\t/, " ").gsub(/\r?\n/, " ") }.join("\t")
      end
    end
    rows.size
  end

  # Write a pretty-printed JSON intermediate. Returns the entry count.
  def self.write_json(path, data)
    File.write(path, JSON.pretty_generate(data))
    data.size
  end
end
