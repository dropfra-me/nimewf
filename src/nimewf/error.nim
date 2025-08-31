import ./ffi
import ./state

proc lastError*(): string =
  if ewfError == nil:
    return ""
  var buf = newString(4096)
  discard libewf_error_sprint(ewfError, buf.cstring, buf.len.csize_t)
  # Convert buffer to Nim string up to first NUL
  result = $cast[cstring](buf.cstring)

proc clearError*(): bool =
  if ewfError != nil:
    discard libewf_error_free(addr ewfError)
    ewfError = nil
    return true
  return false

