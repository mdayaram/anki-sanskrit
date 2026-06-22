# Vedanta Glossary Word Deck Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `🕉️ Vedanta Glossary` Anki deck (~2,394 single Sanskrit terms; Devanagari front, IAST + English back, no audio) from the arshabodha Vedanta-Sanskrit glossary PDF, with `data/vedanta.json` as the committed source of truth.

**Architecture:** A disposable `bootstrap/` extractor (Python + pypdf) pulls IAST headwords + English definitions from the PDF by font; a committed, tested `lib/iast_devanagari.rb` transliterator adds the Devanagari column; the result is `data/vedanta.json`. A gating, multi-method QA proves the JSON correct before a pure-transform generator (`lib/generators/vedanta.rb`) emits the deck.

**Tech Stack:** Ruby stdlib (runtime + transliterator + QA); Python 3 + `pypdf` (one-time extraction only); minitest for tests.

## Global Constraints

- **Source of truth:** `data/vedanta.json` (committed). The PDF + `bootstrap/` extractor are one-time/disposable; residual errors are fixed **directly in the JSON**, not by hardening the extractor (fix the tool only for *systematic* errors).
- **Kept library:** `lib/iast_devanagari.rb` (transliterator, both directions, tested).
- **Deck:** `🕉️ Vedanta Glossary`, constant `Anki::VEDANTA_DECK`. Flag `--vedanta`. No audio.
- **Card:** front = Devanagari term; back = IAST (bold) + English definition. Key `vedanta:<iast>` (stable GUID). `requires_letters? == false`, `audio_files == []`.
- **Abbreviations** (`comp.`/`ind.`/`lit.`/`nom. sing.`/`p.p.p.`) are expanded inline in definitions.
- **QA gates generation:** the generator is not run until QA (A structural, B round-trip, C visual cross-reference) is clean.
- **Source PDF URL:** `https://arshabodha.org/wp-content/uploads/abc/teachings/Vedanta-Sanskrit-Glossary.pdf` (already downloaded to `/tmp/vedanta_glossary.pdf`).
- **PDF fonts:** `TT2CEt00` = IAST headword, `TT2CDt00` = Devanagari (discard), `TT2D1t00` = English definition, `TT2D0t00` = italic (abbreviations + IAST cross-refs). Entry rows: leftmost chunk is a `TT2CEt00` headword at x≈90.
- **Run Ruby tests:** `ruby test/<name>_test.rb`. **Branch:** `vedanta-glossary-deck` (already checked out).

---

## File Structure

**Create (committed runtime/library):**
- `lib/iast_devanagari.rb` — IAST↔Devanagari transliterator.
- `lib/vedanta.rb` — `Vedanta.load` (reads `data/vedanta.json`).
- `lib/generators/vedanta.rb` — `Generators::Vedanta`.
- `data/vedanta.json` — source of truth (generated, hand-corrected, committed).
- `test/iast_devanagari_test.rb`, `test/vedanta_test.rb`.

**Create (disposable bootstrap):**
- `bootstrap/extract_vedanta.py` — PDF → `bootstrap/vedanta_raw.json` (`[{iast, definition}]`).
- `bootstrap/build_vedanta.rb` — raw + transliterator → `data/vedanta.json`.
- `bootstrap/qa_vedanta.rb` — structural + round-trip QA over `data/vedanta.json`.

**Modify:**
- `lib/anki.rb` — add `VEDANTA_DECK`.
- `main.rb` — register `Generators::Vedanta`.
- `CLAUDE.md`, `README.md` — document the deck.

---

### Task 1: IAST↔Devanagari transliterator

**Files:**
- Create: `lib/iast_devanagari.rb`
- Test: `test/iast_devanagari_test.rb`

**Interfaces:**
- Produces: `IastDevanagari.to_devanagari(iast) -> String` and `IastDevanagari.to_iast(devanagari) -> String`. Deterministic; `to_iast(to_devanagari(x)) == x` for valid lowercase IAST words.

- [ ] **Step 1: Write the failing test**

