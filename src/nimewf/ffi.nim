# Low-level FFI mappings to libewf (1:1 names)

when defined(nimewfUseLibewf):
  # Resolve from the link line provided by pkg-config; no dynlib path here.
  proc libewf_get_version*(): cstring {.importc, cdecl.}
else:
  # Stubbed fallback for local dev/tests without libewf
  proc libewf_get_version*(): cstring =
    return "stub-0.0.0"

