const LIBS = ["libewf", "openssl"]

var
  cflags, libs: string

for l in LIBS:
  cflags.add(" " & staticExec("pkg-config --cflags " & l))
  libs.add(" " & staticExec("pkg-config --libs " & l))

if cflags.len > 0: switch("passC", cflags)
if libs.len > 0: switch("passL", libs)
