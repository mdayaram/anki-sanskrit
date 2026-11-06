# frozen_string_literal: true

# Renders the word-meaning gloss shared by every sandhi deck (vowel, visarga,
# external and internal consonant — forward and splitting). Each record in those
# data files carries three curated strings: `word1_meaning`, `word2_meaning` and
# `combined_meaning`. For a compound the combined meaning is its definition; for
# two free words it is a translation of the phrase; for a stem + ending it names
# the grammatical function (an affix has no dictionary meaning of its own).
#
#   deva “god” + ālaya “abode, dwelling”
#   → devālaya “temple (abode of a god)”
#
# Every deck — forward and splitting alike — shows the parts first, then the
# whole, so the gloss always reads the same way regardless of the prompt.
#
# Curly quotes, not ASCII ones: the decks are tab-separated and a field opening
# with `"` would be read as a quoted field by Anki's importer.
module SandhiMeanings
  FIELDS = %w[word1_meaning word2_meaning combined_meaning].freeze

  module_function

  # `combined_iast` is passed in because the decks store it differently (a single
  # string in the vowel deck, the primary form of a `combined` list elsewhere).
  def html(entry, combined_iast)
    parts = "#{gloss(entry['word1_iast'], entry['word1_meaning'])} + " \
            "#{gloss(entry['word2_iast'], entry['word2_meaning'])}"
    whole = gloss(combined_iast, entry["combined_meaning"])
    "<br><br><small>#{parts}<br>→ #{whole}</small>"
  end

  def gloss(iast, meaning) = "<i>#{iast}</i> “#{meaning}”"
end
