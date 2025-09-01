const LIBS = ["libewf", "openssl"]

var accC, accL: string

proc chomp(s: string): string =
  result = s
  var i = result.len - 1
  while i >= 0 and (result[i] == '\n' or result[i] == '\r' or result[i] == ' ' or result[i] == '\t'):
    dec i
  if i >= 0: result = result[0..i] else: result = ""

proc havePkg(lib: string): bool =
  chomp(staticExec("pkg-config --exists " & lib & " && echo yes")) == "yes"

for l in LIBS:
  if havePkg(l):
    let c = chomp(staticExec("pkg-config --silence-errors --cflags " & l))
    let lnk = chomp(staticExec("pkg-config --silence-errors --libs " & l))
    if c.len > 0: accC.add(" " & c)
    if lnk.len > 0: accL.add(" " & lnk)

# Fallback for OpenSSL on Windows: link libcrypto if pkg-config openssl is missing
when defined(windows):
  if not havePkg("openssl"):
    accL.add(" -lcrypto")

if accC.len > 0: switch("passC", accC)
if accL.len > 0: switch("passL", accL)