Create `test/iast_devanagari_test.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/iast_devanagari"

class IastDevanagariTest < Minitest::Test
  def fwd(s) = IastDevanagari.to_devanagari(s)
  def rev(s) = IastDevanagari.to_iast(s)

  def test_independent_vowels
    assert_equal "अ", fwd("a")
    assert_equal "आ", fwd("ā")
    assert_equal "ऐ", fwd("ai")
    assert_equal "औ", fwd("au")
    assert_equal "ऋ", fwd("ṛ")
  end

  def test_consonant_inherent_a
    assert_equal "क", fwd("ka")
    assert_equal "न", fwd("na")
  end

  def test_consonant_with_matra
    assert_equal "की", fwd("kī")
    assert_equal "को", fwd("ko")
  end

  def test_word_final_consonant_gets_virama
    assert_equal "जगत्", fwd("jagat")
  end

  def test_clusters
    assert_equal "क्ष", fwd("kṣa")
    assert_equal "ज्ञ", fwd("jña")
    assert_equal "मोक्षः", fwd("mokṣaḥ")
  end

  def test_anusvara_and_visarga
    assert_equal "अहंकारः", fwd("ahaṃkāraḥ")
    assert_equal "अभावः", fwd("abhāvaḥ")
  end

  def test_real_headwords
    assert_equal "ज्ञानम्", fwd("jñānam")
    assert_equal "ब्रह्मन्", fwd("brahman")
    assert_equal "आत्मा", fwd("ātmā")
  end

  def test_round_trip
    %w[abhāvaḥ mokṣaḥ jñānam ātmā ahaṃkāraḥ jagat brahman vivekaḥ saṃsāraḥ].each do |w|
      assert_equal w, rev(fwd(w)), "round-trip failed for #{w}"
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `ruby test/iast_devanagari_test.rb`
Expected: FAIL — `LoadError: cannot load such file -- ../lib/iast_devanagari`.

- [ ] **Step 3: Implement**

Create `lib/iast_devanagari.rb`:

```ruby
# frozen_string_literal: true

# Deterministic IAST <-> Devanagari transliteration for Sanskrit words.
#
# A committed, reusable tool: it builds the Devanagari column of
# data/vedanta.json and powers the round-trip QA check, and is available for a
# future per-word verse deck. Forward (to_devanagari) and reverse (to_iast) are
# inverse for valid lowercase IAST: to_iast(to_devanagari(x)) == x.
module IastDevanagari
  # vowel => [independent, matra ("" for inherent a)]
  VOWELS = {
    "a" => ["अ", ""],   "ā" => ["आ", "ा"], "i" => ["इ", "ि"], "ī" => ["ई", "ी"],
    "u" => ["उ", "ु"],  "ū" => ["ऊ", "ू"], "ṛ" => ["ऋ", "ृ"], "ṝ" => ["ॠ", "ॄ"],
    "ḷ" => ["ऌ", "ॢ"],  "ḹ" => ["ॡ", "ॣ"], "e" => ["ए", "े"], "ai" => ["ऐ", "ै"],
    "o" => ["ओ", "ो"],  "au" => ["औ", "ौ"]
  }.freeze

  CONSONANTS = {
    "k" => "क", "kh" => "ख", "g" => "ग", "gh" => "घ", "ṅ" => "ङ",
    "c" => "च", "ch" => "छ", "j" => "ज", "jh" => "झ", "ñ" => "ञ",
    "ṭ" => "ट", "ṭh" => "ठ", "ḍ" => "ड", "ḍh" => "ढ", "ṇ" => "ण",
    "t" => "त", "th" => "थ", "d" => "द", "dh" => "ध", "n" => "न",
    "p" => "प", "ph" => "फ", "b" => "ब", "bh" => "भ", "m" => "म",
    "y" => "य", "r" => "र", "l" => "ल", "v" => "व",
    "ś" => "श", "ṣ" => "ष", "s" => "स", "h" => "ह"
  }.freeze

  VIRAMA   = "्"
  ANUSVARA = "ं"
  VISARGA  = "ः"
  AVAGRAHA = "ऽ"

  # IAST tokens, longest first, so "kh"/"ai" match before "k"/"a".
  IAST_TOKENS = (CONSONANTS.keys + VOWELS.keys + ["ṃ", "ḥ", "'"]).sort_by { |t| -t.length }.freeze

  module_function

  def to_devanagari(iast)
    out = +""
    pending_consonant = false # a consonant glyph was emitted with no vowel yet
    i = 0
    s = iast
    while i < s.length
      tok = IAST_TOKENS.find { |t| s[i, t.length] == t }
      if tok.nil?
        # boundary / unknown char (space, hyphen, etc.): close a bare consonant
        out << VIRAMA if pending_consonant
        pending_consonant = false
        out << s[i] unless s[i] == "-" # drop compound hyphens; keep spaces
        i += 1
        next
      end

      if CONSONANTS.key?(tok)
        out << VIRAMA if pending_consonant
        out << CONSONANTS[tok]
        pending_consonant = true
      elsif VOWELS.key?(tok)
        indep, matra = VOWELS[tok]
        out << (pending_consonant ? matra : indep)
        pending_consonant = false
      else # marks
        out << VIRAMA if pending_consonant
        pending_consonant = false
        out << { "ṃ" => ANUSVARA, "ḥ" => VISARGA, "'" => AVAGRAHA }[tok]
      end
      i += tok.length
    end
    out << VIRAMA if pending_consonant
    out
  end

  # Reverse maps (built once).
  DEV_VOWEL_INDEP = VOWELS.to_h { |k, (ind, _m)| [ind, k] }.freeze
  DEV_VOWEL_MATRA = VOWELS.reject { |k, _| k == "a" }.to_h { |k, (_i, m)| [m, k] }.freeze
  DEV_CONSONANT   = CONSONANTS.to_h { |k, v| [v, k] }.freeze

  def to_iast(dev)
    out = +""
    pending_a = false # a consonant base was emitted; inherent 'a' unless cancelled
    i = 0
    while i < dev.length
      ch = dev[i]
      if DEV_CONSONANT.key?(ch)
        out << "a" if pending_a
        out << DEV_CONSONANT[ch]
        pending_a = true
      elsif ch == VIRAMA
        pending_a = false
      elsif DEV_VOWEL_MATRA.key?(ch)
        out << DEV_VOWEL_MATRA[ch]
        pending_a = false
      elsif DEV_VOWEL_INDEP.key?(ch)
        out << "a" if pending_a
        out << DEV_VOWEL_INDEP[ch]
        pending_a = false
      elsif ch == ANUSVARA
        out << "a" if pending_a
        pending_a = false
        out << "ṃ"
      elsif ch == VISARGA
        out << "a" if pending_a
        pending_a = false
        out << "ḥ"
      elsif ch == AVAGRAHA
        out << "a" if pending_a
        pending_a = false
        out << "'"
      else
        out << "a" if pending_a
        pending_a = false
        out << ch
      end
      i += 1
    end
    out << "a" if pending_a
    out
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `ruby test/iast_devanagari_test.rb`
Expected: PASS (8 runs, 0 failures). If a specific word fails, fix the table/logic and re-run before continuing.

