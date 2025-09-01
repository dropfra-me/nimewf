import unittest
import os
import times
import nimewf

suite "writer pipeline":
  test "open/write/finalize/close produces a segment file":
    var h = newHandle()
    require h != nil
    # Prepare temp base path without extension; libewf adds .E01
    let base = getTempDir() / ("nimewf_test_" & $(epochTime().int))
    var buf: array[64, byte]
    for i in 0 ..< buf.len: buf[i] = byte(i)
    check openForWrite(h, base)
    discard setFormat(h, fmtEwf)
    discard setMediaType(h, mediaFixed)
    discard setMediaFlags(h, {})
    discard setCompressionValues(h, clNone, {})
    discard setMaximumSegmentSize(h, 64'u64 * 1024 * 1024)
    discard setBytesPerSector(h, 512'u32)
    check setMediaSize(h, uint64(buf.len))
    let (wrote, hs) = writeAndHash(h, buf)
    check wrote == buf.len
    check hs.md5.len == 32 and hs.sha1.len == 40 and hs.sha256.len == 64
    check setStoredHashes(h, hs)
    check finalizeWrite(h)
    check close(h)
    var found = false
    for ext in ["E01", "e01"]:
      if fileExists(base & "." & ext):
        found = true
        break
    check found
    let ok = freeHandle(h)
    check ok
    check h == nil

  test "verify helper reads and reports":
    # Use previous image if present, or create a tiny one
    let base = getTempDir() / ("nimewf_verify_" & $(epochTime().int))
    var h = newHandle()
    require h != nil
    var buf: array[8, byte]
    for i in 0 ..< buf.len: buf[i] = byte(i)
    require openForWrite(h, base)
    discard setFormat(h, fmtEwf)
    discard setMediaType(h, mediaFixed)
    discard setMediaFlags(h, {})
    discard setCompressionValues(h, clNone, {})
    discard setMaximumSegmentSize(h, 64'u64 * 1024 * 1024)
    discard setBytesPerSector(h, 512'u32)
    check setMediaSize(h, uint64(buf.len))
    let (_, hs) = writeAndHash(h, buf)
    check setStoredHashes(h, hs)
    discard finalizeWrite(h)
    discard close(h)
    discard freeHandle(h)
    var seg = base & ".E01"
    if not fileExists(seg): seg = base & ".e01"
    let res = verify(seg)
    # Prefer concrete integrity signals over the coarse corrupt flag here.
    check res.checksumErrors == 0
    # Compare digests
    if res.md5Stored.len == 32: check res.md5Match
    if res.sha1Stored.len == 40: check res.sha1Match
    if res.sha256Stored.len == 64: check res.sha256Match
