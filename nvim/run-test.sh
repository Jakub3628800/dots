#!/bin/sh
set -eu

NVIM=$1
MODE=$2
COMPONENT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
TEST_DATA="$COMPONENT_DIR/.test-data"

case "$MODE" in
check | prepare) ;;
*)
    echo "Unknown test mode: $MODE" >&2
    exit 2
    ;;
esac
if [ ! -x "$NVIM" ]; then
    echo "Neovim not installed at $NVIM" >&2
    exit 1
fi
if [ -L "$TEST_DATA" ]; then
    echo "Refusing a symlinked test-data directory: $TEST_DATA" >&2
    exit 1
fi

cd "$COMPONENT_DIR"
# Configuration and binary changes require a fresh, explicitly prepared seed.
FINGERPRINT=$(
    {
        sha256sum "$NVIM"
        find home/.config/nvim -type f -print0 | sort -z | xargs -0 sha256sum
    } | sha256sum
)
if [ "$MODE" = check ] && [ -f home/.config/nvim/lazy-lock.json ]; then
    if [ ! -f "$TEST_DATA/fingerprint" ] || [ "$(head -n 1 "$TEST_DATA/fingerprint")" != "$FINGERPRINT" ]; then
        echo "Neovim test data is missing or stale; run make -C nvim prepare-test" >&2
        exit 1
    fi
fi

TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dots-nvim-test.XXXXXX")
trap 'rm -rf -- "$TEST_ROOT"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

# Copy config too: plugin managers may rewrite lazy-lock.json during setup.
export HOME="$TEST_ROOT/home"
export XDG_CONFIG_HOME="$TEST_ROOT/config"
export XDG_DATA_HOME="$TEST_ROOT/data"
export XDG_STATE_HOME="$TEST_ROOT/state"
export XDG_CACHE_HOME="$TEST_ROOT/cache"
export XDG_CONFIG_DIRS="$TEST_ROOT/config-dirs"
export XDG_DATA_DIRS="$TEST_ROOT/data-dirs"
export NVIM_APPNAME=nvim
export DOTS_NVIM_TEST_MODE="$MODE"
export DOTS_NVIM_TEST_SCRIPT="$COMPONENT_DIR/test-config.lua"
export DOTS_NVIM_TEST_DONE="$TEST_ROOT/completed"
unset VIMINIT EXINIT MYVIMRC LUA_PATH LUA_CPATH
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
cp -R home/.config/nvim "$XDG_CONFIG_HOME/nvim"
if [ "$MODE" = check ] && [ -d "$TEST_DATA/data" ]; then
    cp -R "$TEST_DATA/data/." "$XDG_DATA_HOME/"
fi

# Use the normal headless event loop: -l can exit during nested plugin waits.
# Catch runner errors explicitly instead of hiding them behind a later +qa.
timeout 300 "$NVIM" --headless -i NONE -u NONE \
    -c 'lua local ok, err = pcall(dofile, vim.env.DOTS_NVIM_TEST_SCRIPT); if not ok then io.stderr:write(tostring(err) .. "\n"); vim.cmd("cquit 1") end'
if [ ! -f "$DOTS_NVIM_TEST_DONE" ]; then
    echo "Neovim exited before completing the configuration checks" >&2
    exit 1
fi

if [ "$MODE" = prepare ]; then
    # Publish only successful setup; normal checks never modify the reusable seed.
    rm -rf -- "$TEST_DATA"
    mkdir -p "$TEST_DATA"
    cp -R "$XDG_DATA_HOME" "$TEST_DATA/data"
    printf '%s\n' "$FINGERPRINT" >"$TEST_DATA/fingerprint"
    echo "Prepared isolated Neovim test data in $TEST_DATA"
fi
