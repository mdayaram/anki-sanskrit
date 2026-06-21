#!/usr/bin/env ruby
# frozen_string_literal: true

# Standalone networked fetch for the Bhagavad Gita verse deck. Downloads the
# gita/gita dataset (verses, English translations, chapter metadata) and the
# per-verse recitation MP3s, then writes data/gita.json + data/gita_audio/*.mp3.
#
# Like scrape_sanskrit.rb, this is the only networked step for its deck and is
# kept out of main.rb. The generator (lib/generators/gita_verses.rb) is a pure
# transform over data/gita.json. Re-running skips MP3s already on disk.
#
# Usage: ruby fetch_gita.rb

require "json"
require "fileutils"
require "open-uri"
require_relative "lib/paths"
require_relative "lib/gita_dataset"

RAW                = "https://raw.githubusercontent.com/gita/gita/main/data"
LITERAL_AUTHOR     = "Swami Gambirananda"
DEVOTIONAL_AUTHOR  = "Swami Sivananda"

def fetch_json(name)
  url = "#{RAW}/#{name}"
  puts "Fetching #{url} ..."
  JSON.parse(URI.parse(url).open(&:read))
end

verses       = fetch_json("verse.json")
translations = fetch_json("translation.json")
chapters     = fetch_json("chapters.json")

records = GitaDataset.build(
  verses, translations,
  literal_author: LITERAL_AUTHOR, devotional_author: DEVOTIONAL_AUTHOR
)
records.sort_by! { |r| [r["chapter"], r["verse"]] }

# Validate translation coverage before touching the network for audio.
missing = records.reject { |r| r["translations"]["literal"] && r["translations"]["devotional"] }
unless missing.empty?
  warn "ERROR: #{missing.size} verses are missing a literal or devotional translation."
  warn "First few: #{missing.first(5).map { |r| "#{r['chapter']}.#{r['verse']}" }.join(', ')}"
  abort "Check that LITERAL_AUTHOR/DEVOTIONAL_AUTHOR match authors present in translation.json."
end

# Validate per-chapter verse counts against chapters.json.
expected = chapters.to_h { |c| [c["chapter_number"], c["verses_count"]] }
actual   = records.group_by { |r| r["chapter"] }.transform_values(&:size)
expected.each do |chapter, count|
  got = actual[chapter] || 0
  warn "WARNING: chapter #{chapter}: expected #{count} verses, built #{got}" unless got == count
end

# Download recitation audio (skip files already present).
FileUtils.mkdir_p(Paths::GITA_AUDIO_DIR)
downloaded = 0
failed = []
records.each do |r|
  dest = File.join(Paths::GITA_AUDIO_DIR, r["audio_file"])
  next if File.exist?(dest) && File.size(dest).positive?

  url = "#{RAW}/verse_recitation/#{r['chapter']}/#{r['verse']}.mp3"
  begin
    data = URI.parse(url).open(&:read)
    File.binwrite(dest, data)
    downloaded += 1
    print "\r  downloaded #{downloaded} audio files ..."
  rescue OpenURI::HTTPError => e
    failed << "#{r['chapter']}.#{r['verse']} (#{e.message})"
  end
  sleep 0.1
end
puts ""
warn "WARNING: #{failed.size} audio files failed: #{failed.first(5).join(', ')}" unless failed.empty?

File.write(Paths::GITA_JSON, JSON.pretty_generate(records))

present_audio = records.count { |r| File.exist?(File.join(Paths::GITA_AUDIO_DIR, r["audio_file"])) }
puts ""
puts "Wrote #{records.size} verses to #{Paths::GITA_JSON}"
puts "Audio present: #{present_audio}/#{records.size} in #{Paths::GITA_AUDIO_DIR}"
puts "Next: ./main.rb --gita-verses"
