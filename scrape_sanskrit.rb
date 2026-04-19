#!/usr/bin/env ruby
# frozen_string_literal: true

# Script 1: Scrape and download Sanskrit alphabet data
#
# Fetches letter data from https://enjoylearningsanskrit.com/sanskrit-alphabet-tutor/
# and saves everything locally:
#   data/letters.json  - all letter metadata (Devanagari, romanization, properties, tips)
#   data/audio/         - downloaded .mp3 pronunciation files
#
# Usage:
#   bundle install
#   bundle exec ruby scrape_sanskrit.rb

require "bundler/setup"
require "nokogiri"
require "open-uri"
require "json"
require "fileutils"

SITE_URL = "https://enjoylearningsanskrit.com/sanskrit-alphabet-tutor/"
AUDIO_BASE = "https://sanskritserver.kautukam.com/sanskritserver/mp3/"
DATA_DIR = File.join(__dir__, "data")
AUDIO_DIR = File.join(DATA_DIR, "audio")

# All letter IDs in traditional Sanskrit alphabet order
ALL_LETTERS = %w[
  a aa i ii u uu RRi RRI LLi e ai o au aM aH
  ka kha ga gha GNa
  ca cha ja jha JNa
  Ta Tha Da Dha Na
  ta tha da dha na
  pa pha ba bha ma
  ya ra la va
  sha Sha sa ha
  kSha jJNa
].freeze

# Internal ID -> Devanagari character
DEVANAGARI = {
  "a" => "\u0905", "aa" => "\u0906", "i" => "\u0907", "ii" => "\u0908",
  "u" => "\u0909", "uu" => "\u090A", "RRi" => "\u090B", "RRI" => "\u0960",
  "LLi" => "\u090C", "e" => "\u090F", "ai" => "\u0910", "o" => "\u0913",
  "au" => "\u0914", "aM" => "\u0905\u0902", "aH" => "\u0905\u0903",
  "ka" => "\u0915", "kha" => "\u0916", "ga" => "\u0917", "gha" => "\u0918",
  "GNa" => "\u0919", "ca" => "\u091A", "cha" => "\u091B", "ja" => "\u091C",
  "jha" => "\u091D", "JNa" => "\u091E", "Ta" => "\u091F", "Tha" => "\u0920",
  "Da" => "\u0921", "Dha" => "\u0922", "Na" => "\u0923", "ta" => "\u0924",
  "tha" => "\u0925", "da" => "\u0926", "dha" => "\u0927", "na" => "\u0928",
  "pa" => "\u092A", "pha" => "\u092B", "ba" => "\u092C", "bha" => "\u092D",
  "ma" => "\u092E", "ya" => "\u092F", "ra" => "\u0930", "la" => "\u0932",
  "va" => "\u0935", "sha" => "\u0936", "Sha" => "\u0937", "sa" => "\u0938",
  "ha" => "\u0939", "jJNa" => "\u091C\u094D\u091E",
  "kSha" => "\u0915\u094D\u0937"
}.freeze

# Internal ID -> IAST romanized transliteration
ROMAN = {
  "a" => "a", "aa" => "\u0101", "i" => "i", "ii" => "\u012B",
  "u" => "u", "uu" => "\u016B", "RRi" => "\u1E5B", "RRI" => "\u1E5D",
  "LLi" => "\u1E37", "e" => "e", "ai" => "ai", "o" => "o",
  "au" => "au", "aM" => "a\u1E41", "aH" => "a\u1E25",
  "ka" => "ka", "kha" => "kha", "ga" => "ga", "gha" => "gha",
  "GNa" => "\u1E45a", "ca" => "ca", "cha" => "cha", "ja" => "ja",
  "jha" => "jha", "JNa" => "\u00F1a", "Ta" => "\u1E6Da", "Tha" => "\u1E6Dha",
  "Da" => "\u1E0Da", "Dha" => "\u1E0Dha", "Na" => "\u1E47a",
  "ta" => "ta", "tha" => "tha", "da" => "da", "dha" => "dha", "na" => "na",
  "pa" => "pa", "pha" => "pha", "ba" => "ba", "bha" => "bha", "ma" => "ma",
  "ya" => "ya", "ra" => "ra", "la" => "la", "va" => "va",
  "sha" => "\u015Ba", "Sha" => "\u1E63a", "sa" => "sa", "ha" => "ha",
  "jJNa" => "j\u00F1a", "kSha" => "k\u1E63a"
}.freeze

