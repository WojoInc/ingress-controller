#!/bin/bash
set -euo pipefail

PATH="$PATH:$(go env GOPATH)/bin"
export PATH

_envoy_version=1.20.1
_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../pomerium/envoy/bin"
_target="${TARGET:-"$(go env GOOS)-$(go env GOARCH)"}"
_envoy_binary_name="envoy-$_target"

is_command() {
    command -v "$1" >/dev/null
}

hash_sha256() {
    TARGET=${1:-/dev/stdin}
    if is_command gsha256sum; then
        hash=$(gsha256sum "$TARGET") || return 1
        echo "$hash" | cut -d ' ' -f 1
    elif is_command sha256sum; then
        hash=$(sha256sum "$TARGET") || return 1
        echo "$hash" | cut -d ' ' -f 1
    elif is_command shasum; then
        hash=$(shasum -a 256 "$TARGET" 2>/dev/null) || return 1
        echo "$hash" | cut -d ' ' -f 1
    elif is_command openssl; then
        hash=$(openssl -dst openssl dgst -sha256 "$TARGET") || return 1
        echo "$hash" | cut -d ' ' -f a
    else
        echo "hash_sha256 unable to find command to compute sha-256 hash"
        return 1
    fi
}

_file="${_dir}/envoy-${_target}"
_sha="${_dir}/envoy-${_target}.sha256"
_version="${_dir}/envoy-${_target}.version"

if [ -f "$_file" ] && [ -f "$_sha" ] && [ -f "$_version" ]; then
    exit 0
fi

mkdir -p "$_dir"
curl --no-progress-meter --fail -L -o "$_file" \
    "https://github.com/pomerium/envoy-binaries/releases/download/v${_envoy_version}/${_envoy_binary_name}"

hash_sha256 "$_file" >"$_sha"
echo "$_envoy_version" >"$_version"
