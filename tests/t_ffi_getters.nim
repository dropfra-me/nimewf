import unittest
import std/times
import std/os
import nimewf/handle
import nimewf/options
import nimewf/types
import nimewf/ffi
import nimewf/state
import nimewf/writer

suite "ffi getters round-trip":
  test "format getter returns set value":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_pr1_fmt_" & $(epochTime().int))
    require openForWrite(h, base)
    discard setFormat(h, fmtEwf)
    var fmtU8: uint8 = 0
    check libewf_handle_get_format(h, addr fmtU8, addr ewfError) == 1
    check fmtU8 == uint8(ord(fmtEwf))
    discard close(h)
    discard freeHandle(h)

  test "maximum segment size getter returns set value":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_pr1_seg_" & $(epochTime().int))
    require openForWrite(h, base)
    let seg = 64'u64 * 1024 * 1024
    discard setMaximumSegmentSize(h, seg)
    var outSz: culonglong
    check libewf_handle_get_maximum_segment_size(h, addr outSz, addr ewfError) == 1
    check uint64(outSz) == seg
    discard close(h)
    discard freeHandle(h)

  test "sectors per chunk getter returns set value":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_pr1_spc_" & $(epochTime().int))
    require openForWrite(h, base)
    let spc = 64'u32
    discard setSectorsPerChunk(h, spc)
    var outSpc: uint32 = 0
    check libewf_handle_get_sectors_per_chunk(h, addr outSpc, addr ewfError) == 1
    check outSpc == spc
    discard close(h)
    discard freeHandle(h)

  test "compression getters return set values":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_pr1_comp_" & $(epochTime().int))
    require openForWrite(h, base)
    discard setCompressionValues(h, clFast, {})
    var lvl: int8 = 0
    var flg: uint8 = 0
    check libewf_handle_get_compression_values(h, addr lvl, addr flg, addr ewfError) == 1
    check lvl == int8(clFast)
    check flg == 0'u8
    discard setCompressionValues(h, clFast, {compressEmptyBlock})
    lvl = 0; flg = 0
    check libewf_handle_get_compression_values(h, addr lvl, addr flg, addr ewfError) == 1
    check (flg and uint8(ord(compressEmptyBlock))) == uint8(ord(compressEmptyBlock))
    discard close(h)
    discard freeHandle(h)

  test "media type/flags getters return set values":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_pr1_media_" & $(epochTime().int))
    require openForWrite(h, base)
    discard setMediaType(h, mediaFixed)
    discard setMediaFlags(h, {})
    var mt: uint8 = 0
    var mf: uint8 = 0
    check libewf_handle_get_media_type(h, addr mt, addr ewfError) == 1
    check libewf_handle_get_media_flags(h, addr mf, addr ewfError) == 1
    check mt == uint8(ord(mediaFixed))
    # Some libewf builds may set a non-zero bit outside our known flags; ensure none of our supported flags are set.
    let knownMask = toU8({mediaPhysical, mediaFastBloc, mediaTableau})
    check (mf and knownMask) == 0'u8
    discard close(h)
    discard freeHandle(h)
