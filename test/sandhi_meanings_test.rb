# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../lib/paths"
require_relative "../lib/sandhi_meanings"
%w[vowel_sandhi vowel_sandhi_split visarga_sandhi visarga_sandhi_split
   external_consonant_sandhi external_consonant_sandhi_split
   internal_consonant_sandhi internal_consonant_sandhi_split].each do |name|
  require_relative "../lib/generators/#{name}"
end

# Every sandhi deck shows the meaning of each part and of the whole. The glosses
# are curated in the four data files; this checks they are present and safe to
# render, and that all eight generators (forward + splitting) put them on the back.
class SandhiMeaningsTest < Minitest::Test
  DATA_FILES = %w[vowel_sandhi visarga_sandhi external_consonant_sandhi internal_consonant_sandhi].freeze

  GENERATORS = [
    Generators::VowelSandhi, Generators::VowelSandhiSplit,
    Generators::VisargaSandhi, Generators::VisargaSandhiSplit,
    Generators::ExternalConsonantSandhi, Generators::ExternalConsonantSandhiSplit,
    Generators::InternalConsonantSandhi, Generators::InternalConsonantSandhiSplit
  ].freeze

  def records(name) = JSON.parse(File.read(Paths.data("#{name}.json")))

  def test_every_record_has_all_three_meanings
    DATA_FILES.each do |name|
      records(name).each do |e|
        SandhiMeanings::FIELDS.each do |field|
          value = e[field]
          label = "#{name}: #{e['word1_iast']} + #{e['word2_iast']} #{field}"
          assert_kind_of String, value, label
          refute_empty value.strip, label
          # An ASCII double quote could open a quoted TSV field; tabs/newlines and
          # markup would break the card. Use curly or single quotes instead.
          refute_match(/["\t\n<>]/, value, label)
        end
      end
    end
  end

  def test_forward_gloss_reads_parts_then_whole
    entry = { "word1_iast" => "deva", "word1_meaning" => "god",
              "word2_iast" => "ālaya", "word2_meaning" => "abode",
              "combined_meaning" => "temple" }
    html = SandhiMeanings.html(entry, "devālaya")
    assert_equal "<br><br><small><i>deva</i> “god” + <i>ālaya</i> “abode”" \
                 "<br>→ <i>devālaya</i> “temple”</small>", html
  end

  def test_split_gloss_reads_whole_then_parts
    entry = { "word1_iast" => "deva", "word1_meaning" => "god",
              "word2_iast" => "ālaya", "word2_meaning" => "abode",
              "combined_meaning" => "temple" }
    html = SandhiMeanings.html(entry, "devālaya", split: true)
    assert_match(/<i>devālaya<\/i> “temple”<br>→ <i>deva<\/i>/, html)
  end

  def test_every_generator_renders_the_meanings_on_the_back
    GENERATORS.each do |klass|
      gen = klass.new([], {})
      gen.build.each do |entry|
        _key, front, back = gen.card(entry)
        %w[word1_meaning word2_meaning combined_meaning].each do |field|
          assert_includes back, "“#{entry[field]}”", "#{klass}: #{entry['word1_iast']} #{field}"
          # The front is the prompt — the meanings would give the answer away.
          refute_includes front, "“#{entry[field]}”", "#{klass}: front leaks #{field}"
        end
      end
    end
  end
end
