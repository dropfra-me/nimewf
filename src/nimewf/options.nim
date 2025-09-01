import ./ffi
import ./handle
import ./state
import ./types

proc setCompressionValues*(h: Handle, level: CompressionLevel, flags: set[CompressionFlag]): bool =
  return libewf_handle_set_compression_values(h, int8(level), toU8(flags), addr ewfError) == 1

proc setMaximumSegmentSize*(h: Handle, size: uint64): bool =
  return libewf_handle_set_maximum_segment_size(h, culonglong(size), addr ewfError) == 1

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

proc applyRecommendedDefaults*(h: Handle) =
  ## Apply sane defaults for common EWF acquisitions.
  discard setFormat(h, fmtEwf)
  discard setMediaType(h, mediaFixed)
  discard setMediaFlags(h, {})
  discard setCompressionValues(h, clFast, {compressEmptyBlock})
  discard setMaximumSegmentSize(h, 1500'u64 * 1024 * 1024)
  # discard setBytesPerSector(h, 512'u32)
