import unittest
import os
import times
import nimewf
import strutils

suite "writer pipeline":
  test "open/write/finalize/close produces a segment file":
    var h = newHandle()
    require h != nil
    # Prepare temp base path without extension; libewf adds .E01
    let base = getTempDir() / ("nimewf_test_" & $(epochTime().int))
    check openForWrite(h, base)
    var buf: array[64, byte]
    for i in 0 ..< buf.len: buf[i] = byte(i)
    let wrote = writeBuffer(h, buf)
    check wrote == buf.len
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
    require openForWrite(h, base)
    var buf: array[8, byte]
    for i in 0 ..< buf.len: buf[i] = byte(i)
    discard writeBuffer(h, buf)
    discard finalizeWrite(h)
    discard close(h)
    discard freeHandle(h)
    var seg = base & ".E01"
    if not fileExists(seg): seg = base & ".e01"
    let res = verify(seg)
    check res.ok == true
    check res.checksumErrors >= 0
