# Getting started (RU)

## Rust
- `cargo fmt --check`
- `cargo clippy`
- `cargo test`
- `CORE_CONFIG_PATH=config/core.toml cargo run -p art-core`

## Browser/Node
- `npm --prefix browser ci`
- `npm --prefix browser run lint`
- `npm --prefix browser run test`
- `npm --prefix browser run build`

## Smoke (Rust + Browser)
- `make smoke`

## Security smoke
- `gitleaks detect --source . --redact`
- `npx license-checker --production --summary`
