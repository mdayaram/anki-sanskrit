# frozen_string_literal: true

# One-time, DISPOSABLE: bootstrap/vedanta_raw.json -> data/vedanta.json, adding
# the Devanagari column via the committed transliterator. data/vedanta.json is
# the source of truth afterward; re-run only to regenerate from a corrected
# extractor. Run: ruby bootstrap/build_vedanta.rb
require "json"
require_relative "../lib/iast_devanagari"
require_relative "../lib/paths"

raw = JSON.parse(File.read(File.join(__dir__, "vedanta_raw.json")))
out = raw.map do |e|
  {
    "iast" => e["iast"],
    "devanagari" => IastDevanagari.to_devanagari(e["iast"]),
    "definition" => e["definition"]
  }
end
File.write(Paths.data("vedanta.json"), JSON.pretty_generate(out))
puts "Wrote #{out.size} entries to #{Paths.data('vedanta.json')}"
puts "sample: #{out.first(3).map { |e| "#{e['iast']}=#{e['devanagari']}" }.join('  ')}"
