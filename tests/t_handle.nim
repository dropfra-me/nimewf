import unittest
import nimewf

suite "handle lifecycle":
  test "new/free handle":
    var h = newHandle()
    check h != nil
    let ok = freeHandle(h)
    check ok
    check h == nil

