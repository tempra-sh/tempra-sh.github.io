#!/bin/sh
# Tempra installer — https://tempra.sh
# Usage: curl -fsSL https://tempra.sh/install.sh | bash
set -eu

REPO="tempra-sh/tempra"
INSTALL_DIR="/usr/local/bin"

main() {
    arch=$(detect_arch)
    artifact="tempra-linux-${arch}"

    echo "Tempra installer"
    echo "  arch:    ${arch}"
    echo "  target:  ${INSTALL_DIR}/tempra"
    echo ""

    latest=$(get_latest_version)
    echo "  version: ${latest}"

    url="https://github.com/${REPO}/releases/download/${latest}/${artifact}"
    checksum_url="https://github.com/${REPO}/releases/download/${latest}/checksums.txt"

    tmpdir=$(mktemp -d)
    trap 'rm -rf "${tmpdir}"' EXIT

    echo ""
    echo "Downloading ${artifact}..."
    download "${url}" "${tmpdir}/${artifact}"

    echo "Downloading checksums..."
    download "${checksum_url}" "${tmpdir}/checksums.txt"

    echo "Verifying checksum..."
    (cd "${tmpdir}" && sha256sum -c checksums.txt --ignore-missing --quiet)

    echo "Installing to ${INSTALL_DIR}/tempra..."
    chmod +x "${tmpdir}/${artifact}"

    if [ -w "${INSTALL_DIR}" ]; then
        mv "${tmpdir}/${artifact}" "${INSTALL_DIR}/tempra"
    else
        sudo mv "${tmpdir}/${artifact}" "${INSTALL_DIR}/tempra"
    fi

    echo ""
    echo "Installed tempra ${latest}"
    echo ""
    echo "Get started:"
    echo "  tempra scan    # see your system"
    echo "  tempra plan    # see what to harden"
    echo "  tempra apply   # apply hardening"
}

detect_arch() {
    machine=$(uname -m)
    case "${machine}" in
        x86_64|amd64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        *)
            echo "Error: unsupported architecture: ${machine}" >&2
            exit 1
            ;;
    esac
}

get_latest_version() {
    local version=""
    if command -v curl >/dev/null 2>&1; then
        version=$(curl -fsSL -o /dev/null -w '%{url_effective}' -L "https://github.com/${REPO}/releases/latest" \
            | sed 's|.*/||')
    elif command -v wget >/dev/null 2>&1; then
        version=$(wget --spider -S -q -O /dev/null "https://github.com/${REPO}/releases/latest" 2>&1 \
            | grep -i 'Location:' | tail -1 | sed 's|.*/||' | tr -d '\r')
    else
        echo "Error: curl or wget required" >&2
        exit 1
    fi

    if [ -z "${version}" ]; then
        echo "Error: could not determine latest version. Is there a release at" >&2
        echo "  https://github.com/${REPO}/releases?" >&2
        exit 1
    fi

    echo "${version}"
}

download() {
    url="$1"
    dest="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "${dest}" "${url}"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "${dest}" "${url}"
    fi
}

main
