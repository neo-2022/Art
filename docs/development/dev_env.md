# Dev environment (RU)

## Toolchain
- Rust: stable (`rustup toolchain install stable`, компоненты `rustfmt`, `clippy`)
- Node: 22.x (`node -v` должен быть 22.*)

## Env vars
- `ART_PROFILE_ID`: profile selection
- `ART_INGEST_URL`: ingest endpoint
- `ART_STREAM_URL`: stream endpoint
- `RUST_LOG`: log level
- `NODE_ENV`: frontend mode

## Локальные зависимости
- `gitleaks` — для локального security smoke.
- `cargo-deny` — для проверки лицензий Rust (`cargo deny check licenses`).
- `license-checker` — JS summary (`npx license-checker --production --summary`).
