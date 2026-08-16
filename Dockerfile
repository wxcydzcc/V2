# syntax=docker/dockerfile:1

FROM nginx:stable-bookworm

ARG TARGETARCH
ARG V2RAY_VERSION=v5.52.0
ARG V2RAY_AMD64_SHA256=98b123c0f3ba1138eedc2be9b25935e5289236cb6800d1e6370a08d86e797177
ARG V2RAY_ARM64_SHA256=bd87731c32d429eb6986f2a7484b4a78bfc1be4a4de1e25901265c52aa854970

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gettext-base unzip \
    && case "${TARGETARCH}" in \
        amd64) V2RAY_ASSET="v2ray-linux-64.zip"; V2RAY_SHA256="${V2RAY_AMD64_SHA256}" ;; \
        arm64) V2RAY_ASSET="v2ray-linux-arm64-v8a.zip"; V2RAY_SHA256="${V2RAY_ARM64_SHA256}" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl --fail --location --retry 3 --output /tmp/v2ray.zip \
        "https://github.com/v2fly/v2ray-core/releases/download/${V2RAY_VERSION}/${V2RAY_ASSET}" \
    && echo "${V2RAY_SHA256}  /tmp/v2ray.zip" | sha256sum --check --strict - \
    && unzip /tmp/v2ray.zip v2ray geoip.dat geosite.dat -d /app \
    && chmod 0755 /app/v2ray \
    && rm -f /tmp/v2ray.zip \
    && apt-get purge -y --auto-remove unzip \
    && rm -rf /var/lib/apt/lists/* \
    && chown -R nginx:nginx /app /var/cache/nginx

COPY --chown=nginx:nginx config.template.json nginx.conf entrypoint.sh /app/

RUN chmod 0755 /app/entrypoint.sh

USER nginx
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["curl", "--fail", "--silent", "--show-error", "http://127.0.0.1:8080/healthz"]

ENTRYPOINT ["/app/entrypoint.sh"]

