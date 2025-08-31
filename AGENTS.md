# Repository Guidelines

## Project Structure & Module Organization
- Source: `src/` with the public API in `src/nimewf.nim`. Place C-FFI shims in `src/nimewf/` (e.g., `ffi.nim`, `writer.nim`).
- Tests: `tests/` using Nim’s `unittest` (files starting with `t` are preferred, e.g., `tests/t_writer.nim`).
- Package: `nimewf.nimble` defines metadata and dependencies. Keep `srcDir = "src"`.

## Build, Test, and Development Commands
- Build library: `nimble build` — compiles the package (no binary is produced for libraries).
- Run tests: `nimble test` — executes `tests/*.nim` via `unittest`.
- Docs preview: `nim doc src/nimewf.nim` — generates API docs locally.
- FFI mode: default uses stubs; enable real libewf linking with `-d:nimewfUseLibewf`.
- Example compile flags when linking an app against libewf: `nim c -d:nimewfUseLibewf --passL:-lewf --passC:-I/path/to/libewf/include yourapp.nim`.

## Coding Style & Naming Conventions
- Nim style: 2-space indent; procs/vars lowerCamelCase; types PascalCase; modules snake_case.
- FFI layer (`nimewf/ffi`): 1:1 names with libewf, e.g., `proc libewf_handle_initialize* ... {.importc, cdecl.}`.
- Public API (`nimewf.nim` and helpers): ergonomic names without the `libewf_` prefix (e.g., `newWriter`, `writeChunk`). Re-export from `nimewf.nim`.

## Testing Guidelines
- Framework: `unittest`; add focused unit tests per high-level wrapper (writer/options/errors).
- Naming: test files start with `t_` or `t` and describe behavior (`t_writer_finalize.nim`).
- Coverage: prioritize I/O error paths, finalize semantics, and option mapping (compression, segments, format).

## Commit & Pull Request Guidelines
- Commits: concise, imperative (“Add writer finalize path”); prefer Conventional Commits (`feat:`, `fix:`, `test:`).
- PRs: include purpose, minimal repro or small code snippet, and platform/ABI assumptions (Windows/Linux, x64). Link issues and include before/after notes.

## Security & Configuration Tips
- Ensure `libewf` is available at link time. On Windows, set `LIBEWF_DIR` or pass flags in `config.nims`:
  ```nim
  when defined(windows):
    switch("passC", "-I%LIBEWF_DIR%/include")
    switch("passL", "-L%LIBEWF_DIR%/lib -lewf")
  ```
- Keep FFI pointers checked for `nil`; always free handles.
