import unittest
import nimewf

suite "version API":
  test "getVersion returns a non-empty string":
    let v = getVersion()
    check v.len > 0

