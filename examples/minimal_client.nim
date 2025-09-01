import nimewf
import std/os
import std/times

# Minimal hello‑world demonstrating:
# - Printing libewf version
# - Creating and freeing a handle
# - Optional: open/close a writer handle (no data written)

when isMainModule:
  echo "libewf version: ", getVersion()

  # 1) Create a handle
  var h = newHandle()
  if h == nil:
    echo "Failed to create handle"
    quit 1

  # 2) Optional: open and close a writer handle without writing
  let base = getTempDir() / ("nimewf_min_" & $(epochTime().int))
  if openForWrite(h, base):
    discard close(h)

  # 3) Free the handle
  if not freeHandle(h) or h != nil:
    echo "freeHandle failed"
    quit 2
  echo "OK"
