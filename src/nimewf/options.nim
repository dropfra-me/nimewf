import ./ffi
import ./handle
import ./state
import ./types

proc setCompressionValues*(h: Handle, level: CompressionLevel, flags: set[CompressionFlag]): bool =
  return libewf_handle_set_compression_values(h, int8(level), toU8(flags), addr ewfError) == 1

proc setMaximumSegmentSize*(h: Handle, size: uint64): bool =
  return libewf_handle_set_maximum_segment_size(h, culonglong(size), addr ewfError) == 1

## segment_file_size is not reliably supported/needed; prefer maximum_segment_size.
## We intentionally do not expose set/get for segment_file_size to keep API portable.

proc setMediaType*(h: Handle, mediaType: MediaType): bool =
  return libewf_handle_set_media_type(h, uint8(ord(mediaType)), addr ewfError) == 1

proc setMediaFlags*(h: Handle, flags: set[MediaFlag]): bool =
  return libewf_handle_set_media_flags(h, toU8(flags), addr ewfError) == 1

proc setFormat*(h: Handle, fmt: Format): bool =
  return libewf_handle_set_format(h, uint8(ord(fmt)), addr ewfError) == 1

proc setMediaSize*(h: Handle, size: uint64): bool =
  ## Sets the (media) size in bytes.
  return libewf_handle_set_media_size(h, culonglong(size), addr ewfError) == 1

proc getMediaSize*(h: Handle, size: var uint64): bool =
  var tmp: culonglong
  let ok = libewf_handle_get_media_size(h, addr tmp, addr ewfError) == 1
  if ok: size = uint64(tmp)
  return ok

proc setBytesPerSector*(h: Handle, bps: uint32 = 512'u32): bool =
  return libewf_handle_set_bytes_per_sector(h, bps, addr ewfError) == 1

proc getBytesPerSector*(h: Handle, bps: var uint32): bool =
  return libewf_handle_get_bytes_per_sector(h, addr bps, addr ewfError) == 1

proc setSectorsPerChunk*(h: Handle, spc: uint32): bool =
  return libewf_handle_set_sectors_per_chunk(h, spc, addr ewfError) == 1

proc getSectorsPerChunk*(h: Handle, spc: var uint32): bool =
  return libewf_handle_get_sectors_per_chunk(h, addr spc, addr ewfError) == 1

proc getFormat*(h: Handle, outFmt: var Format): bool =
  var fmtU8: uint8
  let ok = libewf_handle_get_format(h, addr fmtU8, addr ewfError) == 1
  if ok:
    outFmt = findEnumByOrd[Format](fmtU8, allFormats, fmtUnknown)
  ok

proc getMaximumSegmentSize*(h: Handle, outSize: var uint64): bool =
  var tmp: culonglong
  let ok = libewf_handle_get_maximum_segment_size(h, addr tmp, addr ewfError) == 1
  if ok: outSize = uint64(tmp)
  ok

proc tuneChunkForSegment*(h: Handle): bool =
  ## Ensures the chunk size (sectors_per_chunk * bytes_per_sector) does not
  ## exceed a safe fraction of the segment capacity. Returns true if values are
  ## OK or adjusted.
  var bps: uint32 = 512'u32
  discard getBytesPerSector(h, bps)
  var spc: uint32 = 64'u32
  discard getSectorsPerChunk(h, spc)
  # Prefer maximum_segment_size as the authoritative per-segment capacity.
  var segSz: uint64 = 0'u64
  discard getMaximumSegmentSize(h, segSz)
  if segSz == 0'u64:
    # Nothing to tune against if segment size is not configured.
    return true
  # Keep chunk size comfortably below the segment size to allow headers/footers.
  # Use at most half of the segment size to be conservative across libewf variants.
  let safeSegBytes = segSz div 2'u64
  let maxSpc = max(1'u32, uint32(safeSegBytes div uint64(bps)))
  if spc == 0'u32 or spc > maxSpc:
    return setSectorsPerChunk(h, maxSpc)
  true

proc getCompressionValues*(h: Handle, level: var CompressionLevel, flags: var set[CompressionFlag]): bool =
  var lvl: int8
  var flg: uint8
  let ok = libewf_handle_get_compression_values(h, addr lvl, addr flg, addr ewfError) == 1
  if ok:
    if lvl < -1 or lvl > 2: level = clDefault else: level = CompressionLevel(lvl)
    flags = fromU8[CompressionFlag](flg)
  ok

proc getMediaType*(h: Handle, outType: var MediaType): bool =
  var mt: uint8
  let ok = libewf_handle_get_media_type(h, addr mt, addr ewfError) == 1
  if ok:
    outType = findEnumByOrd[MediaType](mt, allMediaTypes, mediaRemovable)
  ok

proc getMediaFlags*(h: Handle, outFlags: var set[MediaFlag]): bool =
  var mf: uint8
  let ok = libewf_handle_get_media_flags(h, addr mf, addr ewfError) == 1
  if ok: outFlags = fromU8[MediaFlag](mf)
  ok

proc setHeaderCodepage*(h: Handle, codepage: string): bool =
  ## Best-effort mapping to libewf header codepage API; returns false if unavailable.
  when defined(nimewfHeaderCodepage):
    return libewf_handle_set_header_codepage(h, codepage.cstring, addr ewfError) == 1
  else:
    discard h; discard codepage
    return false

proc applyRecommendedDefaults*(
  h: Handle;
  fmt = fmtEncase6;
  comp = clNone;
  compressEmpty = false;
  segBytes = 1500'u64 * 1024 * 1024; # ~1.4 GiB
  chunkSectors = 64'u32;
  bps = 512'u32;
  mediaType = mediaFixed;
  mflags: set[MediaFlag] = {mediaPhysical}
) =
  ## Apply ewfacquire-aligned sane defaults, customizable via params.
  discard setFormat(h, fmt)
  discard setMediaType(h, mediaType)
  discard setMediaFlags(h, mflags)
  let cflags = (if compressEmpty: {compressEmptyBlock} else: {})
  discard setCompressionValues(h, comp, cflags)
  discard setMaximumSegmentSize(h, segBytes)
  discard setSectorsPerChunk(h, chunkSectors)
  discard setBytesPerSector(h, bps)
  discard tuneChunkForSegment(h)
