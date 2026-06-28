# frozen_string_literal: true

# Sanskrit vowel (svara) sandhi engine.
#
# Given two IAST words, `Sandhi.join` finds the junction — the final vowel of
# word 1 and the initial vowel of word 2 — and applies the named sandhi rule to
# produce the combined IAST form. The transform is fully deterministic: the same
# "computed, not scraped" approach as the combinations/conjuncts generators.
#
# The rule (`type`) is supplied by the caller and VALIDATED against the vowel
# pair: a mislabelled pair raises ArgumentError. This self-checks the curated
# word list — a pair tagged :guna whose junction is actually i+i (dīrgha) fails
# loudly. The one genuinely ambiguous case is a word-final e/o before initial a,
# which is :ayadi internally (ne+ana → nayana) but :avagraha across a word
# boundary (te+api → te'pi); for that pair both types are accepted and the label
# decides, so curated avagraha vs ayadi examples are honoured as written.
#
# Rules and mappings verified across Whitney, Emeneau & van Nooten, Pāṇini's
# sūtras (6.1.101/87/88/77/78), learnsanskrit.org and the Arsha Vidya handouts.
module Sandhi
  # Vowel classes (IAST). "ik" = simple vowels other than a/ā.
  A_CLASS  = %w[a ā].freeze
  IK_CLASS = %w[i ī u ū ṛ ṝ ḷ ḹ].freeze
  COMPOUND = %w[e ai o au].freeze

  # Homogeneous (savarṇa) groups, for savarṇa-dīrgha.
  SAVARNA_GROUPS = [%w[a ā], %w[i ī], %w[u ū], %w[ṛ ṝ], %w[ḷ ḹ]].freeze

  # savarṇa-dīrgha: like simple vowels → the corresponding long vowel.
  LONG = {
    "a" => "ā", "ā" => "ā", "i" => "ī", "ī" => "ī", "u" => "ū", "ū" => "ū",
    "ṛ" => "ṝ", "ṝ" => "ṝ", "ḷ" => "ḹ", "ḹ" => "ḹ"
  }.freeze

  # guṇa: a/ā + this dissimilar simple vowel → this grade.
  GUNA = { "i" => "e", "ī" => "e", "u" => "o", "ū" => "o",
           "ṛ" => "ar", "ṝ" => "ar", "ḷ" => "al", "ḹ" => "al" }.freeze

  # vṛddhi: a/ā + this compound vowel → this grade.
  VRDDHI = { "e" => "ai", "ai" => "ai", "o" => "au", "au" => "au" }.freeze

  # yaṇ: this ik-vowel before a dissimilar vowel → this semivowel.
  SEMIVOWEL = { "i" => "y", "ī" => "y", "u" => "v", "ū" => "v",
                "ṛ" => "r", "ṝ" => "r", "ḷ" => "l", "ḹ" => "l" }.freeze

  # ayādi: this compound vowel before a vowel → this substitute.
  AYADI = { "e" => "ay", "ai" => "āy", "o" => "av", "au" => "āv" }.freeze

  AVAGRAHA = "'"

  RULES = {
    dirgha: {
      name: "Savarṇa-dīrgha", devanagari_name: "सवर्णदीर्घ",
      explanation: "Two like simple vowels coalesce into the corresponding long vowel (a+a→ā, i+i→ī, u+u→ū, ṛ+ṛ→ṝ)."
    },
    guna: {
      name: "Guṇa", devanagari_name: "गुण",
      explanation: "a/ā followed by a dissimilar simple vowel becomes the guṇa vowel: +i/ī→e, +u/ū→o, +ṛ/ṝ→ar."
    },
    vrddhi: {
      name: "Vṛddhi", devanagari_name: "वृद्धि",
      explanation: "a/ā followed by a compound vowel becomes the vṛddhi vowel: +e→ai, +o→au."
    },
    yan: {
      name: "Yaṇ", devanagari_name: "यण्",
      explanation: "i/ī, u/ū, ṛ/ṝ before a dissimilar vowel become the semivowels y, v, r respectively (the second vowel is kept)."
    },
    ayadi: {
      name: "Ayādi", devanagari_name: "अयादि",
      explanation: "A compound vowel before another vowel becomes ay/āy/av/āv (e→ay, ai→āy, o→av, au→āv)."
    },
    avagraha: {
      name: "Avagraha (lopa)", devanagari_name: "अवग्रह",
      explanation: "A word-final e/o before an initial a: the a is elided and marked with an avagraha (ऽ); the e/o is unchanged."
    }
  }.freeze

  # Two-character vowels must be matched before single ones at a boundary.
  TWO_CHAR_VOWELS = %w[ai au].freeze
  ALL_VOWELS = (A_CLASS + IK_CLASS + COMPOUND).freeze

  module_function

  # Join two IAST words with the named vowel-sandhi rule. Returns a hash with the
  # combined form, the input words, the junction vowels, and the rule metadata.
  def join(word1, word2, type)
    raise ArgumentError, "unknown sandhi type #{type.inspect}" unless RULES.key?(type)

    head1, v1 = split_final_vowel(word1)
    v2, tail2 = split_initial_vowel(word2)

    valid = candidates(v1, v2)
    unless valid.include?(type)
      raise ArgumentError,
            "#{word1} + #{word2} (#{v1} + #{v2}) is #{valid.empty? ? 'not a vowel sandhi' : valid.join('/')}, not #{type}"
    end

    combined =
      case type
      when :dirgha   then head1 + LONG.fetch(v1) + tail2
      when :guna     then head1 + GUNA.fetch(v2) + tail2
      when :vrddhi   then head1 + VRDDHI.fetch(v2) + tail2
      when :yan      then head1 + SEMIVOWEL.fetch(v1) + word2 # second vowel kept
      when :ayadi    then head1 + AYADI.fetch(v1) + word2     # second vowel kept
      when :avagraha then head1 + v1 + AVAGRAHA + tail2       # initial a elided
      end

    RULES.fetch(type).merge(
      type: type, word1: word1, word2: word2, v1: v1, v2: v2, combined: combined
    )
  end

  # The sandhi type(s) a vowel junction can resolve to. Usually exactly one; a
  # word-final e/o before initial a is the lone ambiguous case (ayadi/avagraha).
  def candidates(v1, v2)
    types = []
    if A_CLASS.include?(v1)
      types << :dirgha if A_CLASS.include?(v2)
      types << :guna   if IK_CLASS.include?(v2)
      types << :vrddhi if COMPOUND.include?(v2)
    elsif IK_CLASS.include?(v1)
      types << (savarna?(v1, v2) ? :dirgha : :yan)
    elsif COMPOUND.include?(v1)
      types << :ayadi
      types << :avagraha if %w[e o].include?(v1) && v2 == "a"
    end
    types
  end

  def savarna?(v1, v2)
    SAVARNA_GROUPS.any? { |g| g.include?(v1) && g.include?(v2) }
  end

  # [everything before the final vowel, the final vowel].
  def split_final_vowel(word)
    two = word[-2, 2]
    return [word[0..-3], two] if TWO_CHAR_VOWELS.include?(two)

    one = word[-1]
    raise ArgumentError, "#{word} does not end in a vowel" unless ALL_VOWELS.include?(one)

    [word[0..-2], one]
  end

  # [the initial vowel, everything after it].
  def split_initial_vowel(word)
    two = word[0, 2]
    return [two, word[2..]] if TWO_CHAR_VOWELS.include?(two)

    one = word[0]
    raise ArgumentError, "#{word} does not start with a vowel" unless ALL_VOWELS.include?(one)

    [one, word[1..]]
  end
end
