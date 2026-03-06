# Art Core runtime container (reproducible skeleton)
# Source of truth: formats/platform_support.yaml
FROM scratch
ARG BIN_PATH=target/x86_64-unknown-linux-musl/general/art-core
COPY ${BIN_PATH} /art-core
EXPOSE 8080
ENTRYPOINT ["/art-core"]
