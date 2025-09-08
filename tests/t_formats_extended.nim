import unittest
import tests/support
import nimewf

suite "format matrix":
  test "basic write/verify across common formats":
    # Use a modest media size to stay within 1 segment and avoid edge cases.
    let mediaSize = 512 * 1024 # 512 KiB
    let segSize = 64'u64 * 1024 * 1024 # 64 MiB segments
    for f in [fmtEncase6, fmtEncase7, fmtFtkImager, fmtSmart, fmtLinen6, fmtLinen7, fmtEwf, fmtEwfx]:
      let base = mkBase("nimewf_fmt_ext_")
      let (hs, sz) = acquireImage(base, mediaSize, f, segSize)
      let seg = segPath(base)
      let res = verify(seg)
      check res.checksumErrors == 0
      check res.bytesRead == sz
      check res.md5 == hs.md5

