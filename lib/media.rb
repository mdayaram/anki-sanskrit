# frozen_string_literal: true

require "fileutils"
require_relative "paths"

# Copies generated audio into Anki's collection.media folder. Driven by the set
# of audio filenames the generators actually referenced via [sound:...] tags, so
# the copy step appears automatically for any future category that emits audio —
# nothing here is hardcoded to the basic alphabet deck.
module Media
  # Anki keeps media at <base>/<profile>/collection.media. The base differs by
  # platform (see https://docs.ankiweb.net/files.html); the default profile is
  # "User 1". Return every collection.media folder found across the standard
  # locations. Set ANKI_MEDIA_DIR to a full collection.media path to override.
  def self.find_media_dirs
    return [ENV["ANKI_MEDIA_DIR"]] if ENV["ANKI_MEDIA_DIR"]

    home = Dir.home
    bases = [
      File.join(home, "Library", "Application Support", "Anki2"),         # macOS
      (ENV["APPDATA"] && File.join(ENV["APPDATA"], "Anki2")),             # Windows
      (ENV["XDG_DATA_HOME"] && File.join(ENV["XDG_DATA_HOME"], "Anki2")), # Linux (custom)
      File.join(home, ".local", "share", "Anki2"),                       # Linux
      File.join(home, ".var", "app", "net.ankiweb.Anki", "data", "Anki2") # Linux (Flatpak)
    ].compact

    bases.flat_map { |base| Dir.glob(File.join(base, "*", "collection.media")) }
         .select { |dir| File.directory?(dir) }
  end

  # Prefer Anki's default "User 1" profile when several profiles exist.
  def self.choose_media_dir(dirs)
    dirs.find { |d| File.basename(File.dirname(d)) == "User 1" } || dirs.first
  end

  # Prompt to copy the given audio filenames (relative names under data/audio)
  # into the discovered Anki media folder. No-op when nothing references audio.
  def self.copy_audio(filenames)
    filenames = filenames.compact.uniq
    return false if filenames.empty?

    media_dirs = find_media_dirs

    if media_dirs.empty?
      puts ""
      puts "Could not find an Anki media folder in the standard locations."
      puts "Copy #{Paths::AUDIO_DIR}/*.mp3 into your profile's collection.media folder yourself,"
      puts "or set ANKI_MEDIA_DIR to its full path and re-run."
      return false
    end

    target = choose_media_dir(media_dirs)
    puts ""
    if media_dirs.size > 1
      puts "Found multiple Anki media folders:"
      media_dirs.each { |d| puts "  #{d}#{d == target ? '   <- will use' : ''}" }
      puts "(set ANKI_MEDIA_DIR to pick a different one)"
    else
      puts "Found Anki media folder:"
      puts "  #{target}"
    end
    puts ""
    print "Copy #{filenames.size} audio files there now? [Y/n] "
    answer = $stdin.gets.to_s.strip

    unless answer.empty? || answer.downcase.start_with?("y")
      puts "  Skipped. Before importing, copy #{Paths::AUDIO_DIR}/*.mp3 to:"
      puts "    #{target}/"
      return false
    end

    copied = 0
    missing = []
    filenames.each do |name|
      src = File.join(Paths::AUDIO_DIR, name)
      if File.exist?(src)
        FileUtils.cp(src, File.join(target, name))
        copied += 1
      else
        missing << name
      end
    end

    puts "  Copied #{copied} audio files to #{target}"
    puts "  WARNING: #{missing.size} referenced files missing from #{Paths::AUDIO_DIR}: #{missing.join(', ')}" unless missing.empty?
    true
  end
end
