import ./ffi
import ./handle
import ./state

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

proc finalizeWrite*(h: Handle): bool =
  ## Returns true if finalize succeeded (>= 0 bytes adjusted/written).
  return libewf_handle_write_finalize(h, addr ewfError) >= 0

proc close*(h: Handle): bool =
  return libewf_handle_close(h, addr ewfError) == 0

# Backward-compatible alias
proc writeChunk*(h: Handle, data: openArray[byte]): int {.inline.} = writeBuffer(h, data)
