# Example: minimal client

This example uses the `version` and `handle` APIs to sanity-check linking and lifecycle.

## Quick local compile against this repo

1) Ensure system libewf is installed and discoverable via pkg-config
- macOS: `brew install libewf pkg-config`
- Ubuntu: `sudo apt-get install -y libewf-dev pkg-config`

2) Compile the example (from repo root)
- `nim c --path:src --passC:"$(pkg-config --cflags libewf)" --passL:"$(pkg-config --libs libewf)" examples/minimal_client.nim`

3) Run
- `./examples/minimal_client`

## Separate repository

1) Make nimewf importable
- Local install from this repo: `nimble install /path/to/nimewf`
- Or `nimble develop /path/to/nimewf` during development

2) In your client repo, compile with pkg-config flags
- `nim c --passC:"$(pkg-config --cflags libewf)" --passL:"$(pkg-config --libs libewf)" minimal_client.nim`

Notes
- Full static linking on macOS is limited; dynamic linking is standard.
- If `pkg-config` cannot find `libewf`, install it (Homebrew/apt) or adjust `PKG_CONFIG_PATH`.
