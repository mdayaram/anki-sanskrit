#!/usr/bin/env ruby
# frozen_string_literal: true

# Single entry point for generating Sanskrit Anki import files.
#
# Each category is a generator under lib/generators/; they are pure transforms
# over data/letters.json (produced separately by scrape_sanskrit.rb, the only
# network step). All categories merge into one Anki deck.
#
# Usage:
#   ./main.rb --all                    # every category
#   ./main.rb --basic --combinations   # a subset (flags combine)
#   ./main.rb --list                   # list categories
#   ./main.rb --help
#
# Run `bundle exec ruby scrape_sanskrit.rb` first to fetch the source data.

require "optparse"
require_relative "lib/letters"
require_relative "lib/anki"
require_relative "lib/media"
require_relative "lib/generators/basic"
require_relative "lib/generators/combinations"
require_relative "lib/generators/conjuncts"
require_relative "lib/generators/anusvara"
require_relative "lib/generators/gita_verses"
require_relative "lib/generators/vedanta"

# Registry of every category, in run order. Each maps to a --<key> flag.
GENERATORS = [
  Generators::Basic,
  Generators::Combinations,
  Generators::Conjuncts,
  Generators::Anusvara,
  Generators::GitaVerses,
  Generators::Vedanta
].freeze

selected = []

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ./main.rb [options]\n\nGenerate Sanskrit Anki import files. Flags combine.\n\n"

  GENERATORS.each do |gen|
    opts.on("--#{gen::KEY}", gen::DESCRIPTION) { selected << gen }
  end

  opts.on("--all", "Generate every category") { selected = GENERATORS.dup }

  opts.on("--list", "List categories and exit") do
    puts "Categories:"
    GENERATORS.each { |gen| puts "  --#{gen::KEY.ljust(14)} #{gen::DESCRIPTION}" }
    exit
  end

  opts.on("-h", "--help", "Show this help") do
    puts opts
    exit
  end
end

parser.parse!(ARGV)

if selected.empty?
  warn "No category selected.\n\n"
  warn parser.help
  exit 1
end

selected = selected.uniq

puts "=== Sanskrit Anki Generator ==="
puts

needs_letters = selected.any?(&:requires_letters?)
letters = needs_letters ? Letters.load : []
letters_by_id = needs_letters ? Letters.by_id(letters) : {}
if needs_letters
  puts "Loaded #{letters.size} letters from #{Paths::LETTERS_JSON}"
  puts
end

results = selected.map do |gen|
  generator = gen.new(letters, letters_by_id)
  puts "Generating #{generator.key}..."
  result = generator.run
  puts "  #{result[:cards]} cards -> #{File.basename(result[:txt])}"
  puts "  data -> #{File.basename(result[:json])}" if result[:json]
  result
end

puts

# Categories that emitted [sound:...] tags contribute audio to copy, grouped by
# the source folder they live in (alphabet vs. Gita), so each is copied from the
# right directory. Stays data-driven — no category is hardcoded here.
results.group_by { |r| r[:audio_dir] }.each do |source_dir, group|
  files = group.flat_map { |r| r[:audio_files] }
  Media.copy_audio(files, source_dir: source_dir) # dedups and skips when empty
end

puts
puts "=== Done! ==="
puts
puts "Files written:"
results.each { |r| puts "  #{r[:txt]}" }
puts
puts "To import into Anki:"
puts "  1. Open Anki"
puts "  2. File > Import"
puts "  3. Select each file above"
puts "  4. Cards land in deck(s): #{results.map { |r| r[:deck] }.uniq.join(', ')}"
