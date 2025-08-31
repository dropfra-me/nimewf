import ./ffi

type
  EwfError* = ptr libewf_error_t

var ewfError* {.threadvar.}: EwfError

