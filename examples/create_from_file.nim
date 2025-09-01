import nimewf
import std/os

# Acquires a source file into an EWF image.
# Usage: create_from_file <inputPath> [outputBase]

proc usage() =
  echo "Usage: ", getAppFilename(), " <inputPath> [outputBase]"
  quit 1

when isMainModule:
  if paramCount() < 1: usage()
  let src = paramStr(1)
  if not fileExists(src):
    echo "Input not found: ", src
    quit 2
  var base: string
  if paramCount() >= 2:
    base = paramStr(2)
  else:
    base = src & ".ewf"

  var h = newHandle()
  if h == nil: quit 3
  if not openForWrite(h, base):
    echo "openForWrite failed: ", lastError()
    discard freeHandle(h)
    quit 4

  applyRecommendedDefaults(h)
  let fsz = getFileSize(src)
  discard setMediaSize(h, uint64(fsz))

  # Stream the file while computing hashes
  let (written, hashes) = writeAndHash(h, src)
  if written < 0:
    echo "write error: ", lastError()
  discard setStoredHashes(h, hashes)

  if not finalizeWrite(h): echo "finalizeWrite: ", lastError()
  if not close(h): echo "close: ", lastError()
  discard freeHandle(h)

  echo "Created: ", base, ".E01"
  echo "MD5=", hashes.md5, " SHA1=", hashes.sha1, " SHA256=", hashes.sha256
