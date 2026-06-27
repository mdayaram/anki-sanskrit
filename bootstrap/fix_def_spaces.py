#!/usr/bin/env python3
"""Fix spurious intra-word spaces in data/vedanta.json definitions (pypdf artifact).

Ground truth = pdftotext extraction of the PDF (clean word spacing). Build the
PDF's word unigrams + bigrams; for each adjacent word-pair (a,b) in a definition,
merge to "ab" only when "ab" occurs in the PDF and the bigram "a b" does NOT
(so real word pairs are never merged). Iterates to catch multi-way splits.

Usage: python3 bootstrap/fix_def_spaces.py [--apply]
"""
import json, re, sys

VED = "data/vedanta.json"
CLEAN = "/tmp/vg_clean.txt"
apply = "--apply" in sys.argv

clean = open(CLEAN, encoding="utf-8", errors="replace").read().lower()
tokens = re.findall(r"[a-z]+", clean)
UNI = set(tokens)
BI = set(zip(tokens, tokens[1:]))

word = re.compile(r"^[A-Za-z]+$")

def fix(defn):
    changed = []
    for _ in range(5):  # iterate for multi-splits
        parts = defn.split(" ")
        out = []
        i = 0
        merged_any = False
        while i < len(parts):
            if i + 1 < len(parts):
                a, b = parts[i], parts[i + 1]
                # strip trailing/leading punctuation for the lexical test
                am = re.search(r"[A-Za-z]+$", a)
                bm = re.match(r"^[A-Za-z]+", b)
                if am and bm:
                    al, bl = am.group().lower(), bm.group().lower()
                    joined = al + bl
                    if (al, bl) not in BI and joined in UNI and joined not in (al, bl):
                        merged = a + b  # remove the space, keep punctuation
                        out.append(merged)
                        changed.append((f"{a} {b}", merged))
                        i += 2
                        merged_any = True
                        continue
            out.append(parts[i])
            i += 1
        defn = " ".join(out)
        if not merged_any:
            break
    return defn, changed

data = json.load(open(VED))
allchanges = []
for e in data:
    new, ch = fix(e["definition"])
    if ch:
        allchanges.append((e["iast"], e["definition"], new))
        e["definition"] = new

print(f"definitions changed: {len(allchanges)}")
for iast, old, new in allchanges:
    print(f"\n[{iast}]\n  - {old}\n  + {new}")

if apply:
    json.dump(data, open(VED, "w"), ensure_ascii=False, indent=2)
    print(f"\nAPPLIED to {VED}")
else:
    print("\n(dry run — pass --apply to write)")
