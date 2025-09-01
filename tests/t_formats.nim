import unittest
import tests/support
import nimewf

suite "formats smoke":
  test "fmtEwf and fmtEwfx basic write/verify":
    for f in [fmtEwf, fmtEwfx]:
      let base = mkBase("nimewf_fmt_")
      let (hs, sz) = acquireImage(base, 1024, f, 1500'u64 * 1024 * 1024)
      let seg = segPath(base)
      let res = verify(seg)
      check res.checksumErrors == 0
      check res.bytesRead == sz
      check res.md5 == hs.md5

