#!/bin/bash
set -euo pipefail

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
INDEX_FILE="$REPO_DIR/index.txt"

# --------------------------
# CLEANUP
# --------------------------

echo "[*] Check for outdated .deb versions ..."

mapfile -t pkg_files < <(find "$POOL_DIR" -type f -name "*.deb" | sort)

declare -A latest_versions

for deb_path in "${pkg_files[@]}"; do
    pkg_info=$(dpkg-deb -f "$deb_path" Package Version)
    pkg_name=$(echo "$pkg_info" | sed -n '1p')
    pkg_ver=$(echo "$pkg_info" | sed -n '2p')

    if [[ -n "${latest_versions[$pkg_name]+x}" ]]; then
        if dpkg --compare-versions "$pkg_ver" gt "${latest_versions[$pkg_name]%|*}"; then
            old_path="${latest_versions[$pkg_name]#*|}"
            echo "    Removing old version: $old_path"
            rm -f "$old_path"
            latest_versions[$pkg_name]="$pkg_ver|$deb_path"
        else
            echo "    Removing outdated: $deb_path"
            rm -f "$deb_path"
        fi
    else
        latest_versions[$pkg_name]="$pkg_ver|$deb_path"
    fi
done

# --------------------------
# PREP
# --------------------------

echo "[*] Create directory structure ..."
mkdir -p "$DIST_DIR"

echo "[*] Create package file ..."
dpkg-scanpackages -m pool > "$DIST_DIR/Packages"
gzip -9 -c "$DIST_DIR/Packages" > "$DIST_DIR/Packages.gz"

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
# INDEXING
# --------------------------

echo "[*] Creating repository index ..."
echo "komed3.deb Repository – $(date -u +'%Y-%m-%d %H:%M UTC')" > "$INDEX_FILE"
echo "" >> "$INDEX_FILE"
find "$POOL_DIR" -type f -name "*.deb" | sort | while read -r deb; do
    name=$(basename "$deb")
    size=$(stat -c%s "$deb")
    mtime=$(stat -c%y "$deb" | cut -d'.' -f1)
    echo "$name – $(numfmt --to=iec --suffix=B "$size") – $mtime" >> "$INDEX_FILE"
done

# --------------------------
# COMMIT
# --------------------------

echo "[*] Commit changes via Git (signed if configured) ..."
cd "$REPO_DIR"

if git diff --quiet && git diff --cached --quiet; then
    echo "[✓] Nothing to commit."
else
    git add .
    git commit -S -m "Update repository: $(date -u +"%Y-%m-%d %H:%M UTC")"
    git push origin master
    echo "[✓] Successfully committed."
fi
