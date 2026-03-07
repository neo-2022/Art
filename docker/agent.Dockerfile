# Art Agent runtime container (reproducible skeleton)
# Source of truth: formats/platform_support.yaml
FROM scratch
ARG BIN_PATH=target/x86_64-unknown-linux-musl/general/art-agent
COPY ${BIN_PATH} /art-agent
ENV AGENT_HOST=0.0.0.0
ENV AGENT_PORT=8081
EXPOSE 8081
USER 65532:65532
ENTRYPOINT ["/art-agent"]
