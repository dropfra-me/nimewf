import unittest
import os
import times
import nimewf

suite "metadata setters/getters":
  test "set and get basic utf8 headers":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_meta_" & $(epochTime().int))
    # Set basic options (format/media) before opening to satisfy older libewf expectations
    discard setFormat(h, fmtEwf)
    discard setMediaType(h, mediaFixed)
    require openForWrite(h, base)

    if not setCaseNumber(h, "CASE-123"): echo "setCaseNumber error: ", lastError()
    if not setDescription(h, "Short description"): echo "setDescription error: ", lastError()
    if not setExaminerName(h, "Examiner X"): echo "setExaminerName error: ", lastError()
    if not setNotes(h, "Nim EWF test"): echo "setNotes error: ", lastError()
    check setCaseNumber(h, "CASE-123")
    check setDescription(h, "Short description")
    check setExaminerName(h, "Examiner X")
    check setNotes(h, "Nim EWF test")

    # Write a tiny buffer, finalize, and close to ensure metadata is persisted
    var buf: array[1, byte]
    buf[0] = 0
    discard writeBuffer(h, buf)
    discard finalizeWrite(h)
    discard close(h)
    var ok = freeHandle(h)
    check ok
    check h == nil

    # Re-open for read and verify metadata
    var r = newHandle()
    require r != nil
    var seg = base & ".E01"
    if not fileExists(seg): seg = base & ".e01"
    require openForRead(r, seg)
    check getUtf8Header(r, "case_number") == "CASE-123"
    check getUtf8Header(r, "description") == "Short description"
    check getUtf8Header(r, "examiner_name") == "Examiner X"
    check getUtf8Header(r, "notes") == "Nim EWF test"
    ok = freeHandle(r)
    check ok
