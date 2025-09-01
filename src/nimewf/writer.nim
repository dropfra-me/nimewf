import ./ffi
import ./handle
import ./state
import ./crypto
import ./options

proc openForWrite*(h: Handle, basePath: string): bool =
  ## Opens the handle for writing. basePath should be the base filename
  ## (extension like .E01 is added by libewf).
  let flags = libewf_get_access_flags_write()
  var arr = allocCStringArray([basePath])
  defer: deallocCStringArray(arr)
  let opened = libewf_handle_open(h, cast[ptr cstring](arr), 1.cint, flags, addr ewfError) == 1
  if not opened: return false
  # After open, apply ewfacquire-aligned defaults unconditionally; callers can override afterwards.
  applyRecommendedDefaults(h)
  return true

proc openForRead*(h: Handle, path: string): bool =
  let flags = libewf_get_access_flags_read()
  var arr = allocCStringArray([path])
  defer: deallocCStringArray(arr)
  return libewf_handle_open(h, cast[ptr cstring](arr), 1.cint, flags, addr ewfError) == 1

proc writeBuffer*(h: Handle, data: openArray[byte]): int =
  ## Returns number of bytes written, or -1 on error.
  if data.len == 0: return 0
  return libewf_handle_write_buffer(h, unsafeAddr data[0], csize_t(data.len), addr ewfError).int

proc writeBuffer*(h: Handle, f: File, bufSize: int = 1 shl 20): int =
  ## Streams the entire contents of `f` into the EWF writer in chunks.
  ## Returns total bytes written, or -1 on error.
  if bufSize <= 0: return 0
  var buf = newSeq[byte](bufSize)
  var total = 0
  while true:
    let nread = f.readBuffer(addr buf[0], buf.len)
    if nread <= 0:
      break
    var off = 0
    while off < nread:
      let nw = libewf_handle_write_buffer(h, addr buf[off], csize_t(nread - off), addr ewfError)
      if nw < 0:
        return -1
      if nw == 0:
        return total + off
      off += int(nw)
    total += nread
  return total

proc writeBuffer*(h: Handle, path: string, bufSize: int = 1 shl 20): int =
  ## Convenience overload that opens a file for reading and writes its contents.
  var f: File
  if not open(f, path, fmRead):
    return -1
  defer: close(f)
  return writeBuffer(h, f, bufSize)

type HashesHex* = object
  md5*: string
  sha1*: string
  sha256*: string

proc writeAndHash*(h: Handle, data: openArray[byte]): tuple[bytesWritten: int, hashes: HashesHex] =
  if data.len == 0: return (0, HashesHex())
  var hc: HashCtx
  hc.init()
  let nw = libewf_handle_write_buffer(h, unsafeAddr data[0], csize_t(data.len), addr ewfError)
  if nw < 0: return (-1, HashesHex())
  hc.update(unsafeAddr data[0], csize_t(nw))
  var md5: array[16, uint8]
  var sha1: array[20, uint8]
  var sha256: array[32, uint8]
  hc.finish(md5, sha1, sha256)
  result.bytesWritten = int(nw)
  result.hashes = HashesHex(md5: toHex(md5), sha1: toHex(sha1), sha256: toHex(sha256))

proc writeAndHash*(h: Handle, f: File, bufSize: int = 1 shl 20): tuple[bytesWritten: int, hashes: HashesHex] =
  if bufSize <= 0: return (0, HashesHex())
  var hc: HashCtx
  hc.init()
  var buf = newSeq[byte](bufSize)
  var total = 0
  while true:
    let nread = f.readBuffer(addr buf[0], buf.len)
    if nread <= 0: break
    var off = 0
    while off < nread:
      let nw = libewf_handle_write_buffer(h, addr buf[off], csize_t(nread - off), addr ewfError)
      if nw < 0:
        return (-1, HashesHex())
      if nw == 0:
        total += off
        var md5: array[16, uint8]
        var sha1: array[20, uint8]
        var sha256: array[32, uint8]
        hc.finish(md5, sha1, sha256)
        return (total, HashesHex(md5: toHex(md5), sha1: toHex(sha1), sha256: toHex(sha256)))
      hc.update(addr buf[off], csize_t(nw))
      off += int(nw)
    total += nread
  var md5: array[16, uint8]
  var sha1: array[20, uint8]
  var sha256: array[32, uint8]
  hc.finish(md5, sha1, sha256)
  return (total, HashesHex(md5: toHex(md5), sha1: toHex(sha1), sha256: toHex(sha256)))

proc writeAndHash*(h: Handle, path: string, bufSize: int = 1 shl 20): tuple[bytesWritten: int, hashes: HashesHex] =
  var f: File
  if not open(f, path, fmRead):
    return (-1, HashesHex())
  defer: close(f)
  return writeAndHash(h, f, bufSize)

proc setStoredHashes*(h: Handle, hashes: HashesHex): bool =
  ## Stores digests into the EWF: MD5/SHA1 via native fields; SHA256 as header "sha256".
  var md5b: array[16, uint8]
  var sha1b: array[20, uint8]
  var ok = true
  if hashes.md5.len == 32:
    if parseHex(hashes.md5, md5b):
      ok = ok and (libewf_handle_set_md5_hash(h, addr md5b[0], md5b.len.csize_t, addr ewfError) == 1)
  if hashes.sha1.len == 40:
    if parseHex(hashes.sha1, sha1b):
      ok = ok and (libewf_handle_set_sha1_hash(h, addr sha1b[0], sha1b.len.csize_t, addr ewfError) == 1)
  # Store SHA256 in header for old libewf versions
  if hashes.sha256.len == 64:
    discard libewf_handle_set_utf8_header_value(h, cast[ptr uint8](cstring("sha256")), 7.csize_t,
      cast[ptr uint8](hashes.sha256.cstring), hashes.sha256.len.csize_t, addr ewfError)
  return ok

proc finalizeWrite*(h: Handle): bool =
  ## Returns true if finalize succeeded (>= 0 bytes adjusted/written).
  return libewf_handle_write_finalize(h, addr ewfError) >= 0

proc close*(h: Handle): bool =
  return libewf_handle_close(h, addr ewfError) == 0

# Backward-compatible alias
proc writeChunk*(h: Handle, data: openArray[byte]): int {.inline.} = writeBuffer(h, data)
