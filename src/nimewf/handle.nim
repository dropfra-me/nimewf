import ./ffi

type
  Handle* = ptr libewf_handle_t
  EwfError* = ptr libewf_error_t

proc newHandle*(): Handle =
  var h: Handle = nil
  var e: EwfError = nil
  let rc = libewf_handle_initialize(addr h, addr e)
  if rc == 1: h else: nil

proc freeHandle*(h: var Handle): bool =
  var e: EwfError = nil
  let rc = libewf_handle_free(addr h, addr e)
  result = (rc == 1)

