#!/usr/bin/env bash
set -Eeuo pipefail

readonly CONFIG_TEMPLATE="/app/config.template.json"
readonly CONFIG_FILE="/tmp/config.json"
readonly NGINX_TEMPLATE="/app/nginx.conf"
readonly NGINX_CONFIG="/tmp/nginx.conf"

: "${UUID:?UUID is required. Configure it as a Koyeb secret-backed environment variable.}"

VMESS_WSPATH="${VMESS_WSPATH:-/vmess}"
VLESS_WSPATH="${VLESS_WSPATH:-/vless}"

if [[ ! "${UUID}" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$ ]]; then
    echo "UUID must be a valid RFC 9562 UUID." >&2
    exit 64
fi

validate_ws_path() {
    local name="$1"
    local value="$2"

    if [[ ! "${value}" =~ ^/[A-Za-z0-9._~/-]+$ ]] || [[ "${value}" == "/" ]] || [[ "${value}" == *"//"* ]]; then
        echo "${name} must start with /, contain only URL path-safe characters, and cannot be /." >&2
        exit 64
    fi
}

validate_ws_path "VMESS_WSPATH" "${VMESS_WSPATH}"
validate_ws_path "VLESS_WSPATH" "${VLESS_WSPATH}"

if [[ "${VMESS_WSPATH}" == "${VLESS_WSPATH}" ]]; then
    echo "VMESS_WSPATH and VLESS_WSPATH must be different." >&2
    exit 64
fi

export UUID VMESS_WSPATH VLESS_WSPATH
umask 077
envsubst "\${UUID} \${VMESS_WSPATH} \${VLESS_WSPATH}" < "${CONFIG_TEMPLATE}" > "${CONFIG_FILE}"
envsubst "\${VMESS_WSPATH} \${VLESS_WSPATH}" < "${NGINX_TEMPLATE}" > "${NGINX_CONFIG}"

/app/v2ray test -c "${CONFIG_FILE}"
nginx -t -c "${NGINX_CONFIG}"

v2ray_pid=""
nginx_pid=""

shutdown() {
    trap - EXIT INT TERM

    if [[ -n "${nginx_pid}" ]]; then
        kill -QUIT "${nginx_pid}" 2>/dev/null || true
    fi
    if [[ -n "${v2ray_pid}" ]]; then
        kill -TERM "${v2ray_pid}" 2>/dev/null || true
    fi

    wait "${nginx_pid}" "${v2ray_pid}" 2>/dev/null || true
}

trap shutdown EXIT INT TERM

/app/v2ray run -c "${CONFIG_FILE}" &
v2ray_pid="$!"
nginx -c "${NGINX_CONFIG}" -g 'daemon off;' &
nginx_pid="$!"

set +e
wait -n "${v2ray_pid}" "${nginx_pid}"
status="$?"
set -e

shutdown
exit "${status}"
