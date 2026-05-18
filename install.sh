#!/usr/bin/env bash
################################
# Developer: Liad Binyamin
# Purpose: Install script for status-dashboard
# Version: 0.0.1
# Date: 13.5.26
set -euo pipefail
################################


IMAGE_NAME="status-dashboard"
CONTAINER_NAME="status-dashboard"
HOST_BIND="127.0.0.1"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINX_CONF_SRC="${REPO_DIR}/status-dashboard.conf"
NGINX_AVAILABLE="/etc/nginx/sites-available/status-dashboard"
NGINX_ENABLED="/etc/nginx/sites-enabled/status-dashboard"
NGINX_DEFAULT_ENABLED="/etc/nginx/sites-enabled/default"

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "ERROR: install.sh must be run as root (use sudo)." >&2
        exit 1
    fi
}

load_env() { #why not to suggest to copy it from existing exmaple ?
    if [[ ! -f "${REPO_DIR}/.env" ]]; then
        echo "ERROR: .env file not found at ${REPO_DIR}/.env" >&2
        exit 1
    fi

    set -a # why ?
    source "${REPO_DIR}/.env"
    set +a

    PORT="${PORT:-5000}" # why not debug these ?
    VERSION="${VERSION:-1.0.0}"

    if [[ -z "${API_KEY:-}" ]]; then
        echo "ERROR: API_KEY must be set in .env" >&2
        exit 1
    fi
}

build_image() { # why not docker compose ?
    docker build -t "${IMAGE_NAME}" "${REPO_DIR}"
}

remove_old_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "${CONTAINER_NAME}"; then
        docker rm -f "${CONTAINER_NAME}" >/dev/null
    fi
}

run_container() {
    docker run -d \
        --name "${CONTAINER_NAME}" \
        --restart unless-stopped \
        -p "${HOST_BIND}:${PORT}:${PORT}" \
        -e "PORT=${PORT}" \
        -e "VERSION=${VERSION}" \
        -e "API_KEY=${API_KEY}" \
        "${IMAGE_NAME}" >/dev/null
}

install_nginx_site() {
    cp "${NGINX_CONF_SRC}" "${NGINX_AVAILABLE}"
    ln -sfn "${NGINX_AVAILABLE}" "${NGINX_ENABLED}"

    rm -f "${NGINX_DEFAULT_ENABLED}"

    nginx -t
    systemctl enable nginx >/dev/null 2>&1 || true

    if systemctl is-active --quiet nginx; then
        systemctl reload nginx
    else
        systemctl start nginx
    fi
}

print_success() {
    echo " " # why not single printf ?
    echo "SUCCESS: status-dashboard is up."
    echo "  Local:  http://localhost/"
    echo "  API:    http://localhost/api/status"
}

main() { # why not to put this at the beginnging
    require_root
    load_env
    build_image
    remove_old_container
    run_container
    install_nginx_site
    print_success
}

main
