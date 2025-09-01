when defined(windows):
  # Windows: keep it simple and use the local libewf prefix installed by CI.
  # Assumes libewf was installed into `libewf-prefix` at the repository root.
  switch("passC", "-Ilibewf-prefix/include")
  switch("passL", "-Llibewf-prefix/lib -lewf -lz -lbz2 -lssl -lcrypto -liconv")
else:
  # Non-Windows: use pkg-config for libewf and openssl.
  let c1 = staticExec("pkg-config --silence-errors --cflags libewf openssl")
  let l1 = staticExec("pkg-config --silence-errors --libs libewf openssl")
  if c1.len > 0: switch("passC", c1)
  if l1.len > 0: switch("passL", l1)
