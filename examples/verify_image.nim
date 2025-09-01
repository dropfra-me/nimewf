import nimewf
import std/os

# Verifies an EWF image (.E01), prints container status and digests.
# Usage: verify_image <image.E01>

proc usage() =
  echo "Usage: ", getAppFilename(), " <image.E01>"
  quit 1

when isMainModule:
  if paramCount() < 1: usage()
  let img = paramStr(1)
  if not fileExists(img):
    echo "Image not found: ", img
    quit 2
  let res = verify(img)
  echo "Container: corruptFlag=", (not res.ok ? "1" : "0"), " checksumErrors=", res.checksumErrors, " bytesRead=", res.bytesRead
  echo "MD5:    computed=", res.md5, " stored=", res.md5Stored, " match=", res.md5Match
  echo "SHA1:   computed=", res.sha1, " stored=", res.sha1Stored, " match=", res.sha1Match
  if res.sha256.len > 0 or res.sha256Stored.len > 0:
    echo "SHA256: computed=", res.sha256, " stored=", res.sha256Stored, " match=", res.sha256Match
