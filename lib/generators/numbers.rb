# frozen_string_literal: true

require_relative "base"
require_relative "../numbers"

module Generators
  # Sanskrit numbers deck. Pure reader over data/numbers.json (the committed source
  # of truth), read via Numbers.load. No audio, no JSON intermediate.
  #
  # Built on the "core + rules + exceptions" principle: the learner memorises the
  # ~20 building blocks (1-10, the tens, 100, 1000) and the compounding rule, and
  # only the irregular or sandhi-affected compounds are carded individually. The
  # full 21-99 grid is deliberately NOT carded: once the rule is known, a regular
  # compound is predictable, and a card for each would be rote.
  #
  # Card kinds (each record section of the data file):
  #   digits    ५ -> 5 + the word (recognising Devanagari digits)
  #   numerals  २.४७ -> 2.47 (multi-digit numbers and verse references)
  #   cardinals TWO cards each: word -> number (recognition) and number -> word
  #             (production), with distinct key prefixes so Anki keeps them apart
  #   ordinals  the Gita colophon form प्रथमोऽध्यायः -> "chapter 1", the
  #             number form a Gita reader meets most
  #   rules     a question about how numbers are built -> the rule + examples
  class Numbers < Base
    KEY         = "numbers"
    DESCRIPTION = "Sanskrit numbers (digits, number words, ordinals, compounding rules)"
    OUTPUT_TXT  = "sanskrit_numbers_anki.txt"

    GENDERS = { "m" => "masc.", "f" => "fem.", "n" => "neut." }.freeze

    def self.requires_letters? = false
    def deck = Anki::NUMBERS_DECK

    # One entry per card: [kind, record]. Cardinals contribute two cards each.
    def build
      data = ::Numbers.load
      data["digits"].map { |r| [:digit, r] } +
        data["numerals"].map { |r| [:numeral, r] } +
        data["cardinals"].flat_map { |r| [[:word_to_number, r], [:number_to_word, r]] } +
        data["ordinals"].map { |r| [:ordinal, r] } +
        data["rules"].map { |r| [:rule, r] }
    end

    def card((kind, record))
      send("#{kind}_card", record)
    end

    def self.ordinal_suffix(n)
      return "th" if (11..13).cover?(n % 100)

      { 1 => "st", 2 => "nd", 3 => "rd" }.fetch(n % 10, "th")
    end

    private

    def big(text, depth) = "#{'<big>' * depth}#{text}#{'</big>' * depth}"
    def center(html) = "<center>#{html}</center>"
    def dev_digits(value) = ::Numbers.to_devanagari_digits(value)

    def digit_card(r)
      back = center("#{big(r['value'], 3)}<br>#{big(r['devanagari'], 2)}<br>#{r['iast']}")
      ["numbers:digit:#{r['value']}", Anki.glyph_front(r["digit"]), back]
    end

    def numeral_card(r)
      back = center("#{big(r['reading'], 3)}<br>#{r['note']}")
      ["numbers:numeral:#{r['reading']}", center(big(r["devanagari"], 4)), back]
    end

    def word_to_number_card(r)
      front = center(big(r["devanagari"], 4))
      back  = center("#{big(r['value'], 3)} &nbsp; #{big(dev_digits(r['value']), 2)}<br>#{word_details(r)}")
      ["numbers:word:#{r['value']}", front, back]
    end

    def number_to_word_card(r)
      front = center("#{big(r['value'], 4)}<br><small>in Sanskrit?</small>")
      back  = center("#{big(r['devanagari'], 3)}<br>#{word_details(r)}")
      ["numbers:number:#{r['value']}", front, back]
    end

    # Shared back panel for both directions of a cardinal.
    def word_details(r)
      html = +"<big>#{r['iast']}</big>"
      html << "<br>#{r['parts']}" if r["parts"]
      html << "<br>stem: #{r['stem']['devanagari']} #{r['stem']['iast']}" if r["stem"]
      if r["gender_forms"]
        forms = r["gender_forms"].map { |f| "#{GENDERS.fetch(f['gender'])} #{f['devanagari']} #{f['iast']}" }
        html << "<br>#{forms.join(' · ')}"
      end
      if r["alternates"]
        alts = r["alternates"].map { |a| "#{a['devanagari']} #{a['iast']}" }
        html << "<br>also: #{alts.join(' · ')}"
      end
      html << "<br><br>#{r['explanation']}" if r["explanation"]
      html
    end

    def ordinal_card(r)
      n = r["value"]
      back = center(
        "#{big("chapter #{n}", 3)}<br><big>#{r['colophon_iast']}</big>" \
        "<br><br>#{r['devanagari']} #{r['iast']} = #{n}#{self.class.ordinal_suffix(n)} (#{dev_digits(n)})" \
        "<br><small>adhyāyaḥ \"chapter\"; the ordinal's -aḥ becomes -o and the a- of adhyāyaḥ is elided (ऽ)</small>"
      )
      ["numbers:ordinal:#{n}", center(big(r["colophon_devanagari"], 4)), back]
    end

    def rule_card(r)
      examples = r["examples"].map { |e| "#{e['devanagari']} #{e['iast']} = #{e['value']}" }
      back = center("#{r['answer']}<br><br>#{examples.join('<br>')}")
      ["numbers:rule:#{r['id']}", center(big(r["question"], 2)), back]
    end
  end
end
