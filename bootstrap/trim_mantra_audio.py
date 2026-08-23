import wave, array, sys, math

src, dst, t0, t1, fin, fout = sys.argv[1], sys.argv[2], *map(float, sys.argv[3:7])
w = wave.open(src, "rb")
sr, ch, sw, n = w.getframerate(), w.getnchannels(), w.getsampwidth(), w.getnframes()
assert sw == 2, sw
a = array.array("h"); a.frombytes(w.readframes(n))

i0, i1 = int(t0 * sr) * ch, int(t1 * sr) * ch
seg = a[i0:i1]

# linear fades, applied per-frame so channels stay in step
nin, nout = int(fin * sr), int(fout * sr)
total = len(seg) // ch
for f in range(nin):
    g = f / nin
    for c in range(ch): seg[f * ch + c] = int(seg[f * ch + c] * g)
for f in range(nout):
    g = f / nout
    j = total - 1 - f
    for c in range(ch): seg[j * ch + c] = int(seg[j * ch + c] * g)

o = wave.open(dst, "wb")
o.setnchannels(ch); o.setsampwidth(sw); o.setframerate(sr)
o.writeframes(seg.tobytes()); o.close()
print("%s  %.2f s" % (dst, total / sr))
