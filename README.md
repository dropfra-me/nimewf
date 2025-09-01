# nimewf

A small, friendly Nim wrapper around libewf (Expert Witness Format). It exposes a minimal, ergonomic API for creating and verifying EWF images. This library also serves as a foundation for building a static, self‑contained “ewfacquire‑like” executable to aid DFIR engagements where quick, scriptable imaging is essential.

* Links against system `libewf` via pkg-config.

## Quick Start

### Install libewf, OpenSSL (hashing), and pkg-config

* macOS: `brew install libewf openssl@3 pkg-config`
* Ubuntu: `sudo apt-get install -y libewf-dev libssl-dev pkg-config`

### Run tests

* `nimble test`

### Use in your app

```nim
import nimewf

echo "libewf: ", getVersion()
var h = newHandle()
if h != nil:
  discard freeHandle(h)
```

## Examples

* Minimal sanity check: `examples/minimal_client.nim`
* Create from bytes: `examples/create_from_bytes.nim`
* Create from file: `examples/create_from_file.nim`
* Verify image: `examples/verify_image.nim`

## Docs & Building

* Build docs: `nim doc src/nimewf.nim`
* Building and environment notes: `docs/BUILDING.md`
* Roadmap / wrapped vs planned APIs: `docs/TODO.md`

## Design Principles

* Keep it simple: minimal, focused API that does exactly what it needs.
* Avoid unnecessary complexity: straightforward wrappers and typed options.
* Tests first: unit tests for lifecycle, options, metadata, write/verify.

## License

MIT
