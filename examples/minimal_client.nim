import nimewf
import std/os
import std/times

# Minimal, end-to-end example demonstrating:
# - Inspecting libewf version
# - Creating a handle and setting options (format, compression, media)
# - Opening for write with a base filename (libewf adds .E01)
# - Setting optional metadata
# - Writing a few bytes, finalizing, closing, and reading metadata back

when isMainModule:
  echo "libewf version: ", getVersion()

  # 1) Create a handle
  var h = newHandle()
  if h == nil:
    echo "Failed to create handle"
    quit 1

  # 2) Configure options (optional but recommended)
  discard setFormat(h, fmtEwf)
  discard setCompressionValues(h, clFast, {compressEmptyBlock})
  discard setMaximumSegmentSize(h, 1500'u64 * 1024 * 1024) # 1.5 GiB default
  discard setMediaType(h, mediaFixed)
  discard setMediaFlags(h, {})

  # 3) Open for write (use a temp base; libewf will create base.E01)
  let base = getTempDir() / ("nimewf_example_" & $(epochTime().int))
  if not openForWrite(h, base):
    echo "openForWrite failed: ", lastError()
    discard freeHandle(h)
    quit 2
  echo "Writing to base: ", base, " (.E01)"

  # 4) Optional metadata
  if not setCaseNumber(h, "CASE-123"): echo "setCaseNumber: ", lastError()
  if not setDescription(h, "Short description"): echo "setDescription: ", lastError()
  if not setExaminerName(h, "Examiner X"): echo "setExaminerName: ", lastError()
  if not setNotes(h, "Example with nimewf"): echo "setNotes: ", lastError()

  # 5) Write a few bytes
  var data: array[256, byte]
  for i in 0 ..< data.len: data[i] = byte(i)
  discard setMediaSize(h, uint64(data.len))
  let n = writeBuffer(h, data)
  if n != data.len:
    echo "writeBuffer wrote ", n, " bytes: ", lastError()

  # 6) Finalize + close + free
  if not finalizeWrite(h): echo "finalizeWrite: ", lastError()
  if not close(h): echo "close: ", lastError()
  if not freeHandle(h) or h != nil:
    echo "freeHandle failed"
    quit 3

  # 7) Re-open for read and show metadata
  var r = newHandle()
  if r == nil: quit 4
  var seg = base & ".E01"
  if not fileExists(seg): seg = base & ".e01"
  if not openForRead(r, seg):
    echo "openForRead failed: ", lastError()
    discard freeHandle(r)
    quit 5
  echo "Metadata read-back:"
  echo "  case_number   = ", getUtf8Header(r, "case_number")
  echo "  description   = ", getUtf8Header(r, "description")
  echo "  examiner_name = ", getUtf8Header(r, "examiner_name")
  echo "  notes         = ", getUtf8Header(r, "notes")
  discard freeHandle(r)
  echo "Done"
