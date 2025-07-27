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
INDEX_FILE="$REPO_DIR/REPO-INDEX.html"

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
# INDEXING
# --------------------------

echo "[*] Create custom index file ..."
{
    echo "<!DOCTYPE html><html><head><meta charset='utf-8'><title>komed3 Repository</title></head><body>"
    echo "<h1>komed3 APT Repository Index</h1><ul>"

    for file in $(find "$POOL_DIR" -type f -name "*.deb" | sort); do
        rel_path="${file#$REPO_DIR/}"
        echo "<li><a href=\"$rel_path\">$rel_path</a></li>"
    done

    echo "</ul><p>Update: $(date -u '+%Y-%m-%d %H:%M UTC')</p></body></html>"
} > "$INDEX_FILE"

# --------------------------
# PREP
# --------------------------

echo "[*] Create directory structure ..."
mkdir -p "$DIST_DIR"

echo "[*] Create package file ..."
dpkg-scanpackages "$POOL_DIR" "pool" | tee "$DIST_DIR/Packages" | gzip -9 > "$DIST_DIR/Packages.gz"

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

echo "[*] Commit changes via Git (signed if configured) ..."
cd "$REPO_DIR"

git add .
git commit -S -m "Update repository: $(date -u +"%Y-%m-%d %H:%M UTC")" || echo "No changes to commit."
git push origin master

echo "[✓] Git commit pushed."
