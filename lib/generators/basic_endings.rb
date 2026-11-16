# frozen_string_literal: true

require_relative "base"
require_relative "../declensions"

module Generators
  # The basic endings of the Arsha Bodha "Basic Terminations" handout, asked
  # cell -> ending: "Instrumental (तृतीया) dual" → भ्याम्. One card per cell of the
  # masculine/feminine table (7 cases x 3 numbers), one for the vocative (which
  # repeats the nominative), and three for the neuter's own nominative/accusative.
  #
  #   Front: the cell, and which genders the ending covers there
  #   Back:  the ending, the whole row with this cell in bold, the other cells
  #          sharing it, and the ending at work on मरुत् (or जगत् for the neuter)
  #
  # A pure reader over data/declensions.json. No audio, no JSON intermediate.
  class BasicEndings < Base
    KEY         = "basic-endings"
    DESCRIPTION = "Sanskrit basic case endings (case + number -> ending)"
    OUTPUT_TXT  = "sanskrit_declensions_1_endings_anki.txt"

    # The worked example on each back: the masculine noun declined in class, and
    # the neuter one for the neuter cards.
    EXAMPLE_NOUN = "marut"
    NEUTER_EXAMPLE_NOUN = "jagat"

    def self.requires_letters? = false
    def deck = Anki::BASIC_ENDINGS_DECK

    def build
      @data = Declensions.load
      cells = (Declensions::CASES - ["vocative"]).product(Declensions::NUMBERS)
      cells.map { |c, n| { "kind" => "mf", "case" => c, "number" => n } } +
        [{ "kind" => "vocative" }] +
        Declensions::NUMBERS.map { |n| { "kind" => "neuter", "number" => n } }
    end

    def card(entry)
      @data ||= Declensions.load
      case entry["kind"]
      when "mf" then mf_card(entry["case"], entry["number"])
      when "vocative" then vocative_card
      else neuter_card(entry["number"])
      end
    end

    private

    def mf_card(kase, number)
      e = Declensions.mf_ending(@data, kase, number)
      scope = Declensions::NEUTER_CASES.include?(kase) ? "masculine &amp; feminine" : "all genders"
      front = "<center><big>#{Declensions.cell_label(kase, number)}</big><br><small>basic ending · #{scope}</small></center>"

      row = Declensions::NUMBERS.map do |n|
        dev = Declensions.ending_html(Declensions.mf_ending(@data, kase, n))
        n == number ? "<b>#{dev}</b>" : dev
      end
      shared = @data["endings"].select do |x|
        x["devanagari"] == e["devanagari"] && x["case"] != "vocative" && !(x["case"] == kase && x["number"] == number)
      end

      back = +"<center>#{answer(e)}"
      back << "<br><small>#{e['note']}</small>" if e["note"]
      back << "<br><br>#{Declensions.case_names[kase]['devanagari']}: #{row.join(' · ')}"
      back << "<br>Same ending: #{shared.map { |x| Declensions.cell_name(x['case'], x['number']) }.join(', ')}" unless shared.empty?
      back << "<br><br>#{example(EXAMPLE_NOUN, kase, number)}</center>"
      ["basic_ending:mf:#{kase}:#{number}", front, back]
    end

    def vocative_card
      label = CaseFunctions.case_label(Declensions.case_names["vocative"])
      front = "<center><big>#{label}</big><br><small>basic endings · singular, dual, plural</small></center>"
      mf = Declensions::NUMBERS.map { |n| Declensions.ending_html(Declensions.mf_ending(@data, "vocative", n)) }
      neuter = Declensions::NUMBERS.map { |n| Declensions.ending_html(Declensions.ending(@data, "vocative", n, "n")) }
      back = "<center>#{'<big>' * 3}<b>#{mf.join(' · ')}</b>#{'</big>' * 3}" \
             "<br>the same as the nominative<br><br><small>neuter: #{neuter.join(' · ')}, " \
             "likewise the same as its nominative</small></center>"
      ["basic_ending:vocative", front, back]
    end

    def neuter_card(number)
      e = Declensions.ending(@data, "nominative", number, "n")
      front = "<center><big>Neuter nominative &amp; accusative #{number}</big><br><small>basic ending</small></center>"
      nom, acc = %w[nominative accusative].map { |c| Declensions.ending_html(Declensions.mf_ending(@data, c, number)) }
      mf = nom == acc ? "#{nom} for both" : "#{nom} (nom.) and #{acc} (acc.)"
      back = "<center>#{answer(e)}<br><br>One ending for the nominative, the accusative and the vocative. " \
             "Masculine &amp; feminine have #{mf} here.<br><br>#{example(NEUTER_EXAMPLE_NOUN, 'nominative', number)}</center>"
      ["basic_ending:neuter:#{number}", front, back]
    end

    def answer(e)
      "#{'<big>' * 3}<b>#{Declensions.ending_html(e)}</b>#{'</big>' * 3}<br>#{Declensions.ending_iast(e)}"
    end

    # "मरुत् + भिः → मरुद्भिः", with the sandhi note when the join changes something.
    def example(noun_iast, kase, number)
      noun = Declensions.noun(@data, noun_iast)
      form = Declensions.form(noun, kase, number)
      ending = Declensions.ending(@data, kase, number, noun["gender"])
      html = +"<small>e.g. #{Declensions.working(noun, form, ending)} (#{noun['meaning']})"
      html << "<br>#{@data['sandhi'][form['sandhi']]}" if form["sandhi"]
      html << "</small>"
    end
  end
end
