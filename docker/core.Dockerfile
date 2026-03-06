# Art Core runtime container (reproducible skeleton)
# Source of truth: formats/platform_support.yaml
FROM scratch
ARG BIN_PATH=target/x86_64-unknown-linux-musl/general/art-core
COPY config/core.toml /config/core.toml
COPY ${BIN_PATH} /art-core
ENV CORE_CONFIG_PATH=/config/core.toml
ENV CORE_HOST=0.0.0.0
ENV CORE_PORT=8080
ENV CORE_ANALYTICS_STATE_PATH=/analytics_state.json
EXPOSE 8080
ENTRYPOINT ["/art-core"]
