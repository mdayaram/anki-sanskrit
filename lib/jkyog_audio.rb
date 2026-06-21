# frozen_string_literal: true

# JKYog (Swami Mukundananda) Bhagavad Gita recitation audio — clearer and higher
# quality (320 kbps) than the gita/gita repo's own verse_recitation files, and
# the source bhagavadgita.com uses.
#
# Single verses live at <chapter3>_<verse3>.mp3 (e.g. 002_047.mp3). Verses that
# Mukundananda's edition groups share one combined "range" file (e.g.
# 001_004-006.mp3). Which verses are grouped is captured in
# GitaGroups::GITA_VERSE_GROUPS, so both URLs are deterministic — no scraping at
# fetch time.
module JkyogAudio
  BASE = "https://gita-audio.jkyog.org/audio/sanskrit/gita_audios"

  module_function

  # Audio URL for a single (non-grouped) verse.
  def naive_url(chapter, verse)
    format("%s/%03d_%03d.mp3", BASE, chapter, verse)
  end

  # Audio URL for a grouped verse range (start..finish in one chapter).
  def range_url(chapter, start, finish)
    format("%s/%03d_%03d-%03d.mp3", BASE, chapter, start, finish)
  end
end
