import ./ffi
import ./handle
import ./writer
import ./state
import ./crypto
import ./metadata
import std/strutils
import std/os

type VerifyResult* = object
  ok*: bool
  checksumErrors*: int
  bytesRead*: int
  md5*: string
  sha1*: string
  sha256*: string
  md5Stored*: string
  sha1Stored*: string
  sha256Stored*: string
  md5Match*: bool
  sha1Match*: bool
  sha256Match*: bool

proc verify*(path: string, bufSize: int = 1 shl 20): VerifyResult =
  when defined(nimewfDebug):
    echo "[verify] path=", path
    if fileExists(path):
      try:
        echo "[verify] fileSize=", getFileSize(path)
      except CatchableError:
        discard
  var h = newHandle()
  if h == nil:
    return
  defer:
    discard freeHandle(h)
  # Try to open the entire segment chain explicitly for portability (Windows/MSYS may
  # not always auto-discover additional segments from the first file).
  block openChain:
    var files: seq[string] = @[]
    files.add(path)
    # Detect classic EWF segment suffix: .E01 / .e01, then enumerate E02/e02, E03/e03 ...
    # Detect classic .E01/.e01 (4 chars) or EWF-X .Ex01/.ex01 (5 chars).
    let ext4 = (if path.len >= 4: path[(path.len - 4) ..< path.len] else: "")
    let ext5 = (if path.len >= 5: path[(path.len - 5) ..< path.len] else: "")
    if ext5.len == 5 and ext5[0] == '.' and (ext5[1] == 'E' or ext5[1] == 'e') and (ext5[2] == 'x' or ext5[2] == 'X') and ext5[3] in {'0'..'9'} and ext5[4] in {'0'..'9'}:
      let upperE = (ext5[1] == 'E')
      let upperX = (ext5[2] == 'X')
      let base = path[0 ..< (path.len - 5)]
      var i = 2
      while i < 100:
        let num = if i < 10: "0" & $i else: $i
        let nextExt = "." & (if upperE: "E" else: "e") & (if upperX: "X" else: "x") & num
        let nextPath = base & nextExt
        if fileExists(nextPath):
          files.add(nextPath)
          inc i
        else:
          break
    elif ext4.len == 4 and ext4[0] == '.' and (ext4[1] == 'E' or ext4[1] == 'e') and ext4[2] in {'0'..'9'} and ext4[3] in {'0'..'9'}:
      let upper = (ext4[1] == 'E')
      let base = path[0 ..< (path.len - 4)]
      var i = 2
      while i < 100:
        let num = if i < 10: "0" & $i else: $i
        let nextExt = (if upper: ".E" else: ".e") & num
        let nextPath = base & nextExt
        if fileExists(nextPath):
          files.add(nextPath)
          inc i
        else:
          break
    # Open all discovered files at once
    let flags = libewf_get_access_flags_read()
    var carr = allocCStringArray(files)
    defer: deallocCStringArray(carr)
    if libewf_handle_open(h, cast[ptr cstring](carr), cint(files.len), flags, addr ewfError) != 1:
      when defined(nimewfDebug):
        echo "[verify] open chain failed: ", lastErrorString()
      # Fallback to single-file open for non-standard names
      if not openForRead(h, path):
        return
    when defined(nimewfDebug):
      echo "[verify] opened files (", files.len, "):"
      for f in files: echo "  - ", f
  # Probe media size from handle
  when defined(nimewfDebug):
    try:
      var msz: uint64
      if getMediaSize(h, msz):
        echo "[verify] mediaSize=", msz
    except CatchableError:
      discard
  # Read the entire content to exercise the parser
  var hc: HashCtx
  hc.init()
  var buf = newSeq[byte](max(4096, bufSize))
  var totalRead = 0
  while true:
    let n = libewf_handle_read_buffer(h, addr buf[0], csize_t(buf.len), addr ewfError)
    if n <= 0: break
    hc.update(addr buf[0], csize_t(n))
    totalRead += int(n)
  result.bytesRead = totalRead
  when defined(nimewfDebug):
    echo "[verify] totalRead=", totalRead
  # Corruption and checksum errors
  let corrupt = libewf_handle_segment_files_corrupted(h, addr ewfError)
  var nerr: uint32 = 0
  discard libewf_handle_get_number_of_checksum_errors(h, addr nerr, addr ewfError)
  result.ok = (corrupt == 0)
  result.checksumErrors = int(nerr)
  when defined(nimewfDebug):
    echo "[verify] corruptFlag=", corrupt, " checksumErrors=", result.checksumErrors
  # Hashes (computed and stored)
  var md5c: array[16, uint8]
  var sha1c: array[20, uint8]
  var sha256c: array[32, uint8]
  hc.finish(md5c, sha1c, sha256c)
  result.md5 = toHex(md5c)
  result.sha1 = toHex(sha1c)
  result.sha256 = toHex(sha256c)

  var md5s: array[16, uint8]
  var sha1s: array[20, uint8]
  let hasMd5 = libewf_handle_get_md5_hash(h, addr md5s[0], md5s.len.csize_t, addr ewfError) == 1
  if hasMd5:
    result.md5Stored = toHex(md5s)
  let hasSha1 = libewf_handle_get_sha1_hash(h, addr sha1s[0], sha1s.len.csize_t, addr ewfError) == 1
  if hasSha1:
    result.sha1Stored = toHex(sha1s)
  result.sha256Stored = ""
  # Optional SHA256 header value
  let s256 = getUtf8Header(h, "sha256")
  if s256.len == 64:
    result.sha256Stored = s256

  when defined(nimewfDebug):
    echo "[verify] md5 computed=", result.md5, " stored=", result.md5Stored
    echo "[verify] sha1 computed=", result.sha1, " stored=", result.sha1Stored
    if result.sha256Stored.len > 0:
      echo "[verify] sha256 computed=", result.sha256, " stored=", result.sha256Stored
  # Prefer binary comparison for MD5/SHA1 (no string case issues); keep SHA256 string compare (header stores hex).
  result.md5Match = hasMd5 and (md5c == md5s)
  result.sha1Match = hasSha1 and (sha1c == sha1s)
  result.sha256Match = (result.sha256Stored.len == 64 and toLowerAscii(result.sha256Stored) == result.sha256)
