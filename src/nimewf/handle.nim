import ./ffi
import ./state

type
  Handle* = ptr libewf_handle_t

proc newHandle*(): Handle =
  if libewf_handle_initialize(addr result, addr ewfError) != 1: return nil

proc freeHandle*(h: var Handle): bool =
  return libewf_handle_free(addr h, addr ewfError) == 1
