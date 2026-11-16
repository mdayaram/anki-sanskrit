# frozen_string_literal: true

require_relative "base"
require_relative "../declensions"

module Generators
  # Whole paradigms of the class 15 nouns, asked stem + cell -> form: "मरुत्,
  # instrumental plural" → मरुद्भिः. All five end in त् (takārānta), so they show
  # the basic endings joined straight on, with the few sandhi changes the class
  # pointed out: त् → द् before भ्, the nominative's स् dropping, and the neuter
  # plural's inserted न्. मरुत् and जगत् were declined in class; इन्द्रजित्, विद्युत्
  # and बृहत् (declined as a neuter) were the homework.
  #
  #   Front: the stem, its gender and meaning, and the cell
  #   Back:  the form, stem + ending → form, the sandhi note when the join
  #          changed something, and the other cells with the same form
  #
  # Every cell gets a card, vocative included. A pure reader over
  # data/declensions.json. No audio, no JSON intermediate.
  class TNouns < Base
    KEY         = "t-nouns"
    DESCRIPTION = "Five त्-ending nouns in every case and number (stem + case -> form)"
    OUTPUT_TXT  = "sanskrit_declensions_3_t_nouns_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::T_NOUNS_DECK

    def build
      @data = Declensions.load
      @data["nouns"].flat_map { |noun| noun["forms"].map { |form| { "noun" => noun, "form" => form } } }
    end

    def card(entry)
      @data ||= Declensions.load
      noun = entry["noun"]
      form = entry["form"]
      kase = form["case"]
      number = form["number"]
      ending = Declensions.ending(@data, kase, number, noun["gender"])

      front = "<center>#{'<big>' * 3}#{noun['devanagari']}#{'</big>' * 3}" \
              "<br><small>#{Declensions::GENDERS.fetch(noun['gender'])} · #{noun['meaning']}</small>" \
              "<br><br><big>#{Declensions.cell_label(kase, number)}</big></center>"

      same = noun["forms"].reject { |f| f.equal?(form) }.select { |f| f["devanagari"] == form["devanagari"] }
      back = +"<center>#{'<big>' * 3}<b>#{form['devanagari']}</b>#{'</big>' * 3}<br>#{form['iast']}"
      back << "<br><br>#{Declensions.working(noun, form, ending)}"
      back << "<br><small>#{@data['sandhi'][form['sandhi']]}</small>" if form["sandhi"]
      back << "<br><br>Same form: #{same.map { |f| Declensions.cell_name(f['case'], f['number']) }.join(', ')}" unless same.empty?
      back << "<br><br><small>#{noun['note']}</small>" if noun["note"]
      back << "</center>"
      ["t_noun:#{noun['iast']}:#{kase}:#{number}", front, back]
    end
  end
end
