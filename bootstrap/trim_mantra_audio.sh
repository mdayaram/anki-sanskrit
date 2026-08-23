#!/bin/sh
# How a mantra recitation in data/mantra_audio/ was cut from its source.
#
# Not part of the runtime: mantra clips are committed, so ./main.rb --mantras
# never downloads or re-encodes anything. This records the derivation so a clip
# can be reproduced or a new mantra's audio cut the same way. The source URL and
# the trim used for each clip are stored in data/mantras.json (audio_source).
#
# Needs only what macOS ships (afconvert, python3) plus lame for the mp3 encode;
# deliberately no ffmpeg, which is not reliably installed.
#
# gayatri.mp3 — Shri Rattan Mohan Sharma, via the Internet Archive. The source is
# three passes of the mantra over a continuous drone (its envelope autocorrelates
# at 24.3 s, with vocal attacks at 3.44 / 27.74 / 52.0 s), so one invocation is
# 3.10 -> 27.73 s. The drone is still sounding at the cut, hence the fade-out.
set -eu

URL='https://archive.org/download/shri-rattan-mohan-sharma-gayatri-mantra/Shri%20Rattan%20Mohan%20Sharma%20%E2%80%94%20Gayatri%20Mantra.mp3'
DIR=$(mktemp -d)
trap 'rm -rf "$DIR"' EXIT

curl -sL -o "$DIR/source.mp3" "$URL"
afconvert -f WAVE -d LEI16 "$DIR/source.mp3" "$DIR/full.wav"
#                                            in            out          start end   fade-in fade-out
python3 "$(dirname "$0")/trim_mantra_audio.py" "$DIR/full.wav" "$DIR/cut.wav" 3.10 27.73 0.15 0.50
lame --quiet -b 192 -h "$DIR/cut.wav" data/mantra_audio/gayatri.mp3   # 192 kbps CBR matches the source