- [ ] **Step 5: Commit**

```bash
git add lib/iast_devanagari.rb test/iast_devanagari_test.rb
git commit -m "Add IAST<->Devanagari transliterator"
```

---

### Task 2: Bootstrap PDF extractor

**Files:**
- Create: `bootstrap/extract_vedanta.py`
- Produces: `bootstrap/vedanta_raw.json` = `[{ "iast": String, "definition": String }]`

**Interfaces:**
- Consumes: `/tmp/vedanta_glossary.pdf`, `pypdf`.
- Produces: `bootstrap/vedanta_raw.json` (~2,394 entries; `iast` clean IAST, `definition` decoded English with embedded IAST + expanded abbreviations).

- [ ] **Step 1: Ensure deps + PDF present**

Run:
```bash
mkdir -p bootstrap
python3 -c "import pypdf" 2>/dev/null || pip3 install pypdf
test -f /tmp/vedanta_glossary.pdf || curl -sL "https://arshabodha.org/wp-content/uploads/abc/teachings/Vedanta-Sanskrit-Glossary.pdf" -o /tmp/vedanta_glossary.pdf
python3 -c "import pypdf,os;print('ok', os.path.getsize('/tmp/vedanta_glossary.pdf'))"
```
Expected: `ok 446805` (or similar non-zero size).

- [ ] **Step 2: Write the extractor (seed decode map + structure)**

Create `bootstrap/extract_vedanta.py`:

```python
#!/usr/bin/env python3
"""One-time, DISPOSABLE extractor: arshabodha Vedanta glossary PDF -> raw JSON.

Separates each entry row by font: TT2CEt00 = IAST headword, TT2CDt00 = Devanagari
(discarded — unrecoverable glyph font), TT2D1t00 = English definition, TT2D0t00 =
italic (abbreviations + IAST cross-refs). Devanagari is regenerated later by the
Ruby transliterator. Not robust by design; residual errors are fixed in
data/vedanta.json. Run: python3 bootstrap/extract_vedanta.py
"""
import json, re, collections, sys
import pypdf

PDF = "/tmp/vedanta_glossary.pdf"
OUT = "bootstrap/vedanta_raw.json"

HEAD, DEV, DEF, ITAL = "TT2CEt00", "TT2CDt00", "TT2D1t00", "TT2D0t00"

# WinAnsi-glyph -> IAST decode map for the Times-style IAST fonts (TT2CEt00 /
# TT2D0t00). SEED with the confirmed mappings; complete it by running this script
# then the charset QA, which lists any leftover non-IAST char to add here.
DECODE = {
    "ä": "ā", "é": "ī", "ü": "ū", "ù": "ḥ", "ñ": "ṣ", "ï": "ṅ",
    "ö": "ṭ", "à": "ṃ", "ë": "ḍ", "å": "ṇ", "ç": "ś", "è": "ñ",
    "ì": "ṛ", "ò": "ṝ", "ó": "ḷ", "ê": "ḻ", "í": "ḷ",
    # NOTE: the values above are a STARTING POINT derived from sampled entries.
    # During execution, validate against the rendered PDF (QA method C) and the
    # charset check (QA method A); correct/add entries until QA is clean.
}

ABBREV = {
    "comp.": "compound", "ind.": "indeclinable", "lit.": "literally",
    "nom. sing.": "nominative singular", "p.p.p.": "past passive participle",
}

def decode_iast(s):
    return "".join(DECODE.get(c, c) for c in s)

def expand_abbrev(text):
    for k, v in ABBREV.items():
        text = text.replace(k, v)
    return text

def main():
    reader = pypdf.PdfReader(PDF)
    rows = collections.defaultdict(list)  # (page, y) -> [(x, font, text)]
    def make(page):
        def visit(text, cm, tm, fd, fs):
            if not text.strip():
                return
            try:
                base = (fd.get("/BaseFont") or "") if fd else ""
            except Exception:
                base = ""
            base = str(base).split("+")[-1]
            rows[(page, round(tm[5]))].append((round(tm[4], 1), base, text))
        return visit
    for p in range(len(reader.pages)):
        reader.pages[p].extract_text(visitor_text=make(p))

    # Order rows top-to-bottom within each page.
    ordered = sorted(rows.items(), key=lambda kv: (kv[0][0], -kv[0][1]))

    entries = []
    current = None  # {"iast":..., "def_parts":[...]}
    for (page, y), chunks in ordered:
        chunks.sort()  # by x
        is_entry = chunks and chunks[0][1] == HEAD and 86 <= chunks[0][0] <= 94
        if is_entry:
            if current:
                entries.append(current)
            # headword = first HEAD chunk; definition = DEF/ITAL text on this row.
            iast = decode_iast(chunks[0][2].strip())
            def_parts = []
            for x, f, t in chunks[1:]:
                if f in (DEF, ITAL):
                    def_parts.append(decode_iast(t))
                # DEV chunks (incl. 2nd headword of multi-word rows) are dropped.
            current = {"iast": iast, "def_parts": def_parts}
        elif current is not None:
            # continuation line: append DEF/ITAL text
            for x, f, t in chunks:
                if f in (DEF, ITAL):
                    current["def_parts"].append(decode_iast(t))
    if current:
        entries.append(current)

    out = []
    for e in entries:
        definition = expand_abbrev(re.sub(r"\s+", " ", " ".join(e["def_parts"]).strip()))
        out.append({"iast": e["iast"], "definition": definition})

    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)

    # Report leftover (undecoded) glyphs to extend DECODE with.
    leftover = collections.Counter(
        c for e in out for c in e["iast"]
        if not re.match(r"[a-zāīūṛṝḷḹṅñṭḍṇśṣṃḥ'\- ]", c)
    )
    print(f"entries: {len(out)}  (first iast={out[0]['iast']!r})")
    if leftover:
        print("LEFTOVER undecoded chars in IAST (add to DECODE):", leftover.most_common())
    else:
        print("IAST charset clean.")

if __name__ == "__main__":
    main()
```

- [ ] **Step 3: Run and complete the decode map**

Run: `python3 bootstrap/extract_vedanta.py`
Expected: `entries: 2394` (±a few), `first iast='a'`. If it prints `LEFTOVER undecoded chars`, each listed character is an unmapped glyph: find an entry using it (`grep` the raw JSON), render that PDF page with the Read tool (vision) to read the correct IAST diacritic, add the mapping to `DECODE`, and re-run. Repeat until it prints `IAST charset clean.`

- [ ] **Step 4: Sanity-check a few entries against the PDF**

Run:
```bash
python3 -c "import json;d=json.load(open('bootstrap/vedanta_raw.json'));[print(repr(x['iast']),'::',x['definition'][:70]) for x in d[:6]]"
```
Expected: clean IAST headwords (`'a'`, `'ā'`, `'abādhita'`, …) and readable English definitions with proper IAST diacritics in embedded terms and no `comp.`/`ind.` left unexpanded.

- [ ] **Step 5: Commit**

```bash
git add bootstrap/extract_vedanta.py bootstrap/vedanta_raw.json
git commit -m "Add bootstrap PDF extractor + raw Vedanta glossary JSON"
```

---

### Task 3: Build `data/vedanta.json` (transliterate)

