#!/usr/bin/env python3
"""One-time QA: cross-check data/vedanta.json headwords against Monier-Williams.

Builds a set of valid MW headwords (from the Cologne TEI, SLP1 -> Devanagari) and
checks each of our entries' stem against it. Flags entries not found, with the
nearest MW headword (edit distance) for short words as a possible-typo hint.
Run: python3 bootstrap/mw_crosscheck.py
"""
import json, re, glob, collections, os

TEI_DIR = "/tmp/mwtei"
VED = "data/vedanta.json"
REPORT = "bootstrap/mw_crosscheck_report.md"

SLP1_V = {'a':('अ',''),'A':('आ','ा'),'i':('इ','ि'),'I':('ई','ी'),'u':('उ','ु'),
 'U':('ऊ','ू'),'f':('ऋ','ृ'),'F':('ॠ','ॄ'),'x':('ऌ','ॢ'),'X':('ॡ','ॣ'),
 'e':('ए','े'),'E':('ऐ','ै'),'o':('ओ','ो'),'O':('औ','ौ')}
SLP1_C = {'k':'क','K':'ख','g':'ग','G':'घ','N':'ङ','c':'च','C':'छ','j':'ज','J':'झ',
 'Y':'ञ','w':'ट','W':'ठ','q':'ड','Q':'ढ','R':'ण','t':'त','T':'थ','d':'द','D':'ध',
 'n':'न','p':'प','P':'फ','b':'ब','B':'भ','m':'म','y':'य','r':'र','l':'ल','v':'व',
 'S':'श','z':'ष','s':'स','h':'ह','L':'ळ'}
MARKS = {'M':'ं','H':'ः','~':'ँ',"'":'ऽ'}
VIR = '्'

def slp1_to_dev(s):
    out=[]; pend=False
    for ch in s:
        if ch in SLP1_C:
            if pend: out.append(VIR)
            out.append(SLP1_C[ch]); pend=True
        elif ch in SLP1_V:
            ind,m=SLP1_V[ch]; out.append(m if pend else ind); pend=False
        elif ch in MARKS:
            pend=False; out.append(MARKS[ch])
        else:
            if pend: out.append(VIR); pend=False
            # ignore accents/punctuation
    if pend: out.append(VIR)
    return ''.join(out)

# 1. Build MW Devanagari headword set from all <orth ana="key1" ...SLP1...> forms.
orth_re = re.compile(r'<orth ana="key1"[^>]*>([^<]*)</orth>')
mw_slp1=set()
for fn in glob.glob(os.path.join(TEI_DIR,"mw_*.tei")):
    txt=open(fn,encoding="utf-8",errors="replace").read()
    for m in orth_re.findall(txt):
        w=re.sub(r'[^a-zA-ZfFxXMH~\']','',m)  # keep SLP1 letters/marks
        if w: mw_slp1.add(w)
mw_dev=set(slp1_to_dev(w) for w in mw_slp1)
print(f"MW headwords: {len(mw_slp1)} SLP1 -> {len(mw_dev)} Devanagari")

# bucket MW Devanagari by first char for nearest-neighbor
buckets=collections.defaultdict(list)
for w in mw_dev:
    if w: buckets[w[0]].append(w)

def stems(dev):
    c={dev}
    base = dev[:-1] if dev.endswith('ः') else dev   # drop visarga
    c.add(base)
    if base.endswith('ं'): c.add(base[:-1])
    if base.endswith('म्'): c.add(base[:-2])         # neuter -am -> stem
    # common nominative/sandhi reversions to the MW lemma:
    if base.endswith('ी'): c.add(base[:-1]+'िन्')    # -ī  -> -in  (adhikārī->adhikārin)
    if base.endswith('ा'):
        c.add(base[:-1]+'ृ')                         # -ā  -> -ṛ   (kartā->kartṛ)
        c.add(base[:-1]+'न्')                        # -ā  -> -an  (ātmā->ātman)
        c.add(base[:-1])                             # -ā  -> -a
    for a,b in (('द्','त्'),('ब्','प्'),('ग्','क्'),('ड्','ट्')):  # final voicing sandhi
        if base.endswith(a): c.add(base[:-len(a)]+b)
    return c