# Internal ID -> audio filename on the remote server
AUDIO_FILES = {
  "a" => "a.mp3", "aa" => "aa.mp3", "i" => "i.mp3", "ii" => "ii.mp3",
  "u" => "u.mp3", "uu" => "uu.mp3", "RRi" => "r2.mp3", "RRI" => "r3.mp3",
  "LLi" => "l2.mp3", "e" => "e.mp3", "ai" => "ai.mp3", "o" => "o.mp3",
  "au" => "au.mp3", "aM" => "aM.mp3", "aH" => "aH.mp3",
  "ka" => "k1a.mp3", "kha" => "kha.mp3", "ga" => "ga.mp3", "gha" => "gha.mp3",
  "GNa" => "GNa.mp3", "ca" => "ca.mp3", "cha" => "cha.mp3", "ja" => "ja.mp3",
  "jha" => "jha.mp3", "JNa" => "JNa.mp3", "Ta" => "t2a.mp3", "Tha" => "t2ha.mp3",
  "Da" => "d2a.mp3", "Dha" => "d2ha.mp3", "Na" => "n3a.mp3",
  "ta" => "ta.mp3", "tha" => "tha.mp3", "da" => "da.mp3", "dha" => "dha.mp3",
  "na" => "na.mp3", "pa" => "pa.mp3", "pha" => "pha.mp3", "ba" => "ba.mp3",
  "bha" => "bha.mp3", "ma" => "ma.mp3", "ya" => "ya.mp3", "ra" => "ra.mp3",
  "la" => "la.mp3", "va" => "va.mp3", "sha" => "sha.mp3", "Sha" => "s2a.mp3",
  "sa" => "sa.mp3", "ha" => "ha.mp3", "jJNa" => "jJNa.mp3", "kSha" => "kSha.mp3"
}.freeze

# Place of articulation by parent element ID
PLACE_NAMES = {
  "place1" => "Guttural (throat)",
  "place2" => "Palatal (palate)",
  "place3" => "Retroflex (roof of mouth)",
  "place4" => "Dental (teeth)",
  "place5" => "Labial (lips)"
}.freeze

def fetch_page
  puts "  Fetching #{SITE_URL}..."
  html = URI.open(SITE_URL).read
  Nokogiri::HTML(html)
end

def extract_tips(doc)
  tips = {}
  ALL_LETTERS.each do |id|
    el = doc.at_css("#tipsof_#{id}")
    tips[id] = el ? el.inner_html.strip : ""
  end
  tips
end

def build_properties(id, css_class, parent_id)
  parts = []

  # Vowels
  if css_class.match?(/short|long|guna|vriddhi|anusvara|visarga/) ||
     %w[vowels1 vowels2 amaha].include?(parent_id)
    parts << "Vowel"
    case css_class
    when /anusvara/ then parts << "Anusvara"
    when /visarga/  then parts << "Visarga"
    when /guna/     then parts << "Combined" << "Guna" << "Long"
    when /vriddhi/  then parts << "Combined" << "Vriddhi" << "Long"
    when /short/    then parts << "Simple" << "Short"
    when /long/
      parts << (parent_id == "vowels1" ? "Simple" : "Combined")
      parts << "Long"
    end
  end

  # Consonants
  if css_class.match?(/clm[1-4]|nasel|semi|sibi|clm8/)
    parts << "Consonant"
    case css_class
    when /clm1/  then parts += %w[Touch Unaspirated Unvoiced]
    when /clm2/  then parts += %w[Touch Aspirated Unvoiced]
    when /clm3/  then parts += %w[Touch Unaspirated Voiced]
    when /clm4/  then parts += %w[Touch Aspirated Voiced]
    when /nasel/ then parts += %w[Touch Nasal Unaspirated Voiced]
    when /semi/  then parts += %w[Semivowel Unaspirated Voiced]
    when /sibi/  then parts += %w[Sibilant Aspirated Unvoiced]
    when /clm8/  then parts += %w[Aspirated Voiced]
    end
  end

  # Combination letters
  parts << "Combination letter" if %w[jJNa kSha].include?(id)

  # Place of articulation
  place = PLACE_NAMES[parent_id]
  parts << place if place

  parts
