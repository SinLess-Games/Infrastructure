# syntax=docker/dockerfile:1.7

# ==============================================================================
# Builder stage
# ------------------------------------------------------------------------------
# This stage installs MkDocs and all documentation dependencies, then compiles the
# static site into /src/site.
#
# Alpine keeps the image small, but some Python packages may need temporary build
# tooling. Those packages stay in this builder stage and never reach the final
# Nginx runtime image.
# ==============================================================================

FROM python:3.12-alpine AS builder

# Keep Python/Pip behavior predictable in CI and Docker builds.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

# MkDocs will run from /src.
WORKDIR /src

# Install temporary build dependencies for Python packages that may compile wheels.
# These are only in the builder image.
RUN apk add --no-cache --virtual .build-deps \
      build-base \
      gcc \
      musl-dev \
      libffi-dev \
      openssl-dev

# Copy dependency file first so Docker can cache the pip install layer.
# This means docs content changes do not force a dependency reinstall.
COPY Docs/requirements.txt /tmp/requirements.txt

# Install MkDocs and plugins/themes declared in Docs/requirements.txt.
# The cache mount speeds up local and CI rebuilds when BuildKit is enabled.
RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --upgrade pip setuptools wheel && \
    python -m pip install -r /tmp/requirements.txt

# Copy only the files needed to build the documentation site.
COPY mkdocs.yaml /src/mkdocs.yaml
COPY Docs /src/Docs

# Build the static MkDocs site.
#
# --clean:
#   Removes stale files from previous builds.
#
# --strict:
#   Fails the build on warnings, broken links, missing pages, bad nav entries,
#   or plugin/theme warnings that MkDocs surfaces.
RUN mkdocs build --clean --strict


# ==============================================================================
# Runtime stage
# ------------------------------------------------------------------------------
# This stage serves the already-built static site with unprivileged Nginx.
#
# The final image does not contain Python, pip, MkDocs, source Markdown build
# tooling, or compiler packages.
# ==============================================================================

FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime

# Document the port used by nginx-unprivileged and Docs/nginx.conf.
EXPOSE 8080

# Copy the hardened Nginx site config.
COPY Docs/nginx.conf /etc/nginx/conf.d/default.conf

# Copy only the static output from MkDocs into Nginx's web root.
COPY --from=builder /src/site /usr/share/nginx/html

# Lightweight container health check.
# This expects Docs/nginx.conf to expose /healthz.
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/healthz || exit 1