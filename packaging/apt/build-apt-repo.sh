#!/bin/bash
# Regenerates docs/apt (the GitHub Pages-hosted APT repository) from the
# .deb(s) currently in packaging/deb/dist.
#
# Usage:
#   GPG_KEY_ID=<fingerprint> packaging/apt/build-apt-repo.sh
#
# Requires: dpkg-scanpackages, apt-ftparchive, gpg, and a secret key matching
# GPG_KEY_ID already imported (gpg --list-secret-keys). The public half of
# that key must be published at docs/apt/elyra-archive-keyring.{asc,gpg} —
# this script re-exports it every run, so it always matches the signing key.
set -euo pipefail

: "${GPG_KEY_ID:?Set GPG_KEY_ID to the fingerprint of the repo signing key (gpg --list-secret-keys)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEB_DIST="$REPO_ROOT/packaging/deb/dist"
APT_ROOT="$REPO_ROOT/docs/apt"

if ! ls "$DEB_DIST"/*.deb >/dev/null 2>&1; then
    echo "No .deb files in $DEB_DIST — run packaging/deb/build-deb.sh first." >&2
    exit 1
fi

echo "==> Resetting $APT_ROOT"
rm -rf "$APT_ROOT"
mkdir -p "$APT_ROOT/pool/main" "$APT_ROOT/dists/stable/main/binary-amd64"

echo "==> Copying .deb(s) into pool"
cp "$DEB_DIST"/*.deb "$APT_ROOT/pool/main/"

echo "==> Generating Packages index"
(cd "$APT_ROOT" && dpkg-scanpackages --arch amd64 pool/ > dists/stable/main/binary-amd64/Packages)
gzip -9c "$APT_ROOT/dists/stable/main/binary-amd64/Packages" > "$APT_ROOT/dists/stable/main/binary-amd64/Packages.gz"

echo "==> Generating Release"
apt-ftparchive -c "$SCRIPT_DIR/apt-ftparchive.conf" release "$APT_ROOT/dists/stable" \
    > "$APT_ROOT/dists/stable/Release.tmp"
mv "$APT_ROOT/dists/stable/Release.tmp" "$APT_ROOT/dists/stable/Release"

echo "==> Signing (key $GPG_KEY_ID)"
gpg --default-key "$GPG_KEY_ID" --clearsign \
    -o "$APT_ROOT/dists/stable/InRelease" "$APT_ROOT/dists/stable/Release"
gpg --default-key "$GPG_KEY_ID" -abs \
    -o "$APT_ROOT/dists/stable/Release.gpg" "$APT_ROOT/dists/stable/Release"

echo "==> Exporting public key"
gpg --export --armor "$GPG_KEY_ID" > "$APT_ROOT/elyra-archive-keyring.asc"
gpg --dearmor < "$APT_ROOT/elyra-archive-keyring.asc" > "$APT_ROOT/elyra-archive-keyring.gpg"

echo "==> Done. Commit and push docs/apt to publish via GitHub Pages."
