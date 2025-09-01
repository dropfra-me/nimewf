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

# Image option setters
proc libewf_handle_set_compression_values*(
  handle: ptr libewf_handle_t,
  compression_level: int8,
  compression_flags: uint8,
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}

proc libewf_handle_set_maximum_segment_size*(
  handle: ptr libewf_handle_t,
  maximum_segment_size: culonglong,
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}

proc libewf_handle_set_media_type*(
  handle: ptr libewf_handle_t,
  media_type: uint8,
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}

proc libewf_handle_set_media_flags*(
  handle: ptr libewf_handle_t,
  media_flags: uint8,
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}

proc libewf_handle_set_format*(
  handle: ptr libewf_handle_t,
  format: uint8,
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}

# Media size
proc libewf_handle_set_media_size*(
  handle: ptr libewf_handle_t,
  media_size: culonglong,
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}

proc libewf_handle_get_media_size*(
  handle: ptr libewf_handle_t,
  media_size: ptr culonglong,
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}

# Error helpers
proc libewf_error_free*(
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}

proc libewf_error_sprint*(
  error: ptr libewf_error_t,
  string: cstring,
  size: csize_t
): cint {.importc, cdecl.}

# Metadata (UTF-8) header value setters/getters
proc libewf_handle_set_utf8_header_value*(
  handle: ptr libewf_handle_t,
  identifier: ptr uint8,
  identifier_length: csize_t,
  utf8_string: ptr uint8,
  utf8_string_length: csize_t,
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}

proc libewf_handle_get_utf8_header_value_size*(
  handle: ptr libewf_handle_t,
  identifier: ptr uint8,
  identifier_length: csize_t,
  utf8_string_size: ptr csize_t,
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}

proc libewf_handle_get_utf8_header_value*(
  handle: ptr libewf_handle_t,
  identifier: ptr uint8,
  identifier_length: csize_t,
  utf8_string: ptr uint8,
  utf8_string_size: csize_t,
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}

# Acquisition pipeline and open/close
proc libewf_get_access_flags_write*(): cint {.importc, cdecl.}
proc libewf_get_access_flags_read*(): cint {.importc, cdecl.}

proc libewf_handle_open*(
  handle: ptr libewf_handle_t,
  filenames: ptr cstring,
  number_of_filenames: cint,
  access_flags: cint,
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}

proc libewf_handle_close*(
  handle: ptr libewf_handle_t,
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}

proc libewf_handle_write_buffer*(
  handle: ptr libewf_handle_t,
  buffer: pointer,
  buffer_size: csize_t,
  error: ptr ptr libewf_error_t
): clong {.importc, cdecl.}

proc libewf_handle_write_finalize*(
  handle: ptr libewf_handle_t,
  error: ptr ptr libewf_error_t
): clong {.importc, cdecl.}

proc libewf_handle_read_buffer*(
  handle: ptr libewf_handle_t,
  buffer: pointer,
  buffer_size: csize_t,
  error: ptr ptr libewf_error_t
): clong {.importc, cdecl.}

proc libewf_handle_segment_files_corrupted*(
  handle: ptr libewf_handle_t,
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}

proc libewf_handle_get_number_of_checksum_errors*(
  handle: ptr libewf_handle_t,
  number_of_errors: ptr uint32,
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}

proc libewf_handle_get_md5_hash*(
  handle: ptr libewf_handle_t,
  md5_hash: ptr uint8,
  size: csize_t,
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}

proc libewf_handle_get_sha1_hash*(
  handle: ptr libewf_handle_t,
  sha1_hash: ptr uint8,
  size: csize_t,
  error: ptr ptr libewf_error_t
): cint {.importc, cdecl.}
