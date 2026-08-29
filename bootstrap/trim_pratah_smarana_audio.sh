#!/bin/sh
# How pratah_smarana.mp3 in data/mantra_audio/ was cut from its source.
#
# Not part of the runtime: mantra clips are committed, so ./main.rb --mantras
# never downloads or re-encodes anything. This records the derivation so the
# clip can be reproduced. The source URL and the trim are also stored in
# data/mantras.json (audio_source).
#
# Unlike trim_mantra_audio.sh (curl + afconvert, deliberately no ffmpeg — see
# that script), the source here is a YouTube video, not a direct file, so this
# one needs yt-dlp, which in turn shells out to ffmpeg to extract/decode audio.
# The cut/fade/encode step still uses the same ffmpeg-free python3 + lame as
# the other clip.
#
# pratah_smarana.mp3 — Swami Tadatmananda, Arsha Bodha Center (YouTube,
# chanted in Raga Bhairav). The ~233.65 s source is essentially one continuous
# take of all three verses with no clean inter-verse silence (only a single
# breath pause around 88 s, well short of -25dB); it already fades in/out
# naturally at both ends, so the trim keeps nearly the whole file (0.0 -> 233.60
# s) and only adds a short fade on top to avoid a hard cut.
set -eu

URL='https://www.youtube.com/watch?v=cqPlGaHQUNQ'
DIR=$(mktemp -d)
trap 'rm -rf "$DIR"' EXIT

yt-dlp -x --audio-format wav -o "$DIR/source.%(ext)s" "$URL"
#                                            in                 out          start end    fade-in fade-out
python3 "$(dirname "$0")/trim_mantra_audio.py" "$DIR/source.wav" "$DIR/cut.wav" 0.0 233.60 0.05 0.50
lame --quiet -b 160 -h "$DIR/cut.wav" data/mantra_audio/pratah_smarana.mp3   # 160 kbps CBR matches the ~153 kbps Opus source
