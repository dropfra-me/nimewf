import unittest
import std/os
import std/times
import nimewf/handle
import nimewf/options
import nimewf/types
import nimewf/writer
import nimewf/metadata

suite "high-level getters/setters (PR2)":
  test "format, segment size, sectors-per-chunk round-trip":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_pr2_basic_" & $(epochTime().int))
    require openForWrite(h, base)
    discard setFormat(h, fmtEncase6)
    discard setMaximumSegmentSize(h, 32'u64 * 1024 * 1024)
    discard setSectorsPerChunk(h, 64'u32)
    var fmt: Format
    var seg: uint64
    var spc: uint32
    check getFormat(h, fmt)
    check getMaximumSegmentSize(h, seg)
    check getSectorsPerChunk(h, spc)
    check fmt == fmtEncase6
    check seg == 32'u64 * 1024 * 1024
    check spc == 64'u32
    discard close(h)
    discard freeHandle(h)

  test "compression and media getters round-trip":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_pr2_comp_media_" & $(epochTime().int))
    require openForWrite(h, base)
    discard setCompressionValues(h, clFast, {compressEmptyBlock})
    discard setMediaType(h, mediaFixed)
    discard setMediaFlags(h, {mediaPhysical})
    var lvl: CompressionLevel
    var cfl: set[CompressionFlag]
    var mt: MediaType
    var mf: set[MediaFlag]
    check getCompressionValues(h, lvl, cfl)
    check getMediaType(h, mt)
    check getMediaFlags(h, mf)
    check lvl == clFast
    check compressEmptyBlock in cfl
    check mt == mediaFixed
    # Some libewf builds may set extra bits; just ensure our requested flag is present
    check mediaPhysical in mf
    discard close(h)
    discard freeHandle(h)

  test "generic utf8 header set/get":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_pr2_hdr_" & $(epochTime().int))
    discard setFormat(h, fmtEwf)
    discard setMediaType(h, mediaFixed)
    require openForWrite(h, base)
    check setUtf8Header(h, "case_number", "CASE-456")
    check setUtf8Header(h, "description", "Generic header path")
    var tmp: array[1, byte]
    tmp[0] = 0
    discard writeBuffer(h, tmp)
    discard finalizeWrite(h)
    discard close(h)
    discard freeHandle(h)

    var r = newHandle()
    require r != nil
    var seg = base & ".E01"; if not fileExists(seg): seg = base & ".e01"
    require openForRead(r, seg)
    check getUtf8Header(r, "case_number") == "CASE-456"
    check getUtf8Header(r, "description") == "Generic header path"
    discard freeHandle(r)

  when defined(nimewfHeaderCodepage):
    test "header codepage set (best-effort)":
      var h = newHandle()
      require h != nil
      let base = getTempDir() / ("nimewf_pr2_cp_" & $(epochTime().int))
      require openForWrite(h, base)
      check setHeaderCodepage(h, "windows-1252")
      discard close(h)
      discard freeHandle(h)
