# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/jkyog_audio"

class JkyogAudioTest < Minitest::Test
  def test_naive_url_zero_pads
    assert_equal "https://gita-audio.jkyog.org/audio/sanskrit/gita_audios/002_047.mp3",
                 JkyogAudio.naive_url(2, 47)
    assert_equal "https://gita-audio.jkyog.org/audio/sanskrit/gita_audios/018_078.mp3",
                 JkyogAudio.naive_url(18, 78)
  end

  def test_range_url_zero_pads_both_bounds
    assert_equal "https://gita-audio.jkyog.org/audio/sanskrit/gita_audios/001_004-006.mp3",
                 JkyogAudio.range_url(1, 4, 6)
    assert_equal "https://gita-audio.jkyog.org/audio/sanskrit/gita_audios/013_008-012.mp3",
                 JkyogAudio.range_url(13, 8, 12)
  end
end
