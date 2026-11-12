# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and mise.toml.
ARG RUBY_VERSION=4.0.9
FROM ghcr.io/rails/devcontainer/images/ruby:${RUBY_VERSION}@sha256:4f9a4f82ce15d03b8ef96631d42334ee8cb0f88bbca85829db339b8a92a32356

# Bind Rails and Vite to every interface so forwarded ports work.
ENV BINDING="0.0.0.0"
