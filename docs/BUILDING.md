# Building libewf and linking nimewf

This project links against a system `libewf` (via pkg-config) and uses a checked-in `config.nims` to inject flags automatically at compile time.

## Prerequisites

- Common tools: `pkg-config`, C toolchain (GCC/Clang), `make`.
  (CI images usually provide a C toolchain; install if needed.)

### macOS (Homebrew)

- Install deps:
  - `brew install libewf openssl@3 pkg-config`

### Ubuntu/Debian (apt)

- Install deps:
  - `sudo apt-get update`
  - `sudo apt-get install -y build-essential pkg-config libewf-dev libssl-dev`

### Fedora/RHEL (dnf)

- Install deps:
  - `sudo dnf install -y @development-tools pkgconf-pkg-config libewf-devel openssl-devel`

## Setup

- Ensure pkg-config can find the dependencies:
  - `pkg-config --cflags --libs libewf`
  - `pkg-config --cflags --libs openssl` (or ensure `libcrypto` is available via pkg-config)
- No Nimble task is required: `config.nims` is part of the repo and queries pkg-config at compile time.

Note on crypto
- Hashing uses OpenSSL EVP (libcrypto). Ensure the openssl pkg-config files are present.

## Nim compile examples

- Build your app using system or vendored libewf via pkg-config flags injected by `config.nims`:
  - `nim c yourapp.nim`

- If you prefer explicit flags (not required when using `config.nims`):
  - `nim c --passC:$(pkg-config --cflags libewf) --passL:$(pkg-config --libs libewf) yourapp.nim`

## CI notes

- macOS (GitHub Actions):
  - `brew install libewf openssl@3 pkg-config`
  - `nimble test`

- Ubuntu (GitHub Actions):
  - `sudo apt-get update`
  - `sudo apt-get install -y libewf-dev libssl-dev pkg-config build-essential`
  - `nimble test`

## Troubleshooting

- `pkg-config: libewf not found`: install `libewf-dev`/`libewf` or set `PKG_CONFIG_PATH` appropriately.
- `undefined reference to EVP_*`: install the OpenSSL dev package so `pkg-config --libs openssl` resolves, or add `-lcrypto` manually if your platform ships only libcrypto.
