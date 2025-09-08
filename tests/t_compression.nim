import unittest
# no extra std modules
import nimewf/handle
import nimewf/options
import nimewf/writer
import nimewf/verify
import nimewf/types
import nimewf/ffi
import tests/support


proc acquireWithCompression(base: string, size: int, fmt: Format, segSize: uint64, level: CompressionLevel, flags: set[CompressionFlag]): tuple[hashes: HashesHex, size: int] =
  var h = newHandle()
  if h == nil: return
  if not openForWrite(h, base): return
  applyRecommendedDefaults(h)
  discard setFormat(h, fmt)
  discard setBytesPerSector(h, 512'u32)
  discard setMaximumSegmentSize(h, segSize)
  discard tuneChunkForSegment(h)
  discard setMediaSize(h, uint64(size))
  discard setCompressionValues(h, level, flags)
  # generate data in-memory for stability
  var buf = newSeq[byte](size)
  for i in 0 ..< buf.len: buf[i] = byte((i * 31) and 0xFF)
  let (wrote, hs) = writeAndHash(h, buf)
  discard finalizeWrite(h)
  discard setStoredHashes(h, hs)
  discard close(h)
  discard freeHandle(h)
  (hs, wrote)

suite "compression matrix":
  echo "[comp] libewf version=", $libewf_get_version()
  test "encase7 and ewfx single-segment integrity":
    let mediaSize = 64 * 1024 * 1024 # 64 MiB
    let segSize = 256'u64 * 1024 * 1024 # single segment for strict integrity
    let cases = [
      (clNone, {}),
      (clFast, {compressEmptyBlock}),
      (clBest, {compressEmptyBlock}),
    ]
    for f in [fmtEncase7, fmtEwfx]:
      for (lvl, flg) in cases:
        let base = mkBase("nimewf_comp_ss_" & $ord(f) & "_" & $(int(lvl)) & "_")
        let (hs, sz) = acquireWithCompression(base, mediaSize, f, segSize, lvl, flg)
        let seg = segPath(base)
        let res = verify(seg)
        check res.checksumErrors == 0
        check res.bytesRead == sz
        check res.md5 == hs.md5

  test "encase7 and ewfx multi-segment best-effort":
    let mediaSize = 64 * 1024 * 1024 # 64 MiB
    let segSize = 32'u64 * 1024 * 1024 # 32 MiB -> ~2 segments
    let cases = [
      (clNone, {}),
      (clFast, {compressEmptyBlock}),
      (clBest, {compressEmptyBlock}),
    ]
    for f in [fmtEncase7, fmtEwfx]:
      for (lvl, flg) in cases:
        let base = mkBase("nimewf_comp_ms_" & $ord(f) & "_" & $(int(lvl)) & "_")
        let (hs, sz) = acquireWithCompression(base, mediaSize, f, segSize, lvl, flg)
        let seg = segPath(base)
        let produced = countSegments(base)
        echo "[comp] f=", ord(f), " lvl=", int(lvl), " produced=", produced, " seg=", seg
        let res = verify(seg)
        check res.bytesRead == sz
        if res.checksumErrors == 0:
          check res.md5 == hs.md5
