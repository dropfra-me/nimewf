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
    discard setBytesPerSector(h, 1'u32) # ensure tiny media sizes are readable across libewf builds
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
    let minSz = 512
    var buf = newSeq[byte](minSz)
    for i in 0 ..< buf.len: buf[i] = byte(i and 0xFF)
    require openForWrite(h, base)
    discard setFormat(h, fmtEwf)
    discard setMediaType(h, mediaFixed)
    discard setMediaFlags(h, {})
    discard setCompressionValues(h, clNone, {})
    discard setMaximumSegmentSize(h, 64'u64 * 1024 * 1024)
    discard setBytesPerSector(h, 1'u32) # ensure tiny media sizes are readable across libewf builds
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
    check res.bytesRead == buf.len
    # End-to-end digest equality (computed-on-write vs computed-on-read)
    # If it fails, echo diagnostics to help root cause.
    if res.md5 != hs.md5:
      echo "[diag] md5 mismatch: write=", hs.md5, " read=", res.md5, " stored=", res.md5Stored
      echo "[diag] bytesRead=", res.bytesRead, " checksumErrors=", res.checksumErrors
    check res.md5 == hs.md5
    # If libewf stored digests, ensure they match as well (surface useful debug on mismatch)
    if res.md5Stored.len == 32:
      if not res.md5Match:
        echo "[diag] stored MD5 mismatch: stored=", res.md5Stored, " read=", res.md5
      check res.md5Match
    if res.sha1Stored.len == 40:
      if not res.sha1Match:
        echo "[diag] stored SHA1 mismatch: stored=", res.sha1Stored, " read=", res.sha1
      check res.sha1Match
    if res.sha256Stored.len == 64:
      if not res.sha256Match:
        echo "[diag] stored SHA256 mismatch: stored=", res.sha256Stored, " read=", res.sha256
      check res.sha256Match
