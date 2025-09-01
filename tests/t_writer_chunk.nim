import unittest
import os, times
import nimewf

suite "writer large chunk":
  test "write >64KiB and verify":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_big_" & $(epochTime().int))
    check openForWrite(h, base)
    applyRecommendedDefaults(h)
    let sz = 128 * 1024
    var buf = newSeq[byte](sz)
    for i in 0 ..< buf.len: buf[i] = byte(i and 0xFF)
    check setMediaSize(h, uint64(buf.len))
    let (wrote, hs) = writeAndHash(h, buf)
    check wrote == buf.len
    check setStoredHashes(h, hs)
    check finalizeWrite(h)
    check close(h)
    discard freeHandle(h)
    var seg = base & ".E01"
    if not fileExists(seg): seg = base & ".e01"
    let res = verify(seg)
    check res.bytesRead == sz
    check res.checksumErrors == 0
    if res.md5Stored.len == 32: check res.md5Match
    if res.sha1Stored.len == 40: check res.sha1Match
    if res.sha256Stored.len == 64: check res.sha256Match
