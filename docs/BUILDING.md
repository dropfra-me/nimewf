# Building libewf and linking nimewf

This project links against a system `libewf` (via pkg-config).

## Prerequisites

- Common tools: `pkg-config`, C toolchain (GCC/Clang), `make`.
  (CI images usually provide a C toolchain; install if needed.)

### macOS (Homebrew)

- Install deps:
  - `brew install libewf pkg-config`

### Ubuntu/Debian (apt)

- Install deps:
  - `sudo apt-get update`
  - `sudo apt-get install -y build-essential pkg-config libewf-dev`

### Fedora/RHEL (dnf)

- Install deps:
  - `sudo dnf install -y @development-tools pkgconf-pkg-config libewf-devel`

## Setup

- Ensure `pkg-config --cflags --libs libewf` works.
- Generate `config.nims` once: `nimble genPkgConfig`

## Nim compile examples

- Build your app using system or vendored libewf via pkg-config flags injected by `config.nims`:
  - `nim c yourapp.nim`

- If you prefer explicit flags (not required when using `config.nims`):
  - `nim c --passC:$(pkg-config --cflags libewf) --passL:$(pkg-config --libs libewf) yourapp.nim`

## CI notes

- macOS (GitHub Actions):
  - `brew install libewf pkg-config`
  - `nimble genPkgConfig && nimble test`

- Ubuntu (GitHub Actions):
  - `sudo apt-get update`
  - `sudo apt-get install -y libewf-dev pkg-config build-essential`
  - `nimble genPkgConfig && nimble test`

## Troubleshooting

- `pkg-config: libewf not found`: install `libewf-dev`/`libewf` or set `PKG_CONFIG_PATH` appropriately.
