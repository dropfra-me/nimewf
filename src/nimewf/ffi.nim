# Low-level FFI mappings to libewf (1:1 names)

type
  libewf_handle_t* = object ## opaque
  libewf_error_t*  = object ## opaque

# Resolve from the link line provided by pkg-config; no dynlib path here.
proc libewf_get_version*(): cstring {.importc, cdecl.}

proc libewf_handle_initialize*(
  handle: ptr ptr libewf_handle_t,
  error:  ptr ptr libewf_error_t
): cint {.importc, cdecl.}

proc libewf_handle_free*(
  handle: ptr ptr libewf_handle_t,
  error:  ptr ptr libewf_error_t
): cint {.importc, cdecl.}
