#!/usr/bin/env python3
from pathlib import Path


RUST_CARGO = """[package]
name = "art_generated_client"
version = "0.1.0"
edition = "2021"

[lib]
path = "src/lib.rs"

[workspace]
"""

RUST_LIB = """#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BackpressureError {
    pub retry_after_ms: Option<u64>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IngestInvalidDetail {
    pub index: usize,
    pub reason: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IngestAck {
    pub upto_seq: Option<u64>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IngestResponse {
    pub accepted: u64,
    pub invalid_details: Vec<IngestInvalidDetail>,
    pub ack: IngestAck,
}
"""

TS_CONFIG = """{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noEmit": true
  },
  "include": ["src/**/*.ts"]
}
"""

TS_INDEX = """export type BackpressureError = {
  retry_after_ms: number | null;
};

export type IngestInvalidDetail = {
  index: number;
  reason: string;
};

export type IngestResponse = {
  accepted: number;
  invalid_details: IngestInvalidDetail[];
  ack: { upto_seq: number | null };
};
"""


def write_file(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def main() -> None:
    write_file(Path("generated/rust/Cargo.toml"), RUST_CARGO)
    write_file(Path("generated/rust/src/lib.rs"), RUST_LIB)
    write_file(Path("generated/rust/README.md"), "generated Rust client\n")
    write_file(Path("generated/ts/tsconfig.json"), TS_CONFIG)
    write_file(Path("generated/ts/src/index.ts"), TS_INDEX)
    write_file(Path("generated/ts/README.md"), "generated TypeScript client\n")


if __name__ == "__main__":
    main()
