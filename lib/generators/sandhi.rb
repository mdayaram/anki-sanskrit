# frozen_string_literal: true

require_relative "base"
require_relative "../sandhi"
require_relative "../iast_devanagari"

module Generators
  # Vowel (svara) sandhi deck. Computed, not scraped: the driving constant PAIRS
  # is a curated list of [word1, word2, sandhi_type] in IAST; the Sandhi engine
  # joins each pair deterministically and validates the label against the actual
  # junction (a mislabelled pair raises). Devanagari is regenerated from the IAST
  # via IastDevanagari, exactly as the Vedanta deck does.
  #
  #   Front: the two parts in Devanagari, space-separated (देव इन्द्र)
  #   Back:  the combined Devanagari, the IAST (deva + indra → devendra),
  #          which sandhi fired, a brief rule explanation, and the CONTEXT.
  # No audio.
  #
  # Context matters because the front shows two pieces, and how vowels behave at a
  # junction depends on whether those pieces are two free words, the members of a
  # compound, or a stem+affix inside one word. The vowel rules give the same
  # result in all three EXCEPT for a word-final diphthong: between two words,
  # e/o + a → avagraha (te'pi) and ai/au reduce/retain (the ay/av of ayādi never
  # appears across a word boundary). So each pair is tagged with its context, and
  # the two context-bound rules are kept consistent: ayādi examples are internal
  # (derivational), avagraha examples are between words. Add a pair by appending
  # to its category's list; the engine computes and validates the rest.
  class Sandhi < Base
    KEY         = "sandhi"
    DESCRIPTION = "Vowel sandhi (Devanagari word pair -> combined form + rule)"
    OUTPUT_TXT  = "sanskrit_sandhi_anki.txt"
    OUTPUT_JSON = "sandhi.json"

    # How the two pieces relate, shown on the card so the junction isn't misread.
    CONTEXTS = {
      external: "between two separate words",
      compound: "within a compound",
      internal: "within a single word"
    }.freeze

    # [word1, word2, type, context] in IAST. Curated canonical examples, every
    # sub-rule represented; sourced from the verified worked examples (Whitney,
    # Emeneau, learnsanskrit.org, Arsha Vidya). Unattested ḷ junctions are omitted.
    PAIRS = [
      # savarṇa-dīrgha: like simple vowels → long
      ["deva", "ālaya", :dirgha, :compound],     # a + ā → ā
      ["vidyā", "artha", :dirgha, :compound],    # ā + a → ā
      ["mahā", "ātman", :dirgha, :compound],     # ā + ā → ā
      ["dharma", "artha", :dirgha, :compound],   # a + a → ā
      ["ravi", "indra", :dirgha, :compound],     # i + i → ī
      ["kavi", "īśvara", :dirgha, :compound],    # i + ī → ī
      ["guru", "upadeśa", :dirgha, :compound],   # u + u → ū
      ["vadhū", "utsava", :dirgha, :compound],   # ū + u → ū

      # guṇa: a/ā + dissimilar simple vowel → e/o/ar
      ["deva", "indra", :guna, :compound],       # a + i → e
      ["gaṇa", "īśa", :guna, :compound],         # a + ī → e
      ["mahā", "indra", :guna, :compound],       # ā + i → e
      ["sūrya", "udaya", :guna, :compound],      # a + u → o
      ["mahā", "utsava", :guna, :compound],      # ā + u → o
      ["hita", "upadeśa", :guna, :compound],     # a + u → o
      ["deva", "ṛṣi", :guna, :compound],         # a + ṛ → ar
      ["mahā", "ṛṣi", :guna, :compound],         # ā + ṛ → ar

      # vṛddhi: a/ā + compound vowel → ai/au
      ["eka", "eka", :vrddhi, :compound],        # a + e → ai
      ["sadā", "eva", :vrddhi, :external],       # ā + e → ai  (sadā + eva)
      ["tathā", "eva", :vrddhi, :external],      # ā + e → ai  (tathā + eva)
      ["na", "eva", :vrddhi, :external],         # a + e → ai  (na + eva)
      ["jala", "ogha", :vrddhi, :compound],      # a + o → au
      ["mahā", "oṣadhi", :vrddhi, :compound],    # ā + o → au

      # yaṇ: i/u/ṛ before a dissimilar vowel → y/v/r
      ["prati", "akṣa", :yan, :internal],        # i → y  (prefix prati-)
      ["iti", "ādi", :yan, :compound],           # i → y
      ["prati", "eka", :yan, :internal],         # i → y  (prefix prati-)
      ["su", "alpa", :yan, :internal],           # u → v  (prefix su-)
      ["su", "āgata", :yan, :internal],          # u → v  (prefix su-)
      ["anu", "aya", :yan, :internal],           # u → v  (prefix anu-)
      ["nanu", "eva", :yan, :external],          # u → v  (nanu + eva)
      ["pitṛ", "artha", :yan, :compound],        # ṛ → r

      # ayādi: compound vowel before a vowel → ay/āy/av/āv. The retained
      # semivowel only arises in derivation (internal sandhi), never between
      # two free words — so these are root-grade + suffix forms.
      ["ne", "ana", :ayadi, :internal],          # e → ay   (√nī)
      ["gai", "aka", :ayadi, :internal],         # ai → āy  (√gai)
      ["bho", "ana", :ayadi, :internal],         # o → av   (√bhū)
      ["nau", "ika", :ayadi, :internal],         # au → āv  (nau + -ika)

      # avagraha: word-final e/o + initial a → e/o + ऽ (the a is elided). This is
      # the genuine word-boundary outcome of e/o before a.
      ["te", "api", :avagraha, :external],       # e + a → e'
      ["vane", "asti", :avagraha, :external],    # e + a → e'
      ["so", "api", :avagraha, :external],       # o + a → o'
      ["rāmo", "api", :avagraha, :external]      # o + a → o'
    ].freeze

    def self.requires_letters? = false
    def deck = Anki::SANDHI_DECK

    def build
      PAIRS.map do |word1, word2, type, context|
        r = ::Sandhi.join(word1, word2, type)
        {
          "type"                => type.to_s,
          "context"             => context.to_s,
          "word1_iast"          => word1,
          "word2_iast"          => word2,
          "combined_iast"       => r[:combined],
          "word1_devanagari"    => IastDevanagari.to_devanagari(word1),
          "word2_devanagari"    => IastDevanagari.to_devanagari(word2),
          "combined_devanagari" => IastDevanagari.to_devanagari(r[:combined]),
          "sandhi_name"         => r[:name],
          "sandhi_devanagari"   => r[:devanagari_name],
          "explanation"         => r[:explanation]
        }
      end
    end

    def card(entry)
      key     = "sandhi:#{entry['type']}:#{entry['word1_iast']}+#{entry['word2_iast']}"
      context = CONTEXTS.fetch(entry["context"].to_sym)
      front   = "<center>#{'<big>' * 3}#{entry['word1_devanagari']} #{entry['word2_devanagari']}#{'</big>' * 3}</center>"
      back    = "<center>#{'<big>' * 2}<b>#{entry['combined_devanagari']}</b>#{'</big>' * 2}" \
                "<br><big>#{entry['word1_iast']} + #{entry['word2_iast']} → #{entry['combined_iast']}</big>" \
                "<br><br><b>#{entry['sandhi_name']} sandhi (#{entry['sandhi_devanagari']})</b>" \
                "<br>#{entry['explanation']}" \
                "<br><small>(sandhi #{context})</small></center>"
      [key, front, back]
    end
  end
end
