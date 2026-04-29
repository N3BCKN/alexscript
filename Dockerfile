# syntax=docker/dockerfile:1.7

# builder
FROM ruby:3.4.7-slim AS builder

# Dependencies for building native extensions (some gems)
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy Gemfile first to leverage Docker layer caching
COPY Gemfile Gemfile.lock ./

# Bundler setup: install production gems into a dedicated directory
RUN bundle config set --local without 'development test' \
 && bundle config set --local deployment 'true' \
 && bundle config set --local path 'vendor/bundle' \
 && bundle install --jobs 4 --retry 3


# runtime
FROM ruby:3.4.7-slim AS runtime

# OCI metadata (visible in Docker Hub and `docker inspect`)
LABEL org.opencontainers.image.title="AlexScript"
LABEL org.opencontainers.image.description="Programming language interpreter with Polish syntax"
LABEL org.opencontainers.image.version="0.9.18"
LABEL org.opencontainers.image.source="https://github.com/N3BCKN/alexscript"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.authors="Konstanty Koszewski <https://github.com/N3BCKN>"

# Create non-root user (security best practice)
RUN useradd --create-home --shell /bin/bash --uid 1000 alex

# Installation directory
ENV ALEXSCRIPT_ROOT=/opt/alexscript
WORKDIR ${ALEXSCRIPT_ROOT}

# Copy installed gems from builder
COPY --from=builder /build/vendor/bundle ./vendor/bundle
COPY --from=builder /build/Gemfile /build/Gemfile.lock ./

# Configure bundler for runtime
RUN bundle config set --local without 'development test' \
 && bundle config set --local deployment 'true' \
 && bundle config set --local path 'vendor/bundle'

# Copy language source code (filtered via .dockerignore)
COPY lib/  ./lib/
COPY bin/  ./bin/

# Ensure script is executable
RUN chmod +x bin/alexscript.rb

# User workspace (where .as scripts are executed)
# Container starts in /workspace, so mounted files are accessible directly
RUN mkdir -p /workspace && chown alex:alex /workspace

# Used for resolving relative paths
ENV ALEXSCRIPT_USER_PWD=/workspace

USER alex
WORKDIR /workspace

# ENTRYPOINT bundle exec 
ENTRYPOINT ["bundle", "exec", "ruby", "/opt/alexscript/bin/alexscript.rb"]

# for REPL 
CMD []