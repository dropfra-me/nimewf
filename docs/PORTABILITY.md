# Portability, Static Linking, and Streaming Design

This document captures the design choices behind nimewf’s linking model and how to achieve a portable, self‑contained build on Windows, plus how we plan to support streaming EWF output without touching disk.

## Why System Packages (pkg-config)
- Simplicity: rely on the platform’s libewf (and its deps) rather than building an entire C stack in the Nim project.
- Predictability: OS packages ship known ABIs; CI becomes “install dev package, then build”.
- Flexibility: you can still build your own libewf if needed, but that’s outside this repo.

nimewf generates a `config.nims` (`nimble genPkgConfig`) that pulls compile and link flags from `pkg-config libewf`.

## Output Modes
- File‑based (current): open a base filename and let libewf write `.E01` (and subsequent segments). This is the classic workflow.
- Streaming (planned): use libewf’s BFIO integration to open the handle on a `libbfio_pool_t`, where each EWF segment is backed by your custom write/close callbacks. This supports in‑memory or network streaming, no disk I/O required.
  - We will add minimal `libbfio` FFI and a small adapter that forwards libewf writes to a user‑supplied sink. Disk and streaming paths will share the same high‑level writer API.

## Windows: Static, Self‑Contained Executable
Building a single EXE that contains libewf (and its dependencies) is feasible but requires care.

Key considerations
- Toolchain consistency: All libraries must be built with the same toolchain and runtime as your Nim binary.
  - MinGW (GCC): prefer `-static -static-libgcc -static-libstdc++` and link against `.a` static libs.
  - MSVC: prefer `/MT` (static CRT) and link against static `.lib` libraries. vcpkg’s `x64-windows-static` triplet is recommended.
- Dependency graph: libewf depends on multiple libraries (e.g., libbfio, libcaes, libcdata, libcfile, libuna, zlib, bzip2, iconv, pthread, etc. exact set depends on build configuration). All must be present as static libraries to truly produce a single EXE.
- pkg-config on Windows: not always present or complete. For static builds you may:
  - Use `pkg-config --static libewf` if available, or
  - Provide explicit `--passC`/`--passL` flags in `config.nims` pointing to headers and `.a`/`.lib` files (see below).
- License (LGPL): libewf is LGPL (per headers). Static linking to LGPL means you must allow users to relink (e.g., by distributing your object files, or otherwise complying with LGPL terms). Dynamic linking typically avoids that obligation. Consult your legal requirements before distributing statically linked binaries.

Suggested approaches
- MinGW (MSYS2):
  1) Install toolchain and deps (static variants where possible) and build static `libewf`, `libbfio`, and their dependencies using `--enable-static --disable-shared`.
  2) Link your Nim app with `--passL:"-static -static-libgcc -static-libstdc++"` and list all required `.a` libraries (order matters on GCC).
  3) Verify the resulting `.exe` has no external DLLs (use `ntldd`/`objdump -p`).
- MSVC + vcpkg:
  1) Build/install libraries with `-DVCPKG_TARGET_TRIPLET=x64-windows-static`.
  2) Add `--passC` include paths and `--passL` `.lib` paths (or use a `.props`/`pkg-config` equivalent if available).
  3) Compile Nim via `--cc:vcc` (MSVC backend). Ensure `/MT` (static CRT) is used to avoid dependency on the VC runtime DLLs.

Example `config.nims` (Windows, manual flags)
```nim
when defined(windows):
  # Headers
  switch("passC", "-I%LIBEWF_DIR%/include")
  switch("passC", "-I%LIBBFIO_DIR%/include")
  # Lib paths
  switch("passL", "-L%LIBEWF_DIR%/lib")
  switch("passL", "-L%LIBBFIO_DIR%/lib")
  # Static link preferences (MinGW)
  when defined(gcc) or defined(llvm_gcc):
    switch("passL", "-static -static-libgcc -static-libstdc++")
  # Link libraries (order may matter with GCC)
  switch("passL", "-lewf -lbfio -luna -lcdata -lcfile -lcaes -lbz2 -lz -liconv -lpthread")
```
Notes
- The exact library set and order depend on how libewf was built; inspect generated `.pc` files or use `pkg-config --static --libs libewf` where available to get a complete list.
- On MSVC, library names are `.lib` (e.g., `libewf.lib`); adjust accordingly.

## Cross‑Platform Strategy
- Linux/macOS: dynamic linking with system packages (simplest); static on macOS is limited and not recommended.
- Windows: dynamic linking is simplest (ship `libewf.dll` and deps next to your .exe), static is possible with the caveats above.
- nimewf stays thin and stable: our API covers handle lifecycle, image options, and write pipeline; adding BFIO streaming will not change the public API significantly.

## Why This Design
- Keep the wrapper minimal and predictable; focus on correctness and ergonomics.
- Avoid embedding complex C builds in this repo; leave that to platform package managers or separate build scripts.
- Provide a path to robust streaming (BFIO) without sacrificing the classic on‑disk output path.

