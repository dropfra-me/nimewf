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

  # Fallback for libewf on Windows when pkg-config is not resolving but PKG_CONFIG_PATH is set
  if not havePkg("libewf"):
    let pcEnv = getEnv("PKG_CONFIG_PATH")
    if pcEnv.len > 0:
      # take first path up to ';' or ':'
      var first = pcEnv
      var sep = -1
      for i in 0 ..< pcEnv.len:
        let ch = pcEnv[i]
        if ch == ';' or ch == ':':
          sep = i
          break
      if sep >= 0: first = pcEnv[0 .. sep-1]
      # if ends with /lib/pkgconfig, derive prefix
      let suffix = "/lib/pkgconfig"
      if first.len >= suffix.len:
        let start = first.len - suffix.len
        var matches = true
        for i in 0 ..< suffix.len:
          if first[start + i] != suffix[i]: matches = false
        if matches:
          let prefix = first[0 .. start-1]
          accC.add(" -I" & prefix & "/include")
          accL.add(" -L" & prefix & "/lib -lewf")

if accC.len > 0: switch("passC", accC)
if accL.len > 0: switch("passL", accL)
