import unittest
import nimewf

suite "error helpers":
  test "clear with no error is false and lastError empty":
    check lastError() == ""
    check clearError() == false

