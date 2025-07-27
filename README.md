# komed3 APT Repository

This is the official APT package repository for selected Debian/Ubuntu packages maintained by [komed3](https://komed3.de). It provides signed `.deb` packages for easy installation and updates via `apt`.

## Hosted Repository

URL: **https://deb.komed3.de**

Packages are served via HTTP and can be added to any APT-compatible system (Debian or Ubuntu) using the instructions below.

## GPG Signing Key

All packages are signed using a dedicated GPG key:

- **Key ID**: `0x917D04101CDC3CEE`
- **Fingerprint**: `044D 5C0B 1112 3691 2D40  5133 917D 0410 1CDC 3CEE`
- **Public Key**: [komed3-repo.gpg.key](https://deb.komed3.de/komed3-repo.gpg.key)

To import the key:

```bash
curl -fsSL https://deb.komed3.de/komed3-repo.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/komed3.gpg
```

## Repository Structure

This repository contains the release and metadata files for the APT distribution:

```
├── dists/
│   └── stable/
│       └── main/
│           └── binary-amd64/
│               ├── Packages.gz
│               ├── Release
│               └── InRelease
├── pool/
│   └── main/
│       └── ...
└── komed3-repo.gpg.key
```

## How to Use

To use the repository on your system:

**(1) Add GPG key and APT source:**

```bash
echo "deb [signed-by=/usr/share/keyrings/komed3.gpg arch=amd64] https://deb.komed3.de stable main" \
  | sudo tee /etc/apt/sources.list.d/komed3.list
```

**(2) Update and install any available package:**

```bash
sudo apt update
sudo apt install <package-name>
```

## License

This metadata repository contains no software, only packaging and signatures. License of hosted packages is defined per-package in `debian/copyright`.

## Maintainer

This repository is maintained by Paul Köhler ([komed3](https://komed3.de)).

**Mail:** deb@komed3.de  
**GitHub:** [github.com/komed3](https://github.com/komed3)  
**X:** [@komed3dev](https://x.com/komed3dev)
