import unittest
import nimewf
import os
import times

suite "image options setters":
  test "call setters on an opened handle":
    var h = newHandle()
    require h != nil
    # Open for write to ensure option state is active on the handle
    let base = getTempDir() / ("nimewf_opts_" & $(epochTime().int))
    require openForWrite(h, base)
    # Use conservative values; exact validity depends on libewf build/config.
    discard setCompressionValues(h, level = clNone, flags = {})
    discard setMaximumSegmentSize(h, 64'u64 * 1024 * 1024) # 64 MiB
    var msz: uint64
    discard setMediaSize(h, 1024'u64)
    # libewf should now report a non-zero media size
    if getMediaSize(h, msz): check msz >= 1024'u64
    discard setMediaType(h, mediaFixed)
    discard setMediaFlags(h, {})
    discard setFormat(h, fmtEwf)
    discard close(h)
    let ok = freeHandle(h)
    check ok
    check h == nil
