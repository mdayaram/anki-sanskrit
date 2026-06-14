# frozen_string_literal: true

require_relative "base"

module Generators
  # Conjunct consonants (saṃyuktākṣara — two or more consonants written as a
  # single ligature). Deterministic Unicode, no scraping: a conjunct's Devanagari
  # is its component consonants joined by the virama U+094D (प + ् + र = प्र), and
  # its IAST is each component's roman with the inherent trailing 'a' dropped from
  # every component except the last (pa + ra -> "p" + "ra" = "pra"). Composition
  # validated against https://en.wikipedia.org/wiki/Devanagari_conjuncts.
  class Conjuncts < Base
    KEY         = "conjuncts"
    DESCRIPTION = "Conjunct consonants (saṃyuktākṣara ligatures)"
    OUTPUT_TXT  = "sanskrit_conjuncts_anki.txt"
    OUTPUT_JSON = "conjuncts.json"

    VIRAMA = "्"

    # The most common conjuncts in Classical Sanskrit, as [component_ids, frequency].
    # Frequency is Ulrich Stiehl's per-half-verse occurrence rate over the BORI
    # Mahabharata (158,484 half-verse lines), reproduced on Wikipedia's
    # "Devanagari conjuncts" page. This is the subset with frequency > 1.0%, ordered
    # high to low. क्ष (kSha) and ज्ञ (jJNa) are intentionally excluded — they already
    # live in the basic alphabet deck from letters.json.
    CONJUNCTS = [
      [%w[pa ra], 21.172],            # प्र pra
      [%w[ta ra], 14.06],             # त्र tra
      [%w[sa ta], 13.762],            # स्त sta
      [%w[sa ya], 13.483],            # स्य sya
      [%w[sha ca], 12.999],           # श्च śca
      [%w[na ta], 12.919],            # न्त nta
      [%w[ra va], 11.898],            # र्व rva
      [%w[ta ya], 9.763],             # त्य tya
      [%w[ra ma], 9.114],             # र्म rma
      [%w[ta va], 8.125],             # त्व tva
      [%w[ta ta], 7.464],             # त्त tta
      [%w[na ya], 7.223],             # न्य nya
      [%w[ra ya], 6.633],             # र्य rya
      [%w[da dha], 6.155],            # द्ध ddha
      [%w[va ya], 6.095],             # व्य vya
      [%w[da ra], 5.763],             # द्र dra
      [%w[sha ra], 5.604],            # श्र śra
      [%w[da ya], 5.591],             # द्य dya
      [%w[ka ra], 5.207],             # क्र kra
      [%w[da va], 5.162],             # द्व dva
      [%w[na na], 5.086],             # न्न nna
      [%w[sa ma], 4.964],             # स्म sma
      [%w[ra tha], 4.883],            # र्थ rtha
      [%w[Sha Ta], 4.855],            # ष्ट ṣṭa
      [%w[ka ta], 4.85],              # क्त kta
      [%w[sa va], 4.801],             # स्व sva
      [%w[ba ra], 4.583],             # ब्र bra
      [%w[Na Da], 4.57],              # ण्ड ṇḍa
      [%w[Sha Tha], 4.521],           # ष्ठ ṣṭha
      [%w[ra ta], 4.314],             # र्त rta
      [%w[ca cha], 4.297],            # च्छ ccha
      [%w[ta ma], 4.163],             # त्म tma
      [%w[ra Sha], 4.117],            # र्ष rṣa
      [%w[sa tha], 3.492],            # स्थ stha
      [%w[sha va], 3.454],            # श्व śva
      [%w[Sha ya], 3.44],             # ष्य ṣya
      [%w[ra Na], 3.357],             # र्ण rṇa
      [%w[ta sa], 3.35],              # त्स tsa
      [%w[sha ya], 3.276],            # श्य śya
      [%w[bha ya], 3.24],             # भ्य bhya
      [%w[ha ma], 2.98],              # ह्म hma
      [%w[na ma], 2.803],             # न्म nma
      [%w[sa ta ra], 2.764],          # स्त्र stra
      [%w[dha ya], 2.68],             # ध्य dhya
      [%w[pa ta], 2.664],             # प्त pta
      [%w[na va], 2.65],              # न्व nva
      [%w[na da], 2.632],             # न्द nda
      [%w[ga ra], 2.453],             # ग्र gra
      [%w[na da ra], 2.427],          # न्द्र ndra
      [%w[na dha], 2.396],            # न्ध ndha
      [%w[pa ya], 2.285],             # प्य pya
      [%w[ra ja], 2.24],              # र्ज rja
      [%w[ma ya], 2.118],             # म्य mya
      [%w[ha ya], 2.118],             # ह्य hya
      [%w[GNa ga], 2.091],            # ङ्ग ṅga
      [%w[ja ya], 1.937],             # ज्य jya
      [%w[ta pa], 1.918],             # त्प tpa
      [%w[ta ka], 1.883],             # त्क tka
      [%w[ra da], 1.873],             # र्द rda
      [%w[Sha Na], 1.793],            # ष्ण ṣṇa
      [%w[JNa ca], 1.779],            # ञ्च ñca
      [%w[na sa], 1.767],             # न्स nsa
      [%w[ca ca], 1.716],             # च्च cca
      [%w[ra ga], 1.698],             # र्ग rga
      [%w[ra ha], 1.688],             # र्ह rha
      [%w[da bha], 1.687],            # द्भ dbha
      [%w[Na ya], 1.523],             # ण्य ṇya
      [%w[Sha ma], 1.504],            # ष्म ṣma
      [%w[sa ra], 1.481],             # स्र sra
      [%w[ka Sha ya], 1.476],         # क्ष्य kṣya
      [%w[ra sha], 1.443],            # र्श rśa
      [%w[ra dha], 1.434],            # र्ध rdha
      [%w[Sha Ta va], 1.405],         # ष्ट्व ṣṭva
      [%w[ta ta va], 1.339],          # त्त्व ttva
      [%w[sa ta va], 1.339],          # स्त्व stva
      [%w[ka ya], 1.308],             # क्य kya
      [%w[kha ya], 1.307],            # ख्य khya
      [%w[ga na], 1.29],              # ग्न gna
      [%w[ra bha], 1.285],            # र्भ rbha
      [%w[Sha Ta ra], 1.252],         # ष्ट्र ṣṭra
      [%w[bha ra], 1.242],            # भ्र bhra
      [%w[na pa], 1.195],             # न्प npa
      [%w[la ya], 1.178],             # ल्य lya
      [%w[va ra], 1.172],             # व्र vra
      [%w[Sha va], 1.145],            # ष्व ṣva
      [%w[ra na], 1.118],             # र्न rna
      [%w[ca ya], 1.111],             # च्य cya
      [%w[JNa ja], 1.057],            # ञ्ज ñja
      [%w[sa pa], 1.003]              # स्प spa
    ].freeze

    def build
      CONJUNCTS.map do |component_ids, frequency|
        {
          "id"            => component_ids.join("_"),
          "component_ids" => component_ids,
          "devanagari"    => conjunct_devanagari(component_ids),
          "roman"         => conjunct_roman(component_ids),
          "frequency"     => frequency
        }
      end
    end

    def card(entry)
      front = Anki.glyph_front(entry["devanagari"])

      # Component breakdown matching the IAST: every consonant but the last is a
      # half-form (virama, inherent 'a' dropped); the last keeps its full form
      # and vowel, so the parts read as the conjunct does — e.g. प् (p) + र (ra).
      ids = entry["component_ids"]
      breakdown = ids.each_with_index.map do |id, i|
        letter = @letters_by_id.fetch(id)
        if i == ids.size - 1
          "#{letter['devanagari']} (#{letter['roman']})"
        else
          "#{letter['devanagari']}#{VIRAMA} (#{letter['roman'].sub(/a\z/, '')})"
        end
      end.join(" + ")

      back = "<center><big><big><b>#{entry['roman']}</b></big></big>" \
             "<br><big>#{breakdown}</big>" \
             "<br><small>frequency: #{entry['frequency']}%</small></center>"

      [entry["id"], front, back]
    end

    private

    # A conjunct's Devanagari: component consonants joined by the virama.
    def conjunct_devanagari(component_ids)
      component_ids.map { |id| @letters_by_id.fetch(id)["devanagari"] }.join(VIRAMA)
    end

    # A conjunct's IAST: every component but the last loses its inherent trailing
    # 'a' (pa -> p), and the final component keeps its full form (ra -> ra).
    def conjunct_roman(component_ids)
      component_ids.each_with_index.map do |id, i|
        roman = @letters_by_id.fetch(id)["roman"]
        i == component_ids.size - 1 ? roman : roman.sub(/a\z/, "")
      end.join
    end
  end
end
