import nimewf

when isMainModule:
  echo "libewf version: ", getVersion()
  var h = newHandle()
  if h == nil:
    quit 1
  let ok = freeHandle(h)
  if not ok or h != nil:
    quit 2
  echo "Handle lifecycle OK"

