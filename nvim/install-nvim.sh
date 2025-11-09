#!/bin/sh

NVIM_VERSION="v0.11.5"
NVIM_ARCHIVE="nvim-linux-x86_64.tar.gz"
NVIM_URL="https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/$NVIM_ARCHIVE"
DOWNLOAD_DIR="/tmp/nvim_download"
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

mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$INSTALL_DIR"

echo "Downloading neovim $NVIM_VERSION to $DOWNLOAD_DIR..."
cd "$DOWNLOAD_DIR" || exit 1
curl -LO "$NVIM_URL"

echo "Extracting neovim to $INSTALL_DIR..."
sudo tar --strip-components=1 -C "$INSTALL_DIR" -xzf "$DOWNLOAD_DIR/$NVIM_ARCHIVE"

echo "Neovim installed at $INSTALL_DIR/bin/nvim"
