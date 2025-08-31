# Linking libewf

nimewf is a Nim library that links against the system libewf when your application is built.

Enable real linking by compiling with `-d:nimewfUseLibewf`. Without this define, stub FFI is used for local development and tests.

## Build Flags
- Compiler: include headers with `--passC:-I...` and link with `--passL:-lewf` (plus `-L...` if needed).
- Example per-project `config.nims`:
  ```nim
  when defined(windows):
    switch("passC", "-I%LIBEWF_DIR%/include")
    switch("passL", "-L%LIBEWF_DIR%/lib -lewf")
  when defined(linux):
    switch("passL", "-lewf")
  when defined(macosx):
    switch("passL", "-lewf")
  ```

## Platform Notes
- Windows: ensure `libewf.dll` is discoverable at runtime (same dir as EXE or on `PATH`). Prefer x64 builds; keep CRT/runtime consistent.
- Linux: if using non-system paths, add rpath: `switch("passL", "-Wl,-rpath,/opt/libewf/lib -L/opt/libewf/lib -lewf")`.
- macOS: if using non-system paths, `install_name_tool` or `@rpath` can help; simplest is `-Wl,-rpath,/usr/local/lib`.

## Verifying
- Compile a small program that imports `nimewf/ffi` and links (`nim c --passL:-lewf yourapp.nim`).
- If unresolved symbols appear, confirm architecture (x64), the presence of `libewf` on the link path, and that headers match the installed version.
