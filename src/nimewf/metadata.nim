import ./ffi
import ./handle
import ./state

template idPtr*(s: static[string]): ptr uint8 =
  cast[ptr uint8](cstring(s))

proc setUtf8Header*(h: Handle, key, value: string): bool =
  return libewf_handle_set_utf8_header_value(
    h,
    cast[ptr uint8](key.cstring), key.len.csize_t,
    cast[ptr uint8](value.cstring), value.len.csize_t,
    addr ewfError
  ) == 1

proc setCaseNumber*(h: Handle, value: string): bool =
  return libewf_handle_set_utf8_header_value(
    h,
    idPtr("case_number"), 11.csize_t,
    cast[ptr uint8](value.cstring), value.len.csize_t,
    addr ewfError
  ) == 1

proc setDescription*(h: Handle, value: string): bool =
  return libewf_handle_set_utf8_header_value(
    h,
    idPtr("description"), 11.csize_t,
    cast[ptr uint8](value.cstring), value.len.csize_t,
    addr ewfError
  ) == 1

proc setExaminerName*(h: Handle, value: string): bool =
  return libewf_handle_set_utf8_header_value(
    h,
    idPtr("examiner_name"), 13.csize_t,
    cast[ptr uint8](value.cstring), value.len.csize_t,
    addr ewfError
  ) == 1

proc setNotes*(h: Handle, value: string): bool =
  return libewf_handle_set_utf8_header_value(
    h,
    idPtr("notes"), 5.csize_t,
    cast[ptr uint8](value.cstring), value.len.csize_t,
    addr ewfError
  ) == 1

proc setEvidenceNumber*(h: Handle, value: string): bool =
  return setUtf8Header(h, "evidence_number", value)

proc setOrganization*(h: Handle, value: string): bool =
  return setUtf8Header(h, "organization", value)

proc setPhoneNumber*(h: Handle, value: string): bool =
  return setUtf8Header(h, "phone_number", value)

proc setDeviceModel*(h: Handle, value: string): bool =
  return setUtf8Header(h, "device_model", value)

proc setSerialNumber*(h: Handle, value: string): bool =
  return setUtf8Header(h, "serial_number", value)

# Helpers to fetch values for tests/debugging
proc getUtf8Header*(h: Handle, key: string): string =
  var size: csize_t = 0
  discard libewf_handle_get_utf8_header_value_size(
    h,
    cast[ptr uint8](key.cstring), key.len.csize_t,
    addr size,
    addr ewfError
  )
  if size == 0: return ""
  var buf = newString(int(size))
  discard libewf_handle_get_utf8_header_value(
    h,
    cast[ptr uint8](key.cstring), key.len.csize_t,
    cast[ptr uint8](buf.cstring), size,
    addr ewfError
  )
  # Returned size includes NUL; convert via cstring to truncate at the first NUL
  result = $buf.cstring

proc getCaseNumber*(h: Handle): string = getUtf8Header(h, "case_number")
proc getDescription*(h: Handle): string = getUtf8Header(h, "description")
proc getExaminerName*(h: Handle): string = getUtf8Header(h, "examiner_name")
proc getNotes*(h: Handle): string = getUtf8Header(h, "notes")
