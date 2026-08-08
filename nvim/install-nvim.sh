#!/bin/sh
set -eu

NVIM_VERSION="v0.11.5"
NVIM_ARCHIVE="nvim-linux-x86_64.tar.gz"
NVIM_URL="https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/$NVIM_ARCHIVE"
NVIM_SHA256="728321db960a9b6af6c03881892a6abfd743bf759bc62d233f52fa1be64ace3c"
INSTALL_DIR="/opt/nvim-linux64"

if [ "$#" -ne 0 ]; then
	echo "Usage: $0" >&2
	exit 2
fi

if [ -x "$INSTALL_DIR/bin/nvim" ]; then
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
ARCHIVE_PATH="$DOWNLOAD_DIR/$NVIM_ARCHIVE"
STAGING_DIR=""
BACKUP_DIR=""

cleanup() {
	status=$?
	trap - EXIT

	if [ -n "$BACKUP_DIR" ] && sudo test -e "$BACKUP_DIR" && ! sudo test -e "$INSTALL_DIR"; then
		echo "Restoring the previous Neovim installation..." >&2
		if sudo mv "$BACKUP_DIR" "$INSTALL_DIR"; then
			BACKUP_DIR=""
		else
			echo "Could not restore Neovim; the previous installation remains at $BACKUP_DIR" >&2
		fi
	fi

	if [ -n "$STAGING_DIR" ]; then
		sudo rm -rf -- "$STAGING_DIR"
	fi
	rm -rf -- "$DOWNLOAD_DIR"
	exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

echo "Downloading neovim $NVIM_VERSION to $DOWNLOAD_DIR..."
curl --fail --location --show-error --output "$ARCHIVE_PATH" "$NVIM_URL"

echo "Verifying $NVIM_ARCHIVE..."
printf '%s  %s\n' "$NVIM_SHA256" "$ARCHIVE_PATH" | sha256sum -c -

echo "Extracting neovim to a staging directory..."
sudo install -d -m 755 "$(dirname "$INSTALL_DIR")"
STAGING_DIR=$(sudo mktemp -d "${INSTALL_DIR}.staging.XXXXXX")
sudo chmod 755 "$STAGING_DIR"
sudo tar --strip-components=1 --no-same-owner -C "$STAGING_DIR" -xzf "$ARCHIVE_PATH"

if ! sudo test -x "$STAGING_DIR/bin/nvim"; then
	echo "The staged archive does not contain an executable Neovim binary" >&2
	exit 1
fi

STAGED_VERSION=$(sudo "$STAGING_DIR/bin/nvim" --version | awk 'NR == 1 { print $2; exit }')
if [ "$STAGED_VERSION" != "$NVIM_VERSION" ]; then
	echo "The staged Neovim version is $STAGED_VERSION; expected $NVIM_VERSION" >&2
	exit 1
fi

if sudo test -e "$INSTALL_DIR" || sudo test -L "$INSTALL_DIR"; then
	BACKUP_DIR=$(sudo mktemp -d "${INSTALL_DIR}.backup.XXXXXX")
	sudo rmdir "$BACKUP_DIR"
	sudo mv "$INSTALL_DIR" "$BACKUP_DIR"
fi

if ! sudo mv "$STAGING_DIR" "$INSTALL_DIR"; then
	echo "Could not activate the staged Neovim installation" >&2
	exit 1
fi
STAGING_DIR=""

if [ -n "$BACKUP_DIR" ]; then
	sudo rm -rf -- "$BACKUP_DIR"
	BACKUP_DIR=""
fi

echo "Neovim installed at $INSTALL_DIR/bin/nvim"
