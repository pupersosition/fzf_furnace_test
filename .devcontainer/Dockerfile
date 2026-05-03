FROM mcr.microsoft.com/devcontainers/go:1-1.23-bookworm

RUN if ! id -u node >/dev/null 2>&1; then \
      groupadd --gid 1001 node && useradd --uid 1001 --gid 1001 --create-home --shell /bin/bash node; \
    fi
