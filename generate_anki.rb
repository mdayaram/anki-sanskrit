#!/usr/bin/env ruby
# frozen_string_literal: true

# Script 2: Generate Anki flashcards from scraped Sanskrit alphabet data
#
# Reads data/letters.json and produces a tab-separated file for Anki import.
# Optionally copies audio files into your Anki collection.media folder.
#
# Usage:
#   bundle exec ruby generate_anki.rb
#
# Card layout:
#   Front: Devanagari character (large) + audio
#   Back:  Romanization + audio + properties + pronunciation tips

require "json"
require "fileutils"

DATA_DIR       = File.join(__dir__, "data")
AUDIO_DIR      = File.join(DATA_DIR, "audio")
LETTERS_JSON   = File.join(DATA_DIR, "letters.json")
OUTPUT_FILE    = File.join(__dir__, "sanskrit_anki.txt")
ANKI_MEDIA_DIR = "/Users/noj/Library/Application Support/Anki2/User 1/collection.media"

def clean_tips_html(html)
  return "" if html.nil? || html.strip.empty?

  text = html.dup
  # Normalize line breaks in source to nothing (they're not meaningful)
  text.gsub!(/\r\n/, "")
  text.gsub!(/\n/, "")
  # Convert styled spans to bold/italic for Anki
  text.gsub!(/<span[^>]*class="coloredletter1"[^>]*>([^<]*)<\/span>/, '<b>\1</b>')
  text.gsub!(/<span[^>]*class="coloredletter2"[^>]*>([^<]*)<\/span>/, '<i>\1</i>')
  text.gsub!(/<span[^>]*class="tipsmallfont"[^>]*>([^<]*)<\/span>/, '<small>\1</small>')
  # Strip any remaining spans
  text.gsub!(/<\/?span[^>]*>/, "")
  text.strip
end

def generate_cards(letters)
  puts "Generating #{OUTPUT_FILE}..."
  count = 0

  File.open(OUTPUT_FILE, "w:UTF-8") do |f|
    f.puts "#separator:Tab"
    f.puts "#html:true"
    f.puts "#deck:🕉️ Sanskrit Alphabet"
    f.puts "#notetype:Basic"
    f.puts "#columns:Key\tFront\tBack"
    f.puts "#guid column:1"

    letters.each do |letter|
      devan      = letter["devanagari"]
      roman      = letter["roman"]
      audio_file = letter["audio_file"]
      properties = letter["properties"] || []
      tips_html  = letter["pronunciation_tips_html"] || ""

      sound_tag = "[sound:#{audio_file}]"

      # --- Front ---
      # Avoid inline styles (contain semicolons which conflict with the CSV separator).
      # Use basic HTML tags instead.
      front = "<center><big><big><big><big><big>#{devan}</big></big></big></big></big></center>"

      # --- Back ---
      back_parts = []
      back_parts << "<center><big><big><b>#{roman}</b></big></big><br>#{sound_tag}</center>"

      unless properties.empty?
        props_html = properties.map { |p| "<li>#{p}</li>" }.join("")
        back_parts << "<hr><b>Properties</b><ul>#{props_html}</ul>"
      end

      cleaned_tips = clean_tips_html(tips_html)
      unless cleaned_tips.empty?
        back_parts << "<hr><b>Pronunciation</b><br>#{cleaned_tips}"
      end

      back = back_parts.join("")

      key = roman.gsub("\t", " ")
      f.puts "#{key}\t#{front.gsub("\t", " ")}\t#{back.gsub("\t", " ")}"
      count += 1
    end
  end

  puts "  Created #{count} cards in #{OUTPUT_FILE}"
end

def copy_audio
  puts ""
  puts "Audio files need to be in your Anki media folder:"
  puts "  #{ANKI_MEDIA_DIR}"
  puts ""
  print "Copy audio files there now? [Y/n] "
  answer = $stdin.gets.strip

  if answer.empty? || answer.downcase.start_with?("y")
    unless Dir.exist?(ANKI_MEDIA_DIR)
      puts "  ERROR: Anki media directory not found at:"
      puts "    #{ANKI_MEDIA_DIR}"
      puts "  Make sure Anki is installed and the profile exists."
      return false
    end

    copied = 0
    Dir.glob(File.join(AUDIO_DIR, "*.mp3")).each do |src|
      dest = File.join(ANKI_MEDIA_DIR, File.basename(src))
      FileUtils.cp(src, dest)
      copied += 1
    end
    puts "  Copied #{copied} audio files."
    true
  else
    puts "  Skipped. Before importing, manually copy files from:"
    puts "    #{AUDIO_DIR}/"
    puts "  to:"
    puts "    #{ANKI_MEDIA_DIR}/"
    false
  end
end

# --- Main ---
puts "=== Sanskrit Alphabet Anki Generator ==="
puts

unless File.exist?(LETTERS_JSON)
  puts "ERROR: #{LETTERS_JSON} not found."
  puts "Run `bundle exec ruby scrape_sanskrit.rb` first."
  exit 1
end

letters = JSON.parse(File.read(LETTERS_JSON))
puts "Loaded #{letters.size} letters from #{LETTERS_JSON}"
puts

generate_cards(letters)
copy_audio

puts
puts "=== Done! ==="
puts
puts "To import into Anki:"
puts "  1. Open Anki"
puts "  2. File > Import"
puts "  3. Select: #{OUTPUT_FILE}"
puts "  4. Verify deck is 'Sanskrit Alphabet' and note type is 'Basic'"
puts "  5. Click Import"
