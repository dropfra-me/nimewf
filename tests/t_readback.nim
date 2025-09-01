import unittest
import os, times
import nimewf

proc makeSegPath(base: string): string =
  var p = base & ".E01"
  if not fileExists(p): p = base & ".e01"
  return p

suite "readback behavior":
  test "minimum media: 1 sector readable (bps=512)":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_tiny_" & $(epochTime().int))
    require openForWrite(h, base)
    discard setFormat(h, fmtEwf)
    discard setMediaType(h, mediaFixed)
    discard setMediaFlags(h, {})
    discard setCompressionValues(h, clNone, {})
    discard setMaximumSegmentSize(h, 64'u64 * 1024 * 1024)
    discard setBytesPerSector(h, 512'u32)
    let sz = 512
    check setMediaSize(h, uint64(sz))
    var buf = newSeq[byte](sz)
    for i in 0 ..< buf.len: buf[i] = byte(i and 0xFF)
    let (_, hs) = writeAndHash(h, buf)
    discard setStoredHashes(h, hs)
    discard finalizeWrite(h)
    discard close(h)
    discard freeHandle(h)
    let seg = makeSegPath(base)
    let res = verify(seg)
    echo "[rb] bps=512 sz=", sz, " bytesRead=", res.bytesRead, " md5=", res.md5
    check res.bytesRead == sz
    check res.md5 == hs.md5

  test "1KiB media readable with default bytesPerSector":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_kib_" & $(epochTime().int))
    require openForWrite(h, base)
    applyRecommendedDefaults(h)
    let sz = 1024
    check setMediaSize(h, uint64(sz))
    var buf = newSeq[byte](sz)
    for i in 0 ..< buf.len: buf[i] = byte(i and 0xFF)
    let (_, hs) = writeAndHash(h, buf)
    discard setStoredHashes(h, hs)
    discard finalizeWrite(h)
    discard close(h)
    discard freeHandle(h)
    let seg = makeSegPath(base)
    let res = verify(seg)
    echo "[rb] bps=512 sz=", sz, " bytesRead=", res.bytesRead, " md5=", res.md5
    check res.bytesRead == sz
    check res.md5 == hs.md5

  test "tiny media (8B) with bps=8 and sectorsPerChunk=1":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_tiny8spc1_" & $(epochTime().int))
    require openForWrite(h, base)
    discard setFormat(h, fmtEwf)
    discard setMediaType(h, mediaFixed)
    discard setMediaFlags(h, {})
    discard setCompressionValues(h, clNone, {})
    discard setMaximumSegmentSize(h, 64'u64 * 1024 * 1024)
    discard setBytesPerSector(h, 512'u32)
    discard setSectorsPerChunk(h, 1'u32)
    let sz2 = 512
    check setMediaSize(h, uint64(sz2))
    var buf2 = newSeq[byte](sz2)
    for i in 0 ..< buf2.len: buf2[i] = byte((0xA0 + i) and 0xFF)
    let (_, hs2) = writeAndHash(h, buf2)
    discard setStoredHashes(h, hs2)
    discard finalizeWrite(h)
    discard close(h)
    discard freeHandle(h)
    let seg2 = makeSegPath(base)
    let res2 = verify(seg2)
    echo "[rb] bps=512 spc=1 sz=", sz2, " bytesRead=", res2.bytesRead, " md5=", res2.md5
    check res2.bytesRead == sz2
    check res2.md5 == hs2.md5
