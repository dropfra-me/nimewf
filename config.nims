const LIBS = ["libewf", "openssl"]

var
  accC, accL: string

proc havePkg(lib: string): bool =
  staticExec("pkg-config --exists " & lib & " && echo yes").strip == "yes"

for l in LIBS:
  if havePkg(l):
    let c = staticExec("pkg-config --silence-errors --cflags " & l).strip
    let lnk = staticExec("pkg-config --silence-errors --libs " & l).strip
    if c.len > 0: accC.add(" " & c)
    if lnk.len > 0: accL.add(" " & lnk)

if accC.len > 0: switch("passC", accC)
if accL.len > 0: switch("passL", accL)
