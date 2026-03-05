SHELL := /bin/bash

.PHONY: generate generate-schemas-md test-contracts test-telemetry smoke security-smoke

generate:
	@python3 scripts/generate/generate_clients.py

generate-schemas-md:
	@python3 scripts/generate/generate_schemas_md.py

test-contracts:
	@make generate >/dev/null
	@test -s docs/api/openapi.yaml
	@test -s docs/schemas/v1/raw_event.json
	@test -s docs/schemas/v1/ingest_envelope.json
	@test -s docs/schemas/v1/ingest_response.json
	@test -s docs/schemas/v1/incident.json
	@python3 scripts/tests/test_contracts.py
	@cargo check --manifest-path generated/rust/Cargo.toml
	@npx --yes -p typescript tsc -p generated/ts/tsconfig.json --noEmit
	@echo "contract tests: OK"

test-telemetry:
	@test -s docs/telemetry/otel_mapping.md
	@test -s docs/telemetry/otlp_receiver.md
	@test -s docs/telemetry/limits.md
	@test -s docs/runbooks/otlp_rate_limited.md
	@python3 scripts/tests/test_telemetry.py
	@bash scripts/ci/check_telemetry_stage09_docs.sh
	@echo "telemetry tests: OK"

smoke:
	cargo fmt --all --check
	cargo clippy --workspace --all-targets -- -D warnings
	cargo test --workspace
	npm --prefix browser ci
	npm --prefix browser run lint
	npm --prefix browser run test
	npm --prefix browser run build

security-smoke:
	gitleaks detect --source . --redact
	npx --yes license-checker --production --summary
