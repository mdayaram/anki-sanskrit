# frozen_string_literal: true

# Merges the 701 per-verse gita/gita records into bhagavadgita.com's canonical
# verse groups (one card per group). The grouping is hardcoded in
# GITA_VERSE_GROUPS — 49 [chapter, start, end] ranges discovered once from
# bhagavadgita.com (every grouped verse's page maps to a single combined JKYog
# audio clip, e.g. verses 1.4/1.5/1.6 all -> 001_004-006.mp3). Verified: these
# ranges cover exactly the 110 grouped verses with no gaps or overlaps; every
# other verse is its own single card.
#
# Pure transform — no IO. fetch_gita.rb calls this and then downloads one JKYog
# clip per card by the deterministic audio URL.
module GitaGroups
  GITA_VERSE_GROUPS = [
    [1, 4, 6], [1, 16, 18], [1, 21, 22], [1, 29, 31], [1, 32, 33], [1, 34, 35],
    [1, 36, 37], [1, 38, 39], [1, 45, 46], [2, 42, 43], [3, 1, 2], [3, 20, 21],
    [4, 29, 30], [5, 8, 9], [5, 27, 28], [6, 12, 13], [6, 24, 25], [6, 41, 42],
    [8, 1, 2], [8, 9, 10], [8, 23, 26], [9, 7, 8], [9, 16, 17], [10, 4, 5],
    [10, 12, 13], [10, 16, 17], [11, 10, 11], [11, 26, 27], [11, 28, 29],
    [11, 41, 42], [11, 52, 53], [12, 3, 4], [12, 6, 7], [12, 13, 14],
    [12, 18, 19], [13, 8, 12], [14, 3, 4], [14, 11, 13], [14, 14, 15],
    [14, 22, 23], [14, 24, 25], [15, 3, 4], [16, 1, 3], [16, 13, 15],
    [16, 19, 20], [17, 5, 6], [17, 26, 27], [18, 15, 16], [18, 51, 53]
  ].freeze

  module_function

  def build(per_verse)
    by_cv = per_verse.to_h { |r| [[r["chapter"], r["verse"]], r] }

    # (chapter, verse) -> [chapter, start, end] for grouped verses.
    group_of = {}
    GITA_VERSE_GROUPS.each do |ch, s, e|
      (s..e).each { |v| group_of[[ch, v]] = [ch, s, e] }
    end

    emitted = {}
    cards = []
    per_verse.each do |r|
      key = [r["chapter"], r["verse"]]
      group = group_of[key]
      if group
        next if emitted[group]

        emitted[group] = true
        ch, s, e = group
        members = (s..e).map { |v| by_cv[[ch, v]] }
        cards << merge_group(ch, s, e, members)
      else
        cards << single(r)
      end
    end
    cards
  end

  def single(r)
    {
      "chapter" => r["chapter"],
      "verse_label" => r["verse"].to_s,
      "verses" => [r["verse"]],
      "devanagari" => r["devanagari"],
      "transliteration" => r["transliteration"],
      "translations" => {
        "literal" => r.dig("translations", "literal"),
        "devotional" => r.dig("translations", "devotional")
      },
      "word_meanings" => [r["word_meanings"]],
      "audio_file" => "gita_#{r['chapter']}_#{r['verse']}.mp3"
    }
  end

  def merge_group(chapter, start, finish, members)
    {
      "chapter" => chapter,
      "verse_label" => "#{start}-#{finish}",
      "verses" => (start..finish).to_a,
      "devanagari" => members.map { |m| m["devanagari"] }.join("\n\n"),
      "transliteration" => members.map { |m| m["transliteration"] }.join("\n"),
      "translations" => {
        "literal" => members.map { |m| m.dig("translations", "literal").to_s }.join(" "),
        "devotional" => members.map { |m| m.dig("translations", "devotional").to_s }.join(" ")
      },
      "word_meanings" => members.map { |m| m["word_meanings"] },
      "audio_file" => "gita_#{chapter}_#{start}-#{finish}.mp3"
    }
  end
end
