import unittest
import std/os
import std/times
import nimewf/handle
import nimewf/options
import nimewf/writer

suite "segment tuning":
  test "tuneChunkForSegment caps sectors_per_chunk to fit segment":
    var h = newHandle()
    require h != nil
    let base = getTempDir() / ("nimewf_tune_" & $(epochTime().int))
    require openForWrite(h, base)
    discard setBytesPerSector(h, 512'u32)
    discard setSectorsPerChunk(h, 64'u32) # 32 KiB chunk
    discard setMaximumSegmentSize(h, 8192'u64) # 8 KiB segment, safe cap = 4 KiB
    check tuneChunkForSegment(h)
    var spc: uint32
    check getSectorsPerChunk(h, spc)
    check spc <= 8'u32 # 8 * 512 = 4 KiB
    discard close(h)
    discard freeHandle(h)
