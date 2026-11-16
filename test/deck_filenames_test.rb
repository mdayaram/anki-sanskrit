# frozen_string_literal: true

require "minitest/autorun"
Dir[File.join(__dir__, "../lib/generators/*.rb")].each { |f| require f }

# Every import file is named after the deck it fills, so a directory listing
# shows which deck each file belongs to and where it sits in that deck:
#
#   🕉️ Sanskrit Declensions::3. त्-Ending Nouns  ->  sanskrit_declensions_3_t_nouns_anki.txt
#
# sanskrit_ + the family (parent deck, minus the emoji and "Sanskrit") + the
# subdeck's number, then a short name for the subdeck. Files therefore sort by
# family and then in learning order. The basic alphabet file fills two
# subdecks and is numbered 1-2.
class DeckFilenamesTest < Minitest::Test
  def generators = ObjectSpace.each_object(Class).select { |c| c < Generators::Base }

  def family_slug(deck)
    deck.split("::").first.sub(/\A\S*\s*/, "").sub(/\ASanskrit /, "").downcase.tr(" ", "_")
  end

  def test_every_filename_names_its_family_and_subdeck_number
    refute_empty generators
    generators.each do |g|
      deck = g.new([], {}).deck
      file = g::OUTPUT_TXT
      prefix = "sanskrit_#{family_slug(deck)}_"
      number = deck.split("::")[1]&.to_i
      prefix += "#{number}_" if number
      prefix = "sanskrit_alphabet_1-2_" if g == Generators::Basic
      assert file.start_with?(prefix), "#{g}: #{file} should start with #{prefix} (deck #{deck})"
      assert file.end_with?("_anki.txt"), file
    end
  end

  def test_filenames_are_unique
    files = generators.map { |g| g::OUTPUT_TXT }
    assert_equal files.size, files.uniq.size
  end
end
