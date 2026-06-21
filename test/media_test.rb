# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "stringio"
require_relative "../lib/media"

class MediaTest < Minitest::Test
  def test_copies_from_custom_source_dir
    Dir.mktmpdir do |src|
      Dir.mktmpdir do |dest|
        File.write(File.join(src, "gita_1_1.mp3"), "AUDIO")
        ENV["ANKI_MEDIA_DIR"] = dest
        old_stdin = $stdin
        $stdin = StringIO.new("y\n")
        begin
          Media.copy_audio(["gita_1_1.mp3"], source_dir: src)
        ensure
          $stdin = old_stdin
          ENV.delete("ANKI_MEDIA_DIR")
        end
        assert File.exist?(File.join(dest, "gita_1_1.mp3"))
        assert_equal "AUDIO", File.read(File.join(dest, "gita_1_1.mp3"))
      end
    end
  end
end
