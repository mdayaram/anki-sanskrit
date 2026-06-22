# frozen_string_literal: true

# Gating QA over data/vedanta.json (methods A structural + B round-trip).
# Run: ruby bootstrap/qa_vedanta.rb   (exit 0 = clean)
require "json"
require_relative "../lib/iast_devanagari"
require_relative "../lib/paths"

data = JSON.parse(File.read(Paths.data("vedanta.json")))
fail_count = 0
report = lambda do |label, bad|
  next if bad.empty?

  puts "FAIL #{label}: #{bad.size}"
  bad.first(15).each { |b| puts "  #{b}" }
  fail_count += bad.size
end

iast_ok = /\A[a-zāīūṛṝḷḹṅñṭḍṇśṣṃḥ'\- ]+\z/
dev_ok  = /\A[ऀ-ॿ \-]+\z/
# Undecoded source glyphs from the extractor's DECODE map. ñ is excluded — it is a
# valid IAST character and a value the decode map produces (from raw ï).
legacy_chars = /[äéüùïçëåöàìò]/

report.("empty fields", data.select { |e| [e["iast"], e["devanagari"], e["definition"]].any? { |v| v.to_s.strip.empty? } }.map { |e| e["iast"] })
report.("iast charset", data.reject { |e| e["iast"] =~ iast_ok }.map { |e| e["iast"] })
report.("devanagari charset", data.reject { |e| e["devanagari"] =~ dev_ok }.map { |e| "#{e['iast']} -> #{e['devanagari']}" })
report.("legacy glyph in iast/definition", data.select { |e| (e["iast"] + e["definition"]) =~ legacy_chars }.map { |e| e["iast"] })
report.("unexpanded abbreviation", data.select { |e| e["definition"] =~ /\b(comp|ind|lit)\.\s|\bnom\. sing\.|\bp\.p\.p\./ }.map { |e| e["iast"] })

dups = data.group_by { |e| e["iast"] }.select { |_k, v| v.size > 1 }.keys
report.("duplicate iast keys", dups)

# B. Round-trip: to_iast(devanagari) == iast
rt = data.reject { |e| IastDevanagari.to_iast(e["devanagari"]) == e["iast"] }
         .map { |e| "#{e['iast']} -> #{e['devanagari']} -> #{IastDevanagari.to_iast(e['devanagari'])}" }
report.("round-trip mismatch", rt)

puts "entries: #{data.size}"
if fail_count.zero?
  puts "QA A+B CLEAN"
else
  puts "QA A+B FAILURES: #{fail_count}"
  exit 1
end
