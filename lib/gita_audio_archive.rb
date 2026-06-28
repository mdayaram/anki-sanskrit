# frozen_string_literal: true

require "open-uri"
require "fileutils"
require "tmpdir"
require_relative "paths"

# Transparent download of the Bhagavad Gita recitation audio.
#
# The 640 Gita mp3s (~289 MB) are too large to commit, so they live as a single
# tar.gz attached to a GitHub release. main.rb calls `ensure_present!` from the
# audio-copy step, so `./main.rb --gita-verses` pulls the audio automatically the
# first time you copy it into Anki — no separate fetch_gita.rb run needed.
#
# tar.gz (not zip) because main.rb is standard-library-only — Ruby ships no zip
# reader, and `tar` is the one extractor present by default on macOS, Linux, and
# Windows 10+. To re-cut the archive after changing the audio source, see
# CLAUDE.md ("The Bhagavad Gita verse deck").
module GitaAudioArchive
  # Release asset holding the tar.gz (root entry is `gita_audio/`, so it extracts
  # straight into data/). Bump the tag (…-v2) and re-upload if the audio changes.
  URL = "https://github.com/mdayaram/anki-sanskrit/releases/download/" \
        "gita-audio-v1/gita_audio.tar.gz"

  UA = "Mozilla/5.0 (compatible; anki-sanskrit/1.0)"

  # Download the archive and extract it into data/gita_audio/. Returns true on
  # success. On any failure it prints how to fall back to `ruby fetch_gita.rb`
  # and returns false rather than raising, so a copy attempt degrades gracefully.
  def self.ensure_present!
    FileUtils.mkdir_p(Paths::GITA_AUDIO_DIR)

    Dir.mktmpdir("gita-audio") do |tmp|
      archive = File.join(tmp, "gita_audio.tar.gz")
      puts "  Gita audio not found locally — downloading from GitHub release..."
      return false unless download(URL, archive)
      return false unless extract(archive, Paths::DATA_DIR)
    end

    true
  end

  # Stream the URL to `dest`, printing a percentage as it goes. The progress
  # callback fires constantly, so only redraw when the reported value changes.
  def self.download(url, dest)
    total = nil
    last = nil
    URI.parse(url).open(
      "User-Agent" => UA,
      content_length_proc: ->(len) { total = len },
      progress_proc: lambda do |bytes|
        shown = total&.positive? ? "#{(100.0 * bytes / total).round}% (#{bytes / 1_000_000} MB)" : "#{bytes / 1_000_000} MB"
        next if shown == last

        last = shown
        print "\r  downloaded #{shown}"
      end
    ) { |io| IO.copy_stream(io, dest) }
    puts ""
    true
  rescue OpenURI::HTTPError, SocketError, OpenSSL::SSL::SSLError => e
    puts ""
    warn "  Could not download Gita audio (#{e.message})."
    warn "  Run `ruby fetch_gita.rb` to build data/gita_audio/ from the original source instead."
    false
  end

  # Extract the tar.gz into `into` by shelling out to `tar` (libarchive/bsdtar on
  # macOS+Windows, GNU tar on Linux — all read gzip tar).
  def self.extract(archive, into)
    if system("tar", "-xzf", archive, "-C", into)
      true
    else
      warn "  Could not extract Gita audio (is `tar` installed?)."
      warn "  Run `ruby fetch_gita.rb` to build data/gita_audio/ from the original source instead."
      false
    end
  end
end
