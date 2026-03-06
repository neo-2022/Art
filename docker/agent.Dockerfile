# Art Agent runtime container (reproducible skeleton)
# Source of truth: formats/platform_support.yaml
FROM scratch
ARG BIN_PATH=target/x86_64-unknown-linux-musl/general/art-agent
COPY ${BIN_PATH} /art-agent
ENTRYPOINT ["/art-agent"]
