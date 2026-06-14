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

# Anki keeps media at <base>/<profile>/collection.media. The base differs by
# platform (see https://docs.ankiweb.net/files.html); the default profile is
# "User 1". Return every collection.media folder found across the standard
# locations. Set ANKI_MEDIA_DIR to a full collection.media path to override.
def find_media_dirs
  return [ENV["ANKI_MEDIA_DIR"]] if ENV["ANKI_MEDIA_DIR"]

  home = Dir.home
  bases = [
    File.join(home, "Library", "Application Support", "Anki2"),       # macOS
    (ENV["APPDATA"] && File.join(ENV["APPDATA"], "Anki2")),           # Windows
    (ENV["XDG_DATA_HOME"] && File.join(ENV["XDG_DATA_HOME"], "Anki2")), # Linux (custom)
    File.join(home, ".local", "share", "Anki2"),                      # Linux
    File.join(home, ".var", "app", "net.ankiweb.Anki", "data", "Anki2") # Linux (Flatpak)
  ].compact

  bases.flat_map { |base| Dir.glob(File.join(base, "*", "collection.media")) }
       .select { |dir| File.directory?(dir) }
end

# Prefer Anki's default "User 1" profile when several profiles exist.
def choose_media_dir(dirs)
  dirs.find { |d| File.basename(File.dirname(d)) == "User 1" } || dirs.first
end

def copy_audio
  media_dirs = find_media_dirs

  if media_dirs.empty?
    puts ""
    puts "Could not find an Anki media folder in the standard locations."
    puts "Copy #{AUDIO_DIR}/*.mp3 into your profile's collection.media folder yourself,"
    puts "or set ANKI_MEDIA_DIR to its full path and re-run."
    return false
  end

  target = choose_media_dir(media_dirs)
  puts ""
  if media_dirs.size > 1
    puts "Found multiple Anki media folders:"
    media_dirs.each { |d| puts "  #{d}#{d == target ? "   <- will use" : ""}" }
    puts "(set ANKI_MEDIA_DIR to pick a different one)"
  else
    puts "Found Anki media folder:"
    puts "  #{target}"
  end
  puts ""
  print "Copy audio files there now? [Y/n] "
  answer = $stdin.gets.to_s.strip

  unless answer.empty? || answer.downcase.start_with?("y")
    puts "  Skipped. Before importing, copy #{AUDIO_DIR}/*.mp3 to:"
    puts "    #{target}/"
    return false
  end

  copied = 0
  Dir.glob(File.join(AUDIO_DIR, "*.mp3")).each do |src|
    FileUtils.cp(src, File.join(target, File.basename(src)))
    copied += 1
  end
  puts "  Copied #{copied} audio files to #{target}"
  true
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