**Files:**
- Create: `bootstrap/build_vedanta.rb`
- Produces: `data/vedanta.json` = `[{ "iast", "devanagari", "definition" }]`

**Interfaces:**
- Consumes: `bootstrap/vedanta_raw.json`, `IastDevanagari.to_devanagari` (Task 1).
- Produces: committed `data/vedanta.json`.

- [ ] **Step 1: Write the build script**

Create `bootstrap/build_vedanta.rb`:

```ruby
# frozen_string_literal: true

# One-time, DISPOSABLE: bootstrap/vedanta_raw.json -> data/vedanta.json, adding
# the Devanagari column via the committed transliterator. data/vedanta.json is
# the source of truth afterward; re-run only to regenerate from a corrected
# extractor. Run: ruby bootstrap/build_vedanta.rb
require "json"
require_relative "../lib/iast_devanagari"
require_relative "../lib/paths"

raw = JSON.parse(File.read(File.join(__dir__, "vedanta_raw.json")))
out = raw.map do |e|
  {
    "iast" => e["iast"],
    "devanagari" => IastDevanagari.to_devanagari(e["iast"]),
    "definition" => e["definition"]
  }
end
File.write(Paths.data("vedanta.json"), JSON.pretty_generate(out))
puts "Wrote #{out.size} entries to #{Paths.data('vedanta.json')}"
puts "sample: #{out.first(3).map { |e| "#{e['iast']}=#{e['devanagari']}" }.join('  ')}"
```

- [ ] **Step 2: Run it**

Run: `ruby bootstrap/build_vedanta.rb`
Expected: `Wrote 2394 entries ...` and a sample like `a=अ  ā=आ  abādhita=अबाधित`.

- [ ] **Step 3: Commit (first cut — QA will correct it next)**

```bash
git add bootstrap/build_vedanta.rb data/vedanta.json
git commit -m "Build first cut of data/vedanta.json with transliterated Devanagari"
```

---

### Task 4: Structural + round-trip QA (methods A & B)

**Files:**
- Create: `bootstrap/qa_vedanta.rb`

**Interfaces:**
- Consumes: `data/vedanta.json`, `IastDevanagari` (Task 1).
- Produces: a pass/fail report; exit non-zero on any failure.

- [ ] **Step 1: Write the QA script**

Create `bootstrap/qa_vedanta.rb`:

```ruby
# frozen_string_literal: true

# Gating QA over data/vedanta.json (methods A structural + B round-trip).
# Run: ruby bootstrap/qa_vedanta.rb   (exit 0 = clean)
require "json"
require_relative "../lib/iast_devanagari"
require_relative "../lib/paths"

data = JSON.parse(File.read(Paths.data("vedanta.json")))
fail_count = 0
report = lambda { |label, bad| (puts "FAIL #{label}: #{bad.size}"; bad.first(15).each { |b| puts "  #{b}" }; fail_count += bad.size) unless bad.empty? }

iast_ok      = /\A[a-zāīūṛṝḷḹṅñṭḍṇśṣṃḥ'\- ]+\z/
dev_ok       = /\A[ऀ-ॿ \-]+\z/
legacy_chars = /[äéüùñïöàëåçèìòóêí]/
abbrev       = /\b(comp|ind|lit|nom\. sing|p\.p\.p)\.\B|\b(comp|ind|lit)\.(?=\s)/

report.("empty fields", data.select { |e| [e["iast"], e["devanagari"], e["definition"]].any? { |v| v.to_s.strip.empty? } }.map { |e| e["iast"] })
report.("iast charset", data.reject { |e| e["iast"] =~ iast_ok }.map { |e| e["iast"] })
report.("devanagari charset", data.reject { |e| e["devanagari"] =~ dev_ok }.map { |e| "#{e['iast']} -> #{e['devanagari']}" })
report.("legacy glyph in definition", data.select { |e| e["definition"] =~ legacy_chars }.map { |e| e["iast"] })
report.("unexpanded abbreviation", data.select { |e| e["definition"] =~ /\b(comp|ind|lit)\.\s|\bnom\. sing\.|\bp\.p\.p\./ }.map { |e| e["iast"] })

# Duplicate keys
dups = data.group_by { |e| e["iast"] }.select { |_k, v| v.size > 1 }.keys
report.("duplicate iast keys", dups)

# B. Round-trip: to_iast(devanagari) == iast
rt = data.reject { |e| IastDevanagari.to_iast(e["devanagari"]) == e["iast"] }
              .map { |e| "#{e['iast']} -> #{e['devanagari']} -> #{IastDevanagari.to_iast(e['devanagari'])}" }
report.("round-trip mismatch", rt)

puts "entries: #{data.size}"
if fail_count.zero?
  puts "QA A+B CLEAN"
else
  puts "QA A+B FAILURES: #{fail_count}"
  exit 1
end
```

