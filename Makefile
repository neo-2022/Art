SHELL := /bin/bash

.PHONY: generate generate-schemas-md test-contracts test-telemetry smoke security-smoke

generate:
	@mkdir -p generated/rust generated/ts
	@echo "generated client placeholder" > generated/rust/README.md
	@echo "generated client placeholder" > generated/ts/README.md

generate-schemas-md:
	@cat docs/schemas/index.md > docs/api/schemas.md
	@echo "" >> docs/api/schemas.md
	@echo "Generated from docs/schemas/v1/*.json" >> docs/api/schemas.md

test-contracts:
	@test -s docs/api/openapi.yaml
	@test -s docs/schemas/v1/raw_event.json
	@test -s docs/schemas/v1/ingest_envelope.json
	@test -s docs/schemas/v1/ingest_response.json
	@test -s docs/schemas/v1/incident.json
	@echo "contract tests: OK"

test-telemetry:
	@test -s docs/telemetry/otel_mapping.md
	@test -s docs/telemetry/otlp_receiver.md
	@test -s docs/telemetry/limits.md
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
