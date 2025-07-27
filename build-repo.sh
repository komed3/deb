#!/bin/bash
set -e

# --------------------------
# CONFIG
# --------------------------

CODENAME="stable"
DIST="komed3"
ARCH="amd64"
REPO_DIR="$(pwd)"
POOL_DIR="$REPO_DIR/pool"
DIST_DIR="$REPO_DIR/dists/$CODENAME/main/binary-$ARCH"
GPG_KEY_ID="044D5C0B111236912D405133917D04101CDC3CEE"

# --------------------------
# PREP
# --------------------------

echo "[*] Create directory structure ..."
mkdir -p "$DIST_DIR"

echo "[*] Create package file ..."
dpkg-scanpackages "$POOL_DIR" /dev/null | tee "$DIST_DIR/Packages" | gzip -9 > "$DIST_DIR/Packages.gz"

echo "[*] Generate release file ..."
cat > "$REPO_DIR/dists/$CODENAME/Release" <<EOF
Origin: komed3
Label: komed3
Suite: stable
Codename: $CODENAME
Architectures: $ARCH
Components: main
Description: Komed3 Software Repository
EOF

apt-ftparchive release "$REPO_DIR/dists/$CODENAME" >> "$REPO_DIR/dists/$CODENAME/Release"

# --------------------------
# SIGNING
# --------------------------

if gpg --list-keys "$GPG_KEY_ID" >/dev/null 2>&1; then
    echo "[*] Sign release file with GPG ..."
    gpg --default-key "$GPG_KEY_ID" --output "$REPO_DIR/dists/$CODENAME/Release.gpg" \
        --armor --detach-sign "$REPO_DIR/dists/$CODENAME/Release"

    gpg --default-key "$GPG_KEY_ID" --output "$REPO_DIR/dists/$CODENAME/InRelease" \
        --armor --clearsign "$REPO_DIR/dists/$CODENAME/Release"
else
    echo "[!] GPG key '$GPG_KEY_ID' not found – release remains unsigned."
fi

echo "[✓] Repository updated."

# --------------------------
# COMMIT
# --------------------------

echo "[*] Commit changes ..."
cd "$REPO_DIR"

git add .
git commit -m "Update repository: $(date -u +"%Y-%m-%d %H:%M UTC")"
git push origin master

echo "[✓] Successfully commited."
