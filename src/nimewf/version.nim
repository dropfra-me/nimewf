import ./ffi

proc getVersion*(): string =
  # Convert C string to Nim string; works for both real and stub builds.
  result = $libewf_get_version()

