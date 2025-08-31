# Building libewf and linking nimewf

This project can use either a system `libewf` (via pkg-config) or build a vendored copy from `vendor/libewf`.

## Prerequisites

- Common tools: `pkg-config`, C toolchain (GCC/Clang), `make`.
- Autotools stack for the vendored build: `autoconf`, `automake`, `libtool`, `bison`, `flex`.

### macOS (Homebrew)

- Install deps:
  - `brew install pkg-config autoconf automake libtool bison flex`
  - Note: Homebrew’s `flex` is keg-only; the build task auto-detects it at `$(brew --prefix flex)/bin/flex`.

### Ubuntu/Debian (apt)

- Install deps:
  - `sudo apt-get update`
  - `sudo apt-get install -y build-essential pkg-config autoconf automake libtool bison flex`
  - If using system libewf: `sudo apt-get install -y libewf-dev`

### Fedora/RHEL (dnf)

- Install deps:
  - `sudo dnf install -y @development-tools pkgconf-pkg-config autoconf automake libtool bison flex`
  - If using system libewf: `sudo dnf install -y libewf-devel`

## Options

- System libewf (recommended on CI images that provide it):
  - Ensure `pkg-config --cflags --libs libewf` works (install `libewf-dev`/`-devel` or `brew install libewf`).
  - Generate config: `nimble genPkgConfig`
  - Build/tests: `nimble test -d:nimewfUseLibewf`

- Vendored libewf (portable, no system package needed):
  - Build and locally install to `build/libewf-prefix`: `nimble buildLibewf`
  - Build/tests using vendored pkg-config file: `nimble test -d:nimewfUseLibewf`

Both flows generate/consume `config.nims` that wires compile flags from pkg-config when `-d:nimewfUseLibewf` is set.

## Nim compile examples

- Build your app using system or vendored libewf via pkg-config flags injected by `config.nims`:
  - `nim c -d:nimewfUseLibewf yourapp.nim`

- If you prefer explicit flags (not required when using `config.nims`):
  - `nim c -d:nimewfUseLibewf --passC:$(pkg-config --cflags libewf) --passL:$(pkg-config --libs libewf) yourapp.nim`

## CI notes

- macOS (GitHub Actions):
  - `brew install pkg-config autoconf automake libtool bison flex`
  - System lib: `brew install libewf && nimble genPkgConfig`
  - Vendored lib: `nimble buildLibewf`
  - Run: `nimble test -d:nimewfUseLibewf`

- Ubuntu (GitHub Actions):
  - `sudo apt-get update`
  - System lib: `sudo apt-get install -y libewf-dev pkg-config` then `nimble genPkgConfig`
  - Vendored lib: `sudo apt-get install -y build-essential pkg-config autoconf automake libtool bison flex` then `nimble buildLibewf`
  - Run: `nimble test -d:nimewfUseLibewf`

## Troubleshooting

- `configure: error: expected an absolute directory name for --prefix`: fixed in the Nimble task (uses an absolute path).
- `libodraw_cue_scanner.c: No such file or directory`: ensure `flex` is installed; the task sets `LEX` to a valid `flex`.
- `pkg-config: libewf not found`: install `libewf-dev`/`libewf` or run `nimble buildLibewf`. Optionally set `PKG_CONFIG_PATH` to include the vendored prefix: `build/libewf-prefix/lib/pkgconfig`.

