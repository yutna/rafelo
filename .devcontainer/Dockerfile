# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and mise.toml.
ARG RUBY_VERSION=4.0.9
FROM ghcr.io/rails/devcontainer/images/ruby:${RUBY_VERSION}@sha256:4f9a4f82ce15d03b8ef96631d42334ee8cb0f88bbca85829db339b8a92a32356

USER root

# The PostgreSQL client is needed by db:prepare/structure loads; the rest are
# native dependencies for libvips, pg and the Playwright browsers.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential curl git libpq-dev libvips postgresql-client && \
    mkdir -p /ms-playwright && chown vscode:vscode /ms-playwright && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

USER vscode

# Bind Rails and Vite to every interface so forwarded ports work; the mise
# shims put the pinned Node and npm on PATH for every shell and CI job.
ENV BINDING="0.0.0.0" \
    PATH="/home/vscode/.local/bin:/home/vscode/.local/share/mise/shims:${PATH}" \
    PLAYWRIGHT_BROWSERS_PATH="/ms-playwright"

# Install the pinned JavaScript toolchain and the browsers once, so a job only
# runs npm ci and never downloads a browser. The image, not each job, owns the
# browser binaries (OPS-09).
COPY --chown=vscode:vscode mise.toml package.json package-lock.json /tmp/
RUN cd /tmp && \
    mise trust && \
    mise install && \
    mise reshim && \
    mise exec -- npm ci && \
    mise exec -- npx playwright install --with-deps && \
    rm -rf node_modules package.json package-lock.json mise.toml
