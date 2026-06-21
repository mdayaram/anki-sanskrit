# frozen_string_literal: true

# Pure transform from the raw gita/gita upstream JSON into the slim per-verse
# records written to data/gita.json. No IO — fetch_gita.rb handles downloads and
# file writing and calls this. Translations are matched to verses by verse_id and
# filtered to the two named English authors (one literal, one devotional).
module GitaDataset
  module_function

  def build(verses, translations, literal_author:, devotional_author:)
    by_verse = Hash.new { |h, k| h[k] = {} }
    translations.each do |t|
      next unless t["lang"] == "english"

      by_verse[t["verse_id"]][t["authorName"]] = t["description"]
    end

    verses.map do |v|
      chapter = v["chapter_number"]
      verse   = v["verse_number"]
      authors = by_verse[v["id"]]

      {
        "chapter"         => chapter,
        "verse"           => verse,
        "devanagari"      => v["text"],
        "transliteration" => v["transliteration"],
        "word_meanings"   => v["word_meanings"],
        "translations"    => {
          "literal"    => authors[literal_author],
          "devotional" => authors[devotional_author]
        },
        "audio_file"      => "gita_#{chapter}_#{verse}.mp3"
      }
    end
  end
end