- [ ] **Step 2: Run QA and fix until clean**

Run: `ruby bootstrap/qa_vedanta.rb`
Expected eventually: `QA A+B CLEAN`. For each failure category:
- **iast charset / legacy glyph** → a decode-map gap: add the mapping in `bootstrap/extract_vedanta.py` `DECODE`, re-run Tasks 2–3, re-run QA. (Systematic → fix the tool.)
- **round-trip mismatch** → a transliterator bug: if systematic, fix `lib/iast_devanagari.rb` (+ add a unit test in Task 1's file) and rebuild; if it's a genuine source oddity for one entry, correct that entry directly in `data/vedanta.json`.
- **unexpanded abbreviation / duplicate keys / empty** → fix in `data/vedanta.json` directly (or `ABBREV`/extractor if systematic).

- [ ] **Step 3: Commit the cleaned data + QA tool**

```bash
git add bootstrap/qa_vedanta.rb data/vedanta.json bootstrap/extract_vedanta.py bootstrap/vedanta_raw.json lib/iast_devanagari.rb test/iast_devanagari_test.rb
git commit -m "Add structural+round-trip QA; clean data/vedanta.json to pass A+B"
```

---

### Task 5: Visual cross-reference QA (method C)

**Files:**
- Modify (corrections only): `data/vedanta.json`
- Produces: `bootstrap/qa_visual_report.md` (discrepancy report)

**Interfaces:** consumes the PDF (vision) + `data/vedanta.json`; produces corrections committed into the JSON.

- [ ] **Step 1: Dispatch parallel visual-check subagents**

The PDF is 59 pages (~40 entries/page). Dispatch read-only subagents (Task/Agent tool), one per page range (e.g. 6 agents × ~10 pages), each given: the page range, the `data/vedanta.json` entries whose order corresponds to those pages, and these instructions:

> Render each assigned PDF page (`/tmp/vedanta_glossary.pdf`) with the Read tool. For every glossary entry on the page, compare the **printed Devanagari** and **printed IAST headword** to the corresponding `data/vedanta.json` record (matched in order by IAST). Return a JSON list of mismatches: `{iast, field: "devanagari"|"iast", pdf_form, json_form, note}`. Also flag any entry present in the PDF but missing from the JSON (or vice-versa). Spot-check that definitions read sensibly. Do not edit files.

Collect all mismatches into `bootstrap/qa_visual_report.md`.

- [ ] **Step 2: Triage and fix**

For each reported mismatch:
- **Systematic transliterator error** (same wrong rule across many words) → fix `lib/iast_devanagari.rb`, add a unit test, rebuild (`ruby bootstrap/build_vedanta.rb`), re-run Task 4 QA.
- **Decode-map error** (wrong IAST diacritic across entries) → fix `DECODE`, re-run Tasks 2–4.
- **One-off** (incl. the 2 known multi-word entries `a`/`an` and `dyo`) → correct the record directly in `data/vedanta.json`.

- [ ] **Step 3: Re-verify and converge**

Re-run `ruby bootstrap/qa_vedanta.rb` (must stay `QA A+B CLEAN`) and re-dispatch visual checks for any pages whose entries changed, until the discrepancy report has only explained residue (the 2 multi-word entries). Record the final state in `bootstrap/qa_visual_report.md`.

- [ ] **Step 4: Commit**

```bash
git add data/vedanta.json bootstrap/qa_visual_report.md lib/iast_devanagari.rb test/iast_devanagari_test.rb
git commit -m "Visual cross-reference QA: corrections to data/vedanta.json"
```

---

### Task 6: Loader, generator, deck wiring (build the deck)

**Files:**
- Modify: `lib/anki.rb` (add `VEDANTA_DECK`)
- Create: `lib/vedanta.rb`, `lib/generators/vedanta.rb`
- Modify: `main.rb`
- Test: `test/vedanta_test.rb`

**Interfaces:**
- Consumes: `data/vedanta.json` (QA-clean), `Anki::VEDANTA_DECK`, `Generators::Base`.
- Produces: `Generators::Vedanta` — `KEY="vedanta"`, `card(entry) -> ["vedanta:<iast>", front, back]`, `deck == Anki::VEDANTA_DECK`, `requires_letters? == false`, `audio_files == []`.

- [ ] **Step 1: Add the deck constant**

In `lib/anki.rb`, after the `GITA_DECK` line, add:

```ruby
  # The Vedanta glossary word deck (a separate deck).
  VEDANTA_DECK = "🕉️ Vedanta Glossary"
```

- [ ] **Step 2: Write the loader**

Create `lib/vedanta.rb`:

```ruby
# frozen_string_literal: true

require "json"
require_relative "paths"

# Loads data/vedanta.json (the committed source of truth for the Vedanta glossary
# word deck). Pure reader, mirroring Letters/Gita.
module Vedanta
  def self.load(path = Paths.data("vedanta.json"))
    unless File.exist?(path)
      abort "ERROR: #{path} not found."
    end

    JSON.parse(File.read(path))
  end
end
```

- [ ] **Step 3: Write the failing generator test**

Create `test/vedanta_test.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/generators/vedanta"

class VedantaTest < Minitest::Test
  def entry
    { "iast" => "mokṣaḥ", "devanagari" => "मोक्षः", "definition" => "Liberation; release." }
  end

  def gen = Generators::Vedanta.new([], {})

  def test_deck_is_vedanta
    assert_equal Anki::VEDANTA_DECK, gen.deck
  end

  def test_does_not_require_letters
    refute Generators::Vedanta.requires_letters?
  end

  def test_no_audio
    assert_empty gen.audio_files([entry])
  end

  def test_card_key_front_back
    key, front, back = gen.card(entry)
    assert_equal "vedanta:mokṣaḥ", key
    assert_includes front, "मोक्षः"
    refute_includes front, "style="
    assert_includes back, "mokṣaḥ"
    assert_includes back, "Liberation; release."
    refute_includes back, "\n"
  end
end
```

- [ ] **Step 4: Run test to verify it fails**

Run: `ruby test/vedanta_test.rb`
Expected: FAIL — `LoadError: cannot load such file -- ../lib/generators/vedanta`.

- [ ] **Step 5: Write the generator**

Create `lib/generators/vedanta.rb`:

```ruby
# frozen_string_literal: true

require_relative "base"
require_relative "../vedanta"

module Generators
  # Vedanta glossary word deck. Pure transform over data/vedanta.json (the
  # committed source of truth). One card per term:
  #   Front: the Devanagari term (large, centered)
  #   Back:  IAST + English definition
  # No audio.
  class Vedanta < Base
    KEY         = "vedanta"
    DESCRIPTION = "Vedanta glossary terms (Devanagari -> IAST + meaning)"
    OUTPUT_TXT  = "sanskrit_vedanta_anki.txt"

    def self.requires_letters? = false
    def deck = Anki::VEDANTA_DECK

    def build = ::Vedanta.load

    def card(entry)
      iast = entry["iast"]
      key  = "vedanta:#{iast}"
      front = "<center><big>#{br(entry['devanagari'])}</big></center>"
      back  = "<b>#{br(iast)}</b><br><br>#{br(entry['definition'].to_s)}"
      [key, front, back]
    end

    private

    def br(text)
      text.to_s.gsub(/\r?\n/, "<br>")
    end
  end
end
```

- [ ] **Step 6: Run test to verify it passes**

Run: `ruby test/vedanta_test.rb`
Expected: PASS (4 runs, 0 failures).

- [ ] **Step 7: Register in main.rb**

In `main.rb`, after `require_relative "lib/generators/gita_verses"` add:

```ruby
require_relative "lib/generators/vedanta"
```

And add `Generators::Vedanta` as the last entry of the `GENERATORS` array:

```ruby
GENERATORS = [
  Generators::Basic,
  Generators::Combinations,
  Generators::Conjuncts,
  Generators::Anusvara,
  Generators::GitaVerses,
  Generators::Vedanta
].freeze
```

- [ ] **Step 8: Generate the deck and spot-check**

Run: `./main.rb --vedanta`
Expected: `Generating vedanta...`, `~2394 cards -> sanskrit_vedanta_anki.txt`, no audio prompt, `Cards land in deck(s): 🕉️ Vedanta Glossary`, no "Loaded N letters" line.

Run:
```bash
ruby -e 'l=File.readlines("sanskrit_vedanta_anki.txt").reject{|x|x.start_with?("#")}; puts "rows=#{l.size}"; puts "bad_cols=#{l.count{|r| r.split("\t").size!=3}}"; c=l.find{|r|r.start_with?("vedanta:mokṣaḥ\t")}; puts c'
grep -m1 '^#deck' sanskrit_vedanta_anki.txt
```
Expected: `rows`≈2394; `bad_cols=0`; the `mokṣaḥ` row shows Devanagari front + IAST/definition back; deck header `#deck:🕉️ Vedanta Glossary`.

- [ ] **Step 9: Commit**

```bash
git add lib/anki.rb lib/vedanta.rb lib/generators/vedanta.rb test/vedanta_test.rb main.rb sanskrit_vedanta_anki.txt
git commit -m "Add Vedanta glossary deck: loader, generator, wiring"
```

---

### Task 7: Documentation

**Files:**
- Modify: `CLAUDE.md`, `README.md`

- [ ] **Step 1: Update CLAUDE.md commands + add a section**

In `CLAUDE.md` Commands block, the Vedanta deck has no networked fetch in the runtime (the JSON is committed), so no new `ruby fetch_*` line is required; add a one-time-build note. After the "### The Bhagavad Gita verse deck" section, add:

```markdown
### The Vedanta glossary word deck

A third deck (`🕉️ Vedanta Glossary`, `Anki::VEDANTA_DECK`) of ~2,394 single Sanskrit terms — front: Devanagari; back: IAST + English meaning; no audio. Unlike the other decks there is **no committed networked fetch**: `data/vedanta.json` is the **source of truth**, built once from the arshabodha "Vedanta-Sanskrit Glossary" PDF (Swami Dayananda) by the disposable scripts in `bootstrap/` and then hand-corrected. The PDF's Devanagari is an unrecoverable glyph font, so `bootstrap/extract_vedanta.py` (Python + pypdf) recovers only the IAST headword (via a WinAnsi→IAST decode map) and English definition by font, and `lib/iast_devanagari.rb` regenerates the Devanagari by transliteration. `bootstrap/qa_vedanta.rb` runs structural + round-trip QA; a visual cross-reference against the PDF was used to finalize the JSON. The `bootstrap/` scripts are not part of the runtime and may be removed.

`lib/iast_devanagari.rb` is a committed, tested IAST↔Devanagari transliterator (forward + reverse), reusable beyond this deck. `lib/generators/vedanta.rb` (`--vedanta`) is a pure transform over `data/vedanta.json` (via `Vedanta.load`, `lib/vedanta.rb`): key `vedanta:<iast>`, no audio, `requires_letters? == false`.
```

- [ ] **Step 2: Update README.md**

Add a `--vedanta` row to the categories table:

```markdown
| `--vedanta` | `sanskrit_vedanta_anki.txt` | ~2394 | Vedanta glossary terms (separate **🕉️ Vedanta Glossary** deck): Devanagari front, IAST + English meaning back. No audio. Source data committed in `data/vedanta.json`. |
```

And a short section:

```markdown
### Vedanta glossary word deck

```bash
./main.rb --vedanta            # generate sanskrit_vedanta_anki.txt
```

A deck of ~2,394 common Vedanta Sanskrit terms (front: Devanagari; back: IAST + English meaning), built from Swami Dayananda Saraswati's Vedanta-Sanskrit glossary. The term data lives in `data/vedanta.json` (already committed), so no fetch step is needed.
```

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md README.md
git commit -m "Document the Vedanta glossary word deck"
```

---

## Self-Review

**Spec coverage:**
- Source (arshabodha PDF) + font roles → Task 2. ✓
- IAST decode map (seed + derive via QA) → Task 2 Steps 2–3. ✓
- Devanagari via transliteration; transliterator kept + tested + reverse → Task 1. ✓
- `data/vedanta.json` as source of truth; fixes in JSON → Tasks 3–5. ✓
- Multi-word entries fixed in JSON → Task 5 Step 2. ✓
- Abbreviations expanded → Task 2 (`ABBREV`). ✓
- Page-1 header skipped → Task 2 (entry-row rule). ✓
- QA A (structural) + B (round-trip) gating → Task 4. ✓
- QA C (visual cross-reference, parallel agents, both Devanagari + IAST) → Task 5. ✓
- Generation only after QA clean → Task 6 ordered after Tasks 4–5. ✓
- Deck/card/key/no-audio/requires_letters → Task 6. ✓
- Bootstrap disposable; runtime minimal → File Structure + Task 7. ✓
- Docs → Task 7. ✓

**Placeholder scan:** The only intentionally-incomplete artifact is the `DECODE` map in Task 2, which is explicitly a seed completed by a concrete derive-and-validate loop gated by QA (charset check) — not a vague placeholder. All Ruby code (transliterator, loader, generator, QA) is complete. ✓

**Type consistency:** `IastDevanagari.to_devanagari`/`to_iast`; record keys `iast`/`devanagari`/`definition` consistent across extractor → build → QA → generator; `Vedanta.load`; generator `card` returns `[key, front, back]`; `Anki::VEDANTA_DECK`. ✓

**Note:** entry count (~2,394) is approximate; the exact number from extraction is whatever the PDF yields and is validated by QA coverage, not asserted to an exact constant.
