# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/gita_groups"

class GitaGroupsTest < Minitest::Test
  def verse(ch, v, suffix)
    {
      "chapter" => ch, "verse" => v,
      "devanagari" => "DEV#{suffix}",
      "transliteration" => "iast#{suffix}",
      "translations" => { "literal" => "lit#{suffix}", "devotional" => "dev#{suffix}" },
      "word_meanings" => "wm#{suffix}"
    }
  end

  # chapter 1: verse 1 (single), verses 4-6 (a real group), verse 7 (single)
  def per_verse
    [verse(1, 1, 1), verse(1, 4, 4), verse(1, 5, 5), verse(1, 6, 6), verse(1, 7, 7)]
  end

  def cards = GitaGroups.build(per_verse)

  def test_card_count
    assert_equal 3, cards.size
  end

  def test_single_verse_passthrough
    c = cards.find { |x| x["verses"] == [1] }
    assert_equal "1", c["verse_label"]
    assert_equal "DEV1", c["devanagari"]
    assert_equal "lit1", c["translations"]["literal"]
    assert_equal ["wm1"], c["word_meanings"]
    assert_equal "gita_1_1.mp3", c["audio_file"]
  end

  def test_group_merge
    c = cards.find { |x| x["verse_label"] == "4-6" }
    assert_equal [4, 5, 6], c["verses"]
    assert_equal "DEV4\n\nDEV5\n\nDEV6", c["devanagari"]
    assert_equal "iast4\niast5\niast6", c["transliteration"]
    assert_equal "lit4 lit5 lit6", c["translations"]["literal"]
    assert_equal "dev4 dev5 dev6", c["translations"]["devotional"]
    assert_equal %w[wm4 wm5 wm6], c["word_meanings"]
    assert_equal "gita_1_4-6.mp3", c["audio_file"]
  end

  def test_order_preserved
    assert_equal [[1], [4, 5, 6], [7]], cards.map { |c| c["verses"] }
  end

  def test_groups_constant_is_well_formed
    g = GitaGroups::GITA_VERSE_GROUPS
    assert_equal 49, g.size
    covered = g.flat_map { |ch, s, e| (s..e).map { |v| [ch, v] } }
    assert_equal 110, covered.size
    assert_equal 110, covered.uniq.size, "groups must not overlap"
    assert(g.all? { |_ch, s, e| e >= s }, "every range must be non-empty")
  end
end
