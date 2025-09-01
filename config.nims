let cflags = staticExec("pkg-config --cflags libewf")
let libs   = staticExec("pkg-config --libs libewf")
if cflags.len > 0: switch("passC", cflags)
if libs.len > 0: switch("passL", libs)