end

def extract_properties(doc)
  properties = {}
  ALL_LETTERS.each do |id|
    el = doc.at_css("[id='#{id}']")
    if el
      css_class = el["class"].to_s
      parent_id = el.parent ? el.parent["id"].to_s : ""
      properties[id] = build_properties(id, css_class, parent_id)
    else
      properties[id] = []
    end
  end
  properties
end

def download_audio
  FileUtils.mkdir_p(AUDIO_DIR)
  downloaded = 0
  skipped = 0

  ALL_LETTERS.each do |id|
    filename = AUDIO_FILES[id]
    next unless filename

    # Use server filename as local name to avoid macOS case-insensitive
    # collisions (e.g. Da.mp3 vs da.mp3 would be the same file)
    local_name = filename
    local_path = File.join(AUDIO_DIR, local_name)

    if File.exist?(local_path) && File.size(local_path) > 0
      skipped += 1
      next
    end

    url = "#{AUDIO_BASE}#{filename}"
    print "  Downloading #{local_name}..."

    begin
      data = URI.open(url).read
      File.binwrite(local_path, data)
      puts " OK (#{data.bytesize} bytes)"
      downloaded += 1
    rescue OpenURI::HTTPError, SocketError => e
      puts " FAILED: #{e.message}"
    end
  end

  puts "  Audio: #{downloaded} downloaded, #{skipped} already cached"
end

def clean_tips_text(html)
  return "" if html.nil? || html.strip.empty?
  text = html.gsub(/<br\s*\/?>/, "\n")
  text = Nokogiri::HTML.fragment(text).text
  text.gsub(/\n{3,}/, "\n\n").strip
end

# --- Main ---
puts "=== Sanskrit Alphabet Scraper ==="
puts

FileUtils.mkdir_p(DATA_DIR)

puts "Step 1: Fetching page data..."
doc = fetch_page

puts "  Extracting pronunciation tips..."
tips_html = extract_tips(doc)
tips_found = tips_html.count { |_, v| !v.empty? }
puts "  Found tips for #{tips_found}/#{ALL_LETTERS.size} letters"

puts "  Extracting letter properties..."
properties = extract_properties(doc)
props_found = properties.count { |_, v| !v.empty? }
puts "  Found properties for #{props_found}/#{ALL_LETTERS.size} letters"

puts
puts "Step 2: Downloading audio files..."
download_audio

puts
puts "Step 3: Saving letter data..."

letters = ALL_LETTERS.map do |id|
  {
    id: id,
    devanagari: DEVANAGARI[id],
    roman: ROMAN[id],
    properties: properties[id] || [],
    pronunciation_tips_html: tips_html[id] || "",
    pronunciation_tips_text: clean_tips_text(tips_html[id]),
    audio_file: AUDIO_FILES[id]
  }
end

json_path = File.join(DATA_DIR, "letters.json")
File.write(json_path, JSON.pretty_generate(letters))
puts "  Saved #{letters.size} letters to #{json_path}"

puts
puts "=== Scraping complete! ==="
puts "  Data:  #{DATA_DIR}/letters.json"
puts "  Audio: #{AUDIO_DIR}/ (#{ALL_LETTERS.size} files)"
puts
puts "Next: run `bundle exec ruby generate_anki.rb` to create the Anki deck."
