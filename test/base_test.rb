# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/base"

class BaseTest < Minitest::Test
  class FakeGen < Generators::Base
    KEY         = "fake"
    DESCRIPTION = "fake"
    OUTPUT_TXT  = "fake_test_output.txt"

    def self.requires_letters? = false
    def deck = "Fake Deck"
    def audio_dir = "/tmp/fake_audio"
    def build = [{ "n" => 1 }]
    def card(entry) = ["k#{entry['n']}", "front", "back"]
    def audio_files(_data) = ["x.mp3"]
  end

  def test_base_requires_letters_by_default
    assert Generators::Base.requires_letters?
  end

  def test_subclass_can_opt_out_of_letters
    refute FakeGen.requires_letters?
  end

  def test_run_reports_deck_and_audio_dir
    result = FakeGen.new([], {}).run
    assert_equal "Fake Deck", result[:deck]
    assert_equal "/tmp/fake_audio", result[:audio_dir]
    assert_equal ["x.mp3"], result[:audio_files]
    assert_includes File.read(result[:txt]), "#deck:Fake Deck"
  ensure
    File.delete(Paths.output("fake_test_output.txt")) if File.exist?(Paths.output("fake_test_output.txt"))
  end
end
