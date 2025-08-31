# Example: minimal client

This example uses the `version` and `handle` APIs to sanity-check linking and lifecycle.

## Option A: Quick local compile against this repo

1) Provide libewf flags via pkg-config
- System lib: ensure `pkg-config --cflags --libs libewf` works
- Vendored lib (from this repo): run `nimble buildLibewf` once to install under `build/libewf-prefix`

2) Compile the example (from repo root)
- Dynamic link (system or vendored):
  - `nim c --path:src --passC:"$(pkg-config --cflags libewf)" --passL:"$(pkg-config --libs libewf)" examples/minimal_client.nim`
- Static-preference link (if vendored static is available):
  - `PKG_CONFIG_PATH=build/libewf-prefix/lib/pkgconfig nim c --path:src --passC:"$(pkg-config --cflags libewf)" --passL:"$(pkg-config --static --libs libewf)" examples/minimal_client.nim`

3) Run
- `./examples/minimal_client`

## Option B: Separate repository

1) Make nimewf importable
- Local install from this repo: `nimble install /path/to/nimewf`
- Or `nimble develop /path/to/nimewf` during development

2) In your client repo, compile with pkg-config flags
- Dynamic link:
  - `nim c --passC:"$(pkg-config --cflags libewf)" --passL:"$(pkg-config --libs libewf)" minimal_client.nim`
- Static-preference link (requires static libs):
  - `PKG_CONFIG_PATH=/abs/path/to/nimewf/build/libewf-prefix/lib/pkgconfig nim c --passC:"$(pkg-config --cflags libewf)" --passL:"$(pkg-config --static --libs libewf)" minimal_client.nim`

Notes
- Full static linking on macOS is limited; use dynamic linking unless you built vendored static libs and their dependencies.
- If `pkg-config` cannot find `libewf`, install it (Homebrew/apt) or set `PKG_CONFIG_PATH` to the vendored prefix.

