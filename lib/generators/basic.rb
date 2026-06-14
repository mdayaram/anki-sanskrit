# frozen_string_literal: true

require_relative "base"

module Generators
  # The basic Sanskrit alphabet: one card per scraped letter.
  #   Front: Devanagari character (large) + audio
  #   Back:  romanization + audio + properties + pronunciation tips
  #
  # This is the only category with audio; its cards carry [sound:...] tags, which
  # drives the media-copy step in main.rb.
  class Basic < Base
    KEY         = "basic"
    DESCRIPTION = "Basic alphabet — one card per letter (with audio)"
    OUTPUT_TXT  = "sanskrit_anki.txt"

    def build
      @letters
    end

    def card(letter)
      devan      = letter["devanagari"]
      roman      = letter["roman"]
      audio_file = letter["audio_file"]
      properties = letter["properties"] || []
      tips_html  = letter["pronunciation_tips_html"] || ""

      sound_tag = "[sound:#{audio_file}]"

      front = Anki.glyph_front(devan)

      back_parts = ["<center><big><big><b>#{roman}</b></big></big><br>#{sound_tag}</center>"]

      unless properties.empty?
        props_html = properties.map { |p| "<li>#{p}</li>" }.join
        back_parts << "<hr><b>Properties</b><ul>#{props_html}</ul>"
      end

      cleaned_tips = clean_tips_html(tips_html)
      back_parts << "<hr><b>Pronunciation</b><br>#{cleaned_tips}" unless cleaned_tips.empty?

      [roman, front, back_parts.join]
    end

    def audio_files(letters)
      letters.map { |l| l["audio_file"] }.compact
    end

    private

    # Rewrite the source page's styled spans to plain Anki markup and strip the
    # rest. coloredletter1 -> bold, coloredletter2 -> italic, tipsmallfont -> small.
    def clean_tips_html(html)
      return "" if html.nil? || html.strip.empty?

      text = html.dup
      text.gsub!(/\r\n/, "")
      text.gsub!(/\n/, "")
      text.gsub!(%r{<span[^>]*class="coloredletter1"[^>]*>([^<]*)</span>}, '<b>\1</b>')
      text.gsub!(%r{<span[^>]*class="coloredletter2"[^>]*>([^<]*)</span>}, '<i>\1</i>')
      text.gsub!(%r{<span[^>]*class="tipsmallfont"[^>]*>([^<]*)</span>}, '<small>\1</small>')
      text.gsub!(%r{</?span[^>]*>}, "")
      text.strip
    end
  end
end
