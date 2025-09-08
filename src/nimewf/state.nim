import ./ffi

type
  EwfError* = ptr libewf_error_t

var ewfError* {.threadvar.}: EwfError

proc lastErrorString*(): string =
  ## Returns and clears the last libewf error string if present.
  if ewfError != nil:
    var s = newString(1024)
    discard libewf_error_sprint(ewfError, s.cstring, s.len.csize_t)
    result = $s.cstring
    discard libewf_error_free(addr ewfError)
    ewfError = nil
