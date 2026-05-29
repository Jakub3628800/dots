#!/bin/sh
set -eu

NVIM_VERSION="v0.11.5"
NVIM_ARCHIVE="nvim-linux-x86_64.tar.gz"
NVIM_URL="https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/$NVIM_ARCHIVE"
NVIM_SHA256="728321db960a9b6af6c03881892a6abfd743bf759bc62d233f52fa1be64ace3c"
INSTALL_DIR="/opt/nvim-linux64"
FORCE=false

while [ $# -gt 0 ]; do
	case $1 in
		--force)
			FORCE=true
			shift
			;;
		*)
			shift
			;;
	esac
done

if [ "$FORCE" = false ] && [ -f "$INSTALL_DIR/bin/nvim" ]; then
	INSTALLED_VERSION=$("$INSTALL_DIR/bin/nvim" --version | head -n 1 | awk '{print $2}')
	if [ "$INSTALLED_VERSION" = "$NVIM_VERSION" ]; then
		echo "Neovim $NVIM_VERSION is already installed at $INSTALL_DIR/bin/nvim"
		exit 0
	fi
fi

if ! command -v sha256sum >/dev/null 2>&1; then
	echo "sha256sum is required to verify $NVIM_ARCHIVE" >&2
	exit 1
fi

DOWNLOAD_DIR=$(mktemp -d "${TMPDIR:-/tmp}/nvim_download.XXXXXX")
trap 'rm -rf "$DOWNLOAD_DIR"' EXIT HUP INT TERM
ARCHIVE_PATH="$DOWNLOAD_DIR/$NVIM_ARCHIVE"

echo "Downloading neovim $NVIM_VERSION to $DOWNLOAD_DIR..."
curl --fail --location --show-error --output "$ARCHIVE_PATH" "$NVIM_URL"

echo "Verifying $NVIM_ARCHIVE..."
printf '%s  %s\n' "$NVIM_SHA256" "$ARCHIVE_PATH" | sha256sum -c -

echo "Extracting neovim to $INSTALL_DIR..."
sudo install -d -m 755 "$INSTALL_DIR"
sudo tar --strip-components=1 --no-same-owner -C "$INSTALL_DIR" -xzf "$ARCHIVE_PATH"

echo "Neovim installed at $INSTALL_DIR/bin/nvim"
