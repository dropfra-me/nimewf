import std/os
import std/times
import nimewf

proc mkBase*(prefix: string): string =
  getTempDir() / (prefix & $(epochTime().int))

proc segPath*(base: string): string =
  var p = base & ".E01"
  if not fileExists(p): p = base & ".e01"
  p

proc segPathIdx*(base: string, idx: int): string =
  # Additional segments are numbered starting at E02 for idx=1, E03 for idx=2, etc.
  let n = idx + 1
  let ext = ".E" & (if n < 10: "0" & $n else: $n)
  var p = base & ext
  if not fileExists(p):
    let ext2 = ".e" & (if n < 10: "0" & $n else: $n)
    p = base & ext2
  p

proc acquireImage*(base: string, size: int, fmt: Format, segmentSize: uint64, bps: uint32 = 512'u32, compress = false): tuple[hashes: HashesHex, size: int] =
  var h = newHandle()
  if h == nil: return
  if not openForWrite(h, base): return
  applyRecommendedDefaults(h)
  discard setFormat(h, fmt)
  discard setBytesPerSector(h, bps)
  discard setMaximumSegmentSize(h, segmentSize)
  discard setMediaSize(h, uint64(size))
  if compress:
    discard setCompressionValues(h, clFast, {compressEmptyBlock})
  var buf = newSeq[byte](size)
  for i in 0 ..< size: buf[i] = byte(i and 0xFF)
  let (wrote, hs) = writeAndHash(h, buf)
  discard setStoredHashes(h, hs)
  discard finalizeWrite(h)
  discard close(h)
  discard freeHandle(h)
  (hs, wrote)
