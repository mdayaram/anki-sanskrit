#!/usr/bin/env ruby
# frozen_string_literal: true

# Standalone networked fetch for the Bhagavad Gita verse deck.
#
# Text comes from the gita/gita open dataset; verses are merged into
# bhagavadgita.com's canonical groups (GitaGroups), and audio is the JKYog
# (Swami Mukundananda) recitation — one clip per card, by a deterministic URL
# (no scraping). Writes data/gita.json (group-level) + data/gita_audio/*.mp3.
#
# Like scrape_sanskrit.rb, this is the only networked step for its deck and is
# kept out of main.rb. Re-running skips MP3s already on disk; to re-download
# after changing the audio source, clear data/gita_audio/ first.
#
# Usage: ruby fetch_gita.rb

require "json"
require "fileutils"
require "open-uri"
require_relative "lib/paths"
require_relative "lib/gita_dataset"
require_relative "lib/gita_groups"
require_relative "lib/jkyog_audio"

RAW               = "https://raw.githubusercontent.com/gita/gita/main/data"
LITERAL_AUTHOR    = "Swami Gambirananda"
DEVOTIONAL_AUTHOR = "Swami Sivananda"
UA                = "Mozilla/5.0 (compatible; anki-sanskrit/1.0)"

def fetch_json(name)
  url = "#{RAW}/#{name}"
  puts "Fetching #{url} ..."
  JSON.parse(URI.parse(url).open(&:read))
end

def http_get(url)
  URI.parse(url).open("User-Agent" => UA, &:read)
rescue OpenURI::HTTPError
  nil
end

# Deterministic JKYog URL for a card: single verse -> naive, group -> range.
def audio_url_for(card)
  verses = card["verses"]
  if verses.size == 1
    JkyogAudio.naive_url(card["chapter"], verses.first)
  else
    JkyogAudio.range_url(card["chapter"], verses.first, verses.last)
  end
end

verses       = fetch_json("verse.json")
translations = fetch_json("translation.json")
chapters     = fetch_json("chapters.json")

per_verse = GitaDataset.build(
  verses, translations,
  literal_author: LITERAL_AUTHOR, devotional_author: DEVOTIONAL_AUTHOR
)
per_verse.sort_by! { |r| [r["chapter"], r["verse"]] }

cards = GitaGroups.build(per_verse)

# Validate translation coverage before touching the network for audio.
missing = cards.reject { |c| c.dig("translations", "literal") && c.dig("translations", "devotional") }
unless missing.empty?
  warn "ERROR: #{missing.size} cards missing a literal or devotional translation."
  warn "First few: #{missing.first(5).map { |c| "#{c['chapter']}.#{c['verse_label']}" }.join(', ')}"
  abort "Check LITERAL_AUTHOR/DEVOTIONAL_AUTHOR against translation.json."
end

# Validate per-chapter verse counts (sum of card verses) against chapters.json.
expected = chapters.to_h { |c| [c["chapter_number"], c["verses_count"]] }
actual   = cards.group_by { |c| c["chapter"] }.transform_values { |cs| cs.sum { |c| c["verses"].size } }
expected.each do |chapter, count|
  got = actual[chapter] || 0
  warn "WARNING: chapter #{chapter}: expected #{count} verses, built #{got}" unless got == count
end

# Download JKYog audio, one clip per card (skip files already present).
FileUtils.mkdir_p(Paths::GITA_AUDIO_DIR)
downloaded = 0
failed = []
cards.each do |card|
  dest = File.join(Paths::GITA_AUDIO_DIR, card["audio_file"])
  next if File.exist?(dest) && File.size(dest).positive?

  data = http_get(audio_url_for(card))
  if data
    File.binwrite(dest, data)
    downloaded += 1
    print "\r  downloaded #{downloaded} audio files ..."
  else
    failed << "#{card['chapter']}.#{card['verse_label']}"
  end
  sleep 0.1
end
puts ""
warn "WARNING: #{failed.size} audio downloads failed: #{failed.first(5).join(', ')}" unless failed.empty?

File.write(Paths::GITA_JSON, JSON.pretty_generate(cards))

present = cards.count { |c| File.exist?(File.join(Paths::GITA_AUDIO_DIR, c["audio_file"])) }
puts ""
puts "Wrote #{cards.size} cards to #{Paths::GITA_JSON}"
puts "Audio present: #{present}/#{cards.size} in #{Paths::GITA_AUDIO_DIR}"
puts "Next: ./main.rb --gita-verses"
