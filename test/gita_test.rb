# frozen_string_literal: true

require "minitest/autorun"
require "tempfile"
require_relative "../lib/gita"

class GitaTest < Minitest::Test
  def test_load_parses_json_from_given_path
    file = Tempfile.new(["gita", ".json"])
    file.write('[{"chapter":1,"verse":1,"audio_file":"gita_1_1.mp3"}]')
    file.flush
    data = Gita.load(file.path)
    assert_equal 1, data.size
    assert_equal "gita_1_1.mp3", data.first["audio_file"]
  end
end