def lev(a,b):
    if abs(len(a)-len(b))>2: return 99
    prev=list(range(len(b)+1))
    for i,ca in enumerate(a,1):
        cur=[i]
        for j,cb in enumerate(b,1):
            cur.append(min(prev[j]+1,cur[j-1]+1,prev[j-1]+(ca!=cb)))
        prev=cur
    return prev[-1]

ved=json.load(open(VED))
matched=0; unmatched=[]
for e in ved:
    if stems(e["devanagari"]) & mw_dev:
        matched+=1
    else:
        unmatched.append(e)

print(f"entries: {len(ved)}  matched in MW: {matched}  unmatched: {len(unmatched)}")

# For SHORT unmatched (likely single words, not compounds), find nearest MW word.
suspects=[]
others=[]
for e in unmatched:
    dev=e["devanagari"]
    base=dev[:-1] if dev.endswith('ः') else dev
    if len(base)<=9:  # short -> likely a single word worth checking
        best=None;bd=99
        for w in buckets.get(base[0] if base else '', []):
            d=lev(base,w)
            if d<bd: bd=d;best=w
        suspects.append((e,best,bd))
    else:
        others.append(e)

# Missing/wrong-diacritic detector: toggle vowel length (and a few diacritics) one
# at a time; if a variant IS a MW headword, our form is very likely an error.
TOGGLE = [('ि','ी'),('ी','ि'),('ु','ू'),('ू','ु'),('ृ','ॄ'),('आ','अ'),('अ','आ'),
          ('ई','इ'),('इ','ई'),('ऊ','उ'),('उ','ऊ'),('श','स'),('स','श'),('ष','स')]
def variant_hits(base):
    hits=set()
    # single-substitution variants
    for i,ch in enumerate(base):
        for a,b in TOGGLE:
            if ch==a:
                v=base[:i]+b+base[i+1:]
                if v in mw_dev: hits.add(v)
    # inherent-a -> ā: insert ा after each consonant-ish position
    for i in range(1,len(base)+1):
        v=base[:i]+'ा'+base[i:]
        if v in mw_dev: hits.add(v)
    return hits

likely_errors=[]
for e in unmatched:
    base = e["devanagari"][:-1] if e["devanagari"].endswith('ः') else e["devanagari"]
    h=variant_hits(base)
    if h: likely_errors.append((e, sorted(h)))

suspects.sort(key=lambda t:t[2])
with open(REPORT,"w",encoding="utf-8") as f:
    f.write(f"# Monier-Williams cross-check report\n\n")
    f.write(f"- MW headwords loaded: {len(mw_dev)}\n- Our entries: {len(ved)}\n")
    f.write(f"- Matched a MW headword (stem): {matched}\n- Not found: {len(unmatched)} "
            f"(short/single-word: {len(suspects)}, long/compound: {len(others)})\n\n")
    f.write(f"## LIKELY ERRORS: a vowel-length/diacritic variant IS a MW headword ({len(likely_errors)})\n\n")
    f.write("| our IAST | our Devanagari | MW variant(s) | definition |\n|---|---|---|---|\n")
    for e,h in likely_errors:
        f.write(f"| {e['iast']} | {e['devanagari']} | {', '.join(h)} | {e['definition'][:50]} |\n")
    f.write("\n## Short words not found in MW — review (nearest MW headword shown)\n\n")
    f.write("| our IAST | our Devanagari | nearest MW | edit dist | definition |\n|---|---|---|---|---|\n")
    for e,best,bd in suspects:
        f.write(f"| {e['iast']} | {e['devanagari']} | {best or '—'} | {bd if bd<99 else '—'} | {e['definition'][:50]} |\n")
    f.write(f"\n## Long / compound words not found in MW ({len(others)}) — expected (compounds/inflected)\n\n")
    for e in others[:99999]:
        f.write(f"- {e['iast']} ({e['devanagari']}) — {e['definition'][:50]}\n")

print(f"wrote {REPORT}")
print(f"short suspects: {len(suspects)} (closest-match first)")
for e,best,bd in suspects[:25]:
    print(f"  d={bd} {e['iast']!r} {e['devanagari']} ~ MW {best}")
