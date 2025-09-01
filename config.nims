const LIBS = ["libewf", "openssl"]

var accC, accL: string

when defined(windows):
  # Prefer direct flags for libewf based on PKG_CONFIG_PATH to avoid noisy pkg-config errors.
  let pc = getEnv("PKG_CONFIG_PATH")
  if pc.len > 0:
    # Split PKG_CONFIG_PATH on common separators
    for part in pc.split({':', ';'}):
      let pcdir = part.strip
      if pcdir.len == 0: continue
      let pcfile = pcdir / "libewf.pc"
      if fileExists(pcfile):
        # Derive prefix from .../lib/pkgconfig
        let libdir = pcdir.parentDir
        let prefix = libdir.parentDir
        accC.add(" -I" & (prefix / "include"))
        accL.add(" -L" & (prefix / "lib") & " -lewf")
        break
  # OpenSSL via pkg-config if available; otherwise fall back to -lcrypto
  let osslC = staticExec("pkg-config --silence-errors --cflags openssl").strip
  let osslL = staticExec("pkg-config --silence-errors --libs openssl").strip
  if osslC.len > 0: accC.add(" " & osslC)
  if osslL.len > 0: accL.add(" " & osslL) else: accL.add(" -lcrypto")
else:
  # Non-Windows: use pkg-config normally
  for l in LIBS:
    let c = staticExec("pkg-config --silence-errors --cflags " & l).strip
    let lnk = staticExec("pkg-config --silence-errors --libs " & l).strip
    if c.len > 0: accC.add(" " & c)
    if lnk.len > 0: accL.add(" " & lnk)

if accC.len > 0: switch("passC", accC)
if accL.len > 0: switch("passL", accL)
