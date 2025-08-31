import unittest
import nimewf

suite "image options setters":
  test "call setters on a fresh handle":
    var h = newHandle()
    require h != nil
    # Use conservative values; exact validity depends on libewf build/config.
    discard setCompressionValues(h, level = clNone, flags = {})
    discard setMaximumSegmentSize(h, 64'u64 * 1024 * 1024) # 64 MiB
    discard setMediaType(h, mediaFixed)
    discard setMediaFlags(h, {})
    discard setFormat(h, fmtEwf)
    let ok = freeHandle(h)
    check ok
    check h == nil
