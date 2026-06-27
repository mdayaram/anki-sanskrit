#!/usr/bin/env python3
"""One-time, DISPOSABLE extractor: arshabodha Vedanta glossary PDF -> raw JSON.

Separates each entry row by font: TT2CEt00 = IAST headword, TT2CDt00 = Devanagari
(discarded — unrecoverable glyph font), TT2D1t00 = English definition, TT2D0t00 =
italic (abbreviations + IAST cross-refs). Devanagari is regenerated later by the
Ruby transliterator. Not robust by design; residual errors are fixed in
data/vedanta.json. Run: python3 bootstrap/extract_vedanta.py
"""
import json, re, collections
import pypdf

PDF = "/tmp/vedanta_glossary.pdf"
OUT = "bootstrap/vedanta_raw.json"

HEAD, DEV, DEF, ITAL = "TT2CEt00", "TT2CDt00", "TT2D1t00", "TT2D0t00"

# WinAnsi-glyph -> IAST decode map for the Times-style IAST fonts. Seeded with
# CONFIRMED mappings (from sampled entries vs the rendered PDF); completed during
# execution from the "LEFTOVER" report below.
DECODE = {
    "ä": "ā", "é": "ī", "ü": "ū", "ù": "ḥ", "ñ": "ṣ", "ï": "ñ",
    "ç": "ś", "ë": "ṇ", "å": "ṛ", "ö": "ṭ", "à": "ṃ", "ì": "ṅ", "ò": "ḍ",
}

# Word-boundary-anchored so "ind." inside "mind."/"kind."/"Blind." is NOT expanded.
# Allows an optional space before the dot (a pypdf artifact: "ind .").
ABBREV = [
    (r"\bnom\s*\.\s*sing\s*\.", "nominative singular"),
    (r"\bp\s*\.\s*p\s*\.\s*p\s*\.", "past passive participle"),
    (r"\bcomp\s*\.", "compound"),
    (r"\bind\s*\.", "indeclinable"),
    (r"\blit\s*\.", "literally"),
]

IAST_OK = re.compile(r"[a-zāīūṛṝḷḹṅñṭḍṇśṣṃḥ'\- ]")


def decode_iast(s):
    return "".join(DECODE.get(c, c) for c in s)


def expand_abbrev(text):
    for pat, v in ABBREV:
        text = re.sub(pat, v, text)
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

    ordered = sorted(rows.items(), key=lambda kv: (kv[0][0], -kv[0][1]))

    entries = []
    current = None
    for (page, y), chunks in ordered:
        chunks.sort()  # by x
        is_entry = chunks and chunks[0][1] == HEAD and 86 <= chunks[0][0] <= 94
        # Definition includes regular text (DEF), italics (ITAL), and inline bold
        # Sanskrit forms (HEAD) that appear *after* the headword (verb conjugations,
        # alternate forms). Only the Devanagari column (DEV) is dropped. HEAD/ITAL
        # text is IAST and decoded.
        if is_entry:
            if current:
                entries.append(current)
            iast = decode_iast(chunks[0][2].strip())
            def_parts = [decode_iast(t) for x, f, t in chunks[1:] if f in (HEAD, DEF, ITAL)]
            current = {"iast": iast, "def_parts": def_parts}
        elif current is not None:
            for x, f, t in chunks:
                if f in (HEAD, DEF, ITAL):
                    current["def_parts"].append(decode_iast(t))
    if current:
        entries.append(current)

    out = []
    for e in entries:
        definition = expand_abbrev(re.sub(r"\s+", " ", " ".join(e["def_parts"]).strip()))
        out.append({"iast": e["iast"], "definition": definition})

    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)

    leftover = collections.Counter(
        c for e in out for c in e["iast"] if not IAST_OK.match(c)
    )
    print(f"entries: {len(out)}  (first iast={out[0]['iast']!r})")
    if leftover:
        print("LEFTOVER undecoded chars in IAST headwords (add to DECODE):")
        for c, n in leftover.most_common():
            # show one example headword using this char
            ex = next(e["iast"] for e in out if c in e["iast"])
            print(f"  U+{ord(c):04X} {c!r} x{n}   e.g. {ex!r}")
    else:
        print("IAST headword charset clean.")


if __name__ == "__main__":
    main()
