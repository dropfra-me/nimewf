import std/os
import std/times
import nimewf

proc mkBase*(prefix: string): string =
  getTempDir() / (prefix & $(epochTime().int))

proc segPath*(base: string): string =
  ## Returns the first segment path, trying common extensions.
  for ext in [".E01", ".e01", ".Ex01", ".ex01"]:
    let p = base & ext
    if fileExists(p): return p
  # Default to classic lower-case if nothing exists yet (writer will create one).
  base & ".e01"

proc segPathIdx*(base: string, idx: int): string =
  # Additional segments: E02/e02 for classic; Ex02/ex02 for EWF-X.
  let n = idx + 1
  for ext in [
    ".E" & (if n < 10: "0" & $n else: $n),
    ".e" & (if n < 10: "0" & $n else: $n),
    ".Ex" & (if n < 10: "0" & $n else: $n),
    ".ex" & (if n < 10: "0" & $n else: $n)
  ]:
    let p = base & ext
    if fileExists(p): return p
  # Default to classic lower-case
  base & ".e" & (if n < 10: "0" & $n else: $n)

proc countSegments*(base: string): int =
  ## Counts how many segments exist starting at E01/e01.
  result = 0
  if fileExists(segPath(base)):
    result = 1
    var idx = 1
    while fileExists(segPathIdx(base, idx)):
      inc result
      inc idx

proc acquireImage*(base: string, size: int, fmt: Format, segmentSize: uint64, bps: uint32 = 512'u32, compress = false): tuple[hashes: HashesHex, size: int] =
  var h = newHandle()
  if h == nil: return
  if not openForWrite(h, base): return
  applyRecommendedDefaults(h)
  discard setFormat(h, fmt)
  discard setBytesPerSector(h, bps)
  discard setMaximumSegmentSize(h, segmentSize)
  discard tuneChunkForSegment(h)
  discard setMediaSize(h, uint64(size))
  if compress:
    discard setCompressionValues(h, clFast, {compressEmptyBlock})
  var buf = newSeq[byte](size)
  for i in 0 ..< size: buf[i] = byte(i and 0xFF)
  let (wrote, hs) = writeAndHash(h, buf)
  discard finalizeWrite(h)
  discard setStoredHashes(h, hs)
  discard close(h)
  discard freeHandle(h)
  (hs, wrote)
