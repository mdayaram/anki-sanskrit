# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../lib/iast_devanagari"
require_relative "../lib/paths"

# Integrity check on the curated source of truth: every stored (iast, devanagari)
# pair in data/vedanta.json must be a valid spelling of its IAST. Validity allows
# either the anusvara or the explicit-conjunct spelling of a homorganic cluster
# (see IastDevanagari.valid_pair?).
class VedantaDataTest < Minitest::Test
  def entries
    @entries ||= JSON.parse(File.read(Paths.data("vedanta.json")))
  end

  def test_every_pair_is_valid
    invalid = entries.reject { |e| IastDevanagari.valid_pair?(e["iast"], e["devanagari"]) }
                     .map { |e| "#{e['iast']} -> #{e['devanagari']} (reads as #{IastDevanagari.to_iast(e['devanagari'])})" }
    assert_empty invalid, "invalid iast/devanagari pairs:\n#{invalid.join("\n")}"
  end
end
