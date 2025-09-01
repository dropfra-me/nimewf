import unittest
import std/os
import tests/support
import nimewf

suite "segmentation":
  test "forces multiple segments and verifies (best-effort)":
    let base = mkBase("nimewf_seg_")
    let segSize = 1024'u64
    # Use a total size that's an exact multiple of bytes-per-sector to avoid truncation on readback.
    let total = 3 * 1024  # 3 full segments
    let (hs, sz) = acquireImage(base, total, fmtEwf, segSize)
    # Enumerate produced segments for diagnostics (some builds ignore too-small seg sizes)
    var produced = 1
    var idx = 1
    while fileExists(segPathIdx(base, idx)):
      inc produced
      inc idx
    echo "[seg] produced segments=", produced, " (segSize=", segSize, ")"
    let seg = segPath(base)
    let res = verify(seg)
    check res.checksumErrors == 0
    check res.bytesRead == sz
    check res.md5 == hs.md5

  test "partial last segment (exact sector multiple, best-effort)":
    let base = mkBase("nimewf_seg_partial_")
    let segSize = 1024'u64
    let total = 3 * 1024 + 512  # 3.5 segments, still multiple of 512
    let (hs, sz) = acquireImage(base, total, fmtEwf, segSize)
    var produced2 = 1
    var idx2 = 1
    while fileExists(segPathIdx(base, idx2)):
      inc produced2
      inc idx2
    echo "[seg] produced segments=", produced2, " (segSize=", segSize, ")"
    let res = verify(segPath(base))
    check res.checksumErrors == 0
    check res.bytesRead == sz
    check res.md5 == hs.md5
