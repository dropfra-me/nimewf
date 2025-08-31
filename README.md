# nimewf

A small Nim wrapper around libewf (Expert Witness Format). It links against libewf via pkg-config and provides a clean, minimal API surface you can build on.

- Always links to the real libewf (no stub mode).
- Works with either a system libewf (Homebrew/apt) or a vendored build under `vendor/libewf`.
- Modern build flow using Nimble tasks + pkg-config.

## Quick Start

1) Choose how to provide libewf
- System lib (recommended): install libewf and pkg-config.
  - macOS: `brew install libewf pkg-config`
  - Ubuntu: `sudo apt-get install -y libewf-dev pkg-config`
  - Then generate flags: `nimble genPkgConfig`
- Vendored lib: build into a local prefix.
  - `nimble buildLibewf`

2) Run tests
- `nimble test`

3) Use in your app
```nim
import nimewf

echo "libewf: ", getVersion()
var h = newHandle()
if h != nil:
  discard freeHandle(h)
```

See `examples/minimal_client.nim` for a standalone example and `examples/README.md` for compile commands (both dynamic and static-preference using pkg-config).

## Docs & Building
- Build docs: `nim doc src/nimewf.nim`
- Compilation notes and CI tips: see `docs/BUILDING.md` and `docs/LINKING.md`.

## Design Principles
- Keep it simple: minimal, focused API that does exactly what it needs.
- Avoid unnecessary complexity: prefer straightforward wrappers and types.
- Modern build: pkg-config + Nimble tasks; repeatable vendor builds when needed.
- Tests first: unit tests for wrapper behavior and lifecycle handling.

## License
MIT
