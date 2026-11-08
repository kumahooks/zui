#!/bin/sh

set -eu

zig_version="0.17.1"
zig_checksum="3581863e3cbcfd0fce0efc682ce7e9e93da96668a977791d356a26d2a7e9b17a"
archive_name="zig-x86_64-linux-${zig_version}.tar.xz"
archive_path="zig/cache/${archive_name}"
archive_url="https://ziglang.org/download/${zig_version}/${archive_name}"

cached_checksum=""
if [ -f "$archive_path" ]; then
    cached_checksum="$(sha256sum "$archive_path" | cut -d ' ' -f 1)"
fi

if [ "$cached_checksum" != "$zig_checksum" ]; then
    mkdir -p zig/cache
    echo "downloading ${archive_url}"
    curl --fail --location --silent --show-error --output "$archive_path" "$archive_url"

    downloaded_checksum="$(sha256sum "$archive_path" | cut -d ' ' -f 1)"
    if [ "$downloaded_checksum" != "$zig_checksum" ]; then
        echo "checksum mismatch for ${archive_name}" >&2
        echo "expected: ${zig_checksum}" >&2
        echo "actual:   ${downloaded_checksum}" >&2
        exit 1
    fi
fi

echo "extracting ${archive_name}"
rm -rf zig/doc zig/lib
tar -xf "$archive_path" -C zig --strip-components=1

echo "installed $(pwd)/zig/zig"

