# nimewf TODO / Roadmap

## PR1: Expand FFI Surface (formats, segmenting, compression, media)

Rationale: Clients (nimager) need to read/write core parameters and confirm they took effect. Missing getters/setters make behavior opaque (e.g., segment splitting, file format).
Changes
nimewf/src/nimewf/ffi.nim
Add getters:
libewf_handle_get_format*(handle: ptr libewf_handle_t, format: ptr uint8, error: ptr ptr libewf_error_t): cint
libewf_handle_get_maximum_segment_size*(handle: ptr libewf_handle_t, size: ptr culonglong, error: ptr ptr libewf_error_t): cint
libewf_handle_get_sectors_per_chunk*(handle: ptr libewf_handle_t, sectors: ptr uint32, error: ptr ptr libewf_error_t): cint
libewf_handle_get_compression_values*(handle: ptr libewf_handle_t, level: ptr int8, flags: ptr uint8, error: ptr ptr libewf_error_t): cint
libewf_handle_get_media_type*(handle: ptr libewf_handle_t, mediaType: ptr uint8, error: ptr ptr libewf_error_t): cint
libewf_handle_get_media_flags*(handle: ptr libewf_handle_t, flags: ptr uint8, error: ptr ptr libewf_error_t): cint
Add setters (if present in your libewf build):
libewf_handle_set_sectors_per_chunk*(handle: ptr libewf_handle_t, sectors: uint32, error: ptr ptr libewf_error_t): cint
libewf_handle_set_header_codepage*(handle: ptr libewf_handle_t, codepage: cstring, error: ptr ptr libewf_error_t): cint (for -A)
Notes: Guard newer APIs with version/availability if needed. Keep names 1
with libewf.
Tests
Add compile-time presence checks and skip tests when functions not available.
Minimal smoke tests to call getters after setting values and verify round-trip where supported.
## PR2: High-Level Option Getters/Setters + Header Codepage

Rationale: Provide ergonomic, typed APIs in nimewf so clients don’t touch raw FFI or magic numbers.
Changes
nimewf/src/nimewf/options.nim
Add:
proc getFormat*(h: Handle, outFmt: var Format): bool
proc getMaximumSegmentSize*(h: Handle, outSize: var uint64): bool
proc setSectorsPerChunk*(h: Handle, sectors: uint32): bool
proc getSectorsPerChunk*(h: Handle, sectors: var uint32): bool
proc getCompressionValues*(h: Handle, level: var CompressionLevel, flags: var set[CompressionFlag]): bool
proc getMediaType*(h: Handle, outType: var MediaType): bool
proc getMediaFlags*(h: Handle, outFlags: var set[MediaFlag]): bool
proc setHeaderCodepage*(h: Handle, codepage: string): bool (maps ewfacquire -A)
nimewf/src/nimewf/types.nim
Add a Codepage* = enum ... or string passthrough; optionally provide helpers to map ewfacquire names (e.g., windows-1252) to libewf expectations.
nimewf/src/nimewf/metadata.nim
Add generic:
proc setUtf8Header*(h: Handle, key, value: string): bool
proc getUtf8Header*(h: Handle, key: string): string (already present)
Add typed helpers (facade over setUtf8Header):
setEvidenceNumber*, setOrganization*, setPhoneNumber*, setDeviceModel*, setSerialNumber* (common ewfacquire headers)
Tests
Add small unit tests covering: sectors-per-chunk, compression round-trip (when supported), header codepage set (best-effort), generic header set/get.
## PR3: Sane Defaults API

Rationale: Out-of-the-box behavior should match ewfacquire expectations; clients can still override.
Changes
nimewf/src/nimewf/options.nim
Update applyRecommendedDefaults*:
format = fmtEncase6
compression = clNone with {} flags (no empty-block by default)
maximum segment size = 1.4 GiB for EnCase6/7 (documented default)
sectors per chunk = 64
bytes per sector = 512
media type = mediaFixed
media flags = {mediaPhysical}
Add an overload:
proc applyRecommendedDefaults*(h: Handle; fmt = fmtEncase6; comp = clNone; compressEmpty = false; segBytes = 1500'u64*1024*1024; chunkSectors = 64'u32; bps = 512'u32; mediaType = mediaFixed; mflags: set[MediaFlag] = {mediaPhysical})
Tests
Verify defaults apply without error; when getters are available, assert expected values.
## PR4: Build Configuration Robustness

Rationale: Avoid link errors across platforms. Libewf often depends on zlib, bzip2, zstd, OpenSSL; sometimes lzma.
Changes
config.nims in nimewf
Iterate libraries via pkg-config with fallbacks:
const LIBS = ["libewf", "libzstd", "zlib", "bzip2", "openssl"] (optionally "liblzma")
Collect cflags and libs; prefer --static on Linux unless -d:noFullStatic is set.
Fallbacks: -lzstd -lz -lbz2 -lcrypto (and -llzma if added).
Document MSYS2/Windows guidance and env-var knobs (PKG_CONFIG_PATH, -d:noFullStatic).
Tests
CI matrix adjustments (Linux/macOS/Windows) to ensure building and minimal runtime works.
## PR5: Info/Introspection Helpers

Rationale: Allow clients to present ewfinfo-like output without copy/paste of FFI.
Changes
New module nimewf/src/nimewf/info.nim or extend options.nim:
proc readInfo*(path: string): Info where Info includes:
format: Format
sectorsPerChunk: uint32
compressionLevel: CompressionLevel
compressionFlags: set[CompressionFlag]
bytesPerSector: uint32
mediaType: MediaType
mediaFlags: set[MediaFlag]
mediaSize: uint64
headers: Table[string, string] (or just common ones)
storedMd5/sha1 (native) + optional sha256 header
Use the new getters added in ## PR1/2; when not supported by the underlying lib, fill with “unknown”.
Tests
Unit test that reading info on a known small sample returns non-empty core fields or “unknown” gracefully.
## PR6: Documentation & Examples

Rationale: Make the new surface discoverable and safe to adopt.
Changes
README updates:
“Defaults” section describing ewfacquire-aligned defaults.
“Setting options” with examples:
Set format/segment size/chunk sectors/compression.
Set media type/flags.
Set header codepage and metadata (case_number, evidence_number).
“Hashing” notes: MD5/SHA1 native fields; SHA256 as header “sha256”.
Build config notes for zlib/bzip2/zstd/openssl and Windows hints.
Changelog:
New getters/setters, defaults change (noted as behavioral change), added config.nims robustness.
Behavioral Changes (Callouts)

Default format becomes EnCase 6 (was EWF).
Default compression becomes none (was fast).
Default segment size becomes 1.4 GiB for EnCase6/7.
Default sectors per chunk becomes 64.
Default media flags include physical.
These are intended to mirror ewfacquire; document how to opt out.
