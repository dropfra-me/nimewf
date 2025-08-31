# nimewf FFI Map

This library wraps a minimal acquisition-focused subset of libewf.

Build modes:
- Default: stub FFI (no external linking) for local dev/tests.
- Real linking: compile with `-d:nimewfUseLibewf` to enable `{.importc.}` bindings.

## Targeted C APIs
- Lifecycle: `libewf_handle_initialize`, `libewf_handle_free`
- Options: `libewf_handle_set_compression_values`, `libewf_handle_set_maximum_segment_size`, `libewf_handle_set_media_type`, `libewf_handle_set_media_flags`, `libewf_handle_set_format`
- Acquisition: `libewf_handle_prepare_write`, `libewf_handle_write`, `libewf_handle_finalize_write`
- Metadata (optional): `libewf_handle_set_case_number`, `libewf_handle_set_description`, `libewf_handle_set_examiner_name`, `libewf_handle_set_notes`

## Nim FFI Pattern (example)
```nim
# Opaque C types
type
  libewf_handle_t* = object
  libewf_error_t*  = object

# Basic FFI (1:1 with C)
proc libewf_handle_initialize*(
  handle: ptr ptr libewf_handle_t,
  error:  ptr ptr libewf_error_t
): cint {.importc, cdecl.}

proc libewf_handle_free*(
  handle: ptr ptr libewf_handle_t,
  error:  ptr ptr libewf_error_t
): cint {.importc, cdecl.}

proc libewf_handle_write*(
  handle: ptr libewf_handle_t,
  buffer: pointer,
  buffer_size: csize_t,
  error: ptr ptr libewf_error_t
): clong {.importc, cdecl.}

# ...continue mapping the functions listed above.
```

## Wrapper Layer
- Keep FFI in `src/nimewf/ffi.nim` (no logic, no allocation; just importc).
- Provide ergonomic procs in `src/nimewf/writer.nim` (e.g., `newWriter`, `setCompression`, `writeChunk`, `finalize`).
- Re-export user-facing API from `src/nimewf.nim`.
