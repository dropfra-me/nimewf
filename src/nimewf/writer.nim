import ./ffi
import ./handle
import ./state
import std/os

proc openForWrite*(h: Handle, basePath: string): bool =
  ## Opens the handle for writing. basePath should be the base filename
  ## (extension like .E01 is added by libewf).
  let flags = libewf_get_access_flags_write()
  var arr = allocCStringArray([basePath])
  defer: deallocCStringArray(arr)
  return libewf_handle_open(h, cast[ptr cstring](arr), 1.cint, flags, addr ewfError) == 1

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

proc finalizeWrite*(h: Handle): bool =
  ## Returns true if finalize succeeded (>= 0 bytes adjusted/written).
  return libewf_handle_write_finalize(h, addr ewfError) >= 0

proc close*(h: Handle): bool =
  return libewf_handle_close(h, addr ewfError) == 0

# Backward-compatible alias
proc writeChunk*(h: Handle, data: openArray[byte]): int {.inline.} = writeBuffer(h, data)
