# nimewf TODO / Roadmap

High-level plan to reach a practical ewfacquire/ewfacquirestream equivalent with a small, clean API.

## Wrapped (done)

- Handles: lifecycle and open/close
  - `libewf_handle_initialize`, `libewf_handle_free`
  - `libewf_handle_open` (read/write), `libewf_handle_close`
  - Access flags helpers: `libewf_get_access_flags_read`, `libewf_get_access_flags_write`

- Writer: basic write pipeline
  - `libewf_handle_write_buffer`, `libewf_handle_write_finalize`
  - High-level: `openForWrite`, `writeBuffer(bytes|File|path)`, `finalizeWrite`, `close`

- Options: core image options
  - `libewf_handle_set_compression_values`
  - `libewf_handle_set_maximum_segment_size`
  - `libewf_handle_set_media_type`, `libewf_handle_set_media_flags`
  - `libewf_handle_set_format`
  - `libewf_handle_set_media_size`, `libewf_handle_get_media_size`

- Metadata (UTF-8)
  - `libewf_handle_set_utf8_header_value` (+ helpers for case_number, description, examiner_name, notes)
  - `libewf_handle_get_utf8_header_value`/`_size` (generic getter)

- Read/Verify
  - `libewf_handle_read_buffer`
  - `libewf_handle_segment_files_corrupted`
  - `libewf_handle_get_number_of_checksum_errors`
  - Hash fetch: `libewf_handle_get_md5_hash`, `libewf_handle_get_sha1_hash`
  - High-level: `verify(path)` → ok, checksumErrors, md5/sha1

- Errors & Types
  - Error: `libewf_error_sprint`, `libewf_error_free` → `lastError()`, `clearError()`
  - Typed enums: `Format`, `MediaType`, `MediaFlag`, `CompressionLevel`, `CompressionFlag`

## Planned (next)

- Streaming (libbfio) for ewfacquirestream
  - Minimal `libbfio` FFI (handle/pool create/free, set write/close callbacks)
  - `libewf_handle_open_file_io_pool` to open writer on custom sinks (RAM/network)
  - High-level stream adapter: user-supplied sink factory (per segment)
  - Tests: in-memory sink collects bytes per segment

- Read/Extract helpers
  - Simple `readAll` and `copyToFile` for EWF → raw extraction (single stream)

- Hashes & Integrity (nice-to-have)
  - Enable/configure digest calculation (MD5/SHA1/SHA256 if supported)
  - Compare computed vs stored digests in `verify`

- Additional metadata conveniences
  - Evidence number, dates (acquiry/system), acquisition OS/software, model/serial
  - Named getters like `getCaseNumber()`

- UX & CLI/TUI
  - Example CLI: acquire from file/path to `.E01`, show progress, finalize, print digests
  - Example CLI: verify `.E01` and report integrity/metadata

## Notes

- Windows: see `docs/PORTABILITY.md` for static/dynamic linking guidance.
- System packages first: rely on OS `libewf` + `pkg-config` (`nimble genPkgConfig`).

