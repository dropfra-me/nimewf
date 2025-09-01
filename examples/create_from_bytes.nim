import nimewf
import std/os
import std/times

# Creates a small EWF image from an in-memory byte array.

when isMainModule:
  echo "libewf version: ", getVersion()

  var h = newHandle()
  if h == nil:
    quit 1

  # Open for write with a base filename (extension .E01 is added by libewf)
  let base = getTempDir() / ("nimewf_bytes_" & $(epochTime().int))
  if not openForWrite(h, base):
    echo "openForWrite failed: ", lastError()
    discard freeHandle(h)
    quit 2

  # Apply defaults and set media size before writing
  applyRecommendedDefaults(h)
  var data: array[256, byte]
  for i in 0 ..< data.len: data[i] = byte(i)
  discard setMediaSize(h, uint64(data.len))

  let (written, hashes) = writeAndHash(h, data)
  if written != data.len:
    echo "write error: ", lastError()
  discard setStoredHashes(h, hashes)

  if not finalizeWrite(h): echo "finalizeWrite: ", lastError()
  if not close(h): echo "close: ", lastError()
  discard freeHandle(h)

  echo "Created: ", base, ".E01"
  echo "MD5=", hashes.md5, " SHA1=", hashes.sha1, " SHA256=", hashes.sha256
