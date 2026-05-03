FROM mcr.microsoft.com/devcontainers/go:1-1.23-bookworm

RUN rm -f /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      tmux \
      ruby \
      ruby-dev \
      bundler \
      zsh \
      fish \
    && gem install bundler -v 2.6.2 --no-document \
    && rm -rf /var/lib/apt/lists/*

RUN if ! id -u node >/dev/null 2>&1; then \
      groupadd --gid 1001 node && useradd --uid 1001 --gid 1001 --create-home --shell /bin/bash node; \
    fi
