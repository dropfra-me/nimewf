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

proc applyRecommendedDefaults*(h: Handle) =
  ## Apply sane defaults for common EWF acquisitions.
  discard setFormat(h, fmtEwf)
  discard setMediaType(h, mediaFixed)
  discard setMediaFlags(h, {})
  discard setCompressionValues(h, clFast, {compressEmptyBlock})
  discard setMaximumSegmentSize(h, 1500'u64 * 1024 * 1024)
  # discard setBytesPerSector(h, 512'u32)
