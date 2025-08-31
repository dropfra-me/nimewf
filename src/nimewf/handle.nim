import ./ffi

type
  Handle* = ptr libewf_handle_t
  EwfError* = ptr libewf_error_t

proc newHandle*(): Handle =
  var e: EwfError
  if libewf_handle_initialize(addr result, addr e) != 1: return nil

proc freeHandle*(h: var Handle): bool =
  var e: EwfError
  return libewf_handle_free(addr h, addr e) == 1

