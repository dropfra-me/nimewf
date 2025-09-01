import unittest
import std/os
import std/times
import nimewf/handle
import nimewf/options
import nimewf/types
import nimewf/writer

suite "sane defaults (PR3)":
  test "applyRecommendedDefaults matches ewfacquire defaults":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_pr3_def_" & $(epochTime().int))
    require openForWrite(h, base)
    applyRecommendedDefaults(h)
    var fmt: Format
    var seg: uint64
    var spc: uint32
    var bps: uint32
    var lvl: CompressionLevel
    var cfl: set[CompressionFlag]
    var mt: MediaType
    var mf: set[MediaFlag]
    if getFormat(h, fmt): check fmt == fmtEncase6
    if getMaximumSegmentSize(h, seg): check seg == 1500'u64 * 1024 * 1024
    if getSectorsPerChunk(h, spc): check spc == 64'u32
    if getBytesPerSector(h, bps): check bps == 512'u32
    if getCompressionValues(h, lvl, cfl):
      check lvl == clNone
      check compressEmptyBlock notin cfl
    if getMediaType(h, mt): check mt == mediaFixed
    if getMediaFlags(h, mf): check mediaPhysical in mf
    discard close(h)
    discard freeHandle(h)

  test "customizable overload applies requested values":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_pr3_cust_" & $(epochTime().int))
    require openForWrite(h, base)
    applyRecommendedDefaults(
      h,
      fmt = fmtEwfx,
      comp = clFast,
      compressEmpty = true,
      segBytes = 64'u64 * 1024 * 1024,
      chunkSectors = 1'u32,
      bps = 4096'u32,
      mediaType = mediaOptical,
      mflags = {}
    )
    var fmt: Format
    var seg: uint64
    var spc: uint32
    var bps: uint32
    var lvl: CompressionLevel
    var cfl: set[CompressionFlag]
    var mt: MediaType
    var mf: set[MediaFlag]
    if getFormat(h, fmt): check fmt == fmtEwfx
    if getMaximumSegmentSize(h, seg): check seg == 64'u64 * 1024 * 1024
    if getSectorsPerChunk(h, spc): check spc == 1'u32
    if getBytesPerSector(h, bps): check bps == 4096'u32
    if getCompressionValues(h, lvl, cfl):
      check lvl == clFast
      check compressEmptyBlock in cfl
    if getMediaType(h, mt): check mt == mediaOptical
    if getMediaFlags(h, mf): check mf == {}
    discard close(h)
    discard freeHandle(h)

  test "openForWrite applies defaults when untouched":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_pr3_open_def_" & $(epochTime().int))
    # Do NOT set any options; open should apply defaults
    require openForWrite(h, base)
    var fmt: Format
    var seg: uint64
    var spc: uint32
    var bps: uint32
    var lvl: CompressionLevel
    var cfl: set[CompressionFlag]
    var mt: MediaType
    var mf: set[MediaFlag]
    if getFormat(h, fmt): check fmt == fmtEncase6
    if getMaximumSegmentSize(h, seg): check seg == 1500'u64 * 1024 * 1024
    if getSectorsPerChunk(h, spc): check spc == 64'u32
    if getBytesPerSector(h, bps): check bps == 512'u32
    if getCompressionValues(h, lvl, cfl):
      check lvl == clNone
      check compressEmptyBlock notin cfl
    if getMediaType(h, mt): check mt == mediaFixed
    if getMediaFlags(h, mf): check mediaPhysical in mf
    discard close(h)
    discard freeHandle(h)
