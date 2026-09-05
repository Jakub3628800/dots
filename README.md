<img src="dots-logo.svg" alt="dots logo" height="100">

# dots

Small, personal dotfiles for an Ubuntu development machine. GNU Stow owns the
links; the Makefiles install only the packages required by the tracked setup.

- `core/` contains Zsh, Git, tmux-related helpers, and small command-line tools.
- `desktop/` contains the Sway/Wayland setup plus WezTerm and Ghostty configs.
- `nvim/` installs a pinned Neovim release and its plugin configuration.

The supported baseline is Ubuntu 24.04 on x86-64 with APT, `sudo`, and a
systemd user session. The desktop package assumes Sway/Wayland.

## Install

```sh
sudo apt-get update
sudo apt-get install -y git make
git clone https://github.com/Jakub3628800/dots.git ~/repos/dots
cd ~/repos/dots
make install
```

The first core install also creates a Rust toolchain and compiles the few Cargo
tools in `core/Makefile`, so it takes longer than later runs. Existing regular
files are not overwritten by Stow; move any reported conflicts and rerun the
command.

For a machine without the Sway desktop:

```sh
make install-core install-nvim
```

The repository does not replace `~/.profile`. Zsh continues to source the
machine's existing profile when it is a regular file owned by the current user
and is not group/world writable.

## Everyday commands

```sh
make link             # refresh links only
make update           # compatibility alias for `make link`
make upgrade          # reconcile managed packages, Neovim, and links
make system-upgrade   # explicitly upgrade all host APT packages
make clean            # remove managed links
```

`make test` runs the fast script, Stow, Sway, WezTerm, and Neovim config checks.
`make test-bootstrap` performs the slower clean-Ubuntu Docker builds. The full
pre-commit suite can be run with `prek run --all-files`.

## Development checks

Run `prek install` once per clone to enable both the pre-commit and commit-message
hooks. Commits use Conventional Commits, for example `fix(core): handle empty input`.

The hooks lint and format Python (including the extensionless utilities), Bash/POSIX
shell scripts, and Lua, and check Markdown, spelling, secrets, and tracked symlinks.
Zsh has a syntax check but is deliberately excluded from shfmt. Formatters update
files in place; review their changes and stage them before retrying a commit.
Markdown allows long lines and the README logo. Spelling exceptions belong in
`_typos.toml`; keep them limited to intentional names and abbreviations.

Ruff enables `ALL` stable rules, targeting Python 3.12. Its lint and formatter
settings live directly in `.pre-commit-config.yaml`, not a separate Ruff config.
The hook ignores ambient Ruff settings so local runs and CI use the same rules.
Exceptions are documented beside the hook arguments: conflicting formatter/docstring
rules, copyright headers, intentional CLI output, and unittest-native assertions.
Reviewed SQL/subprocess false positives have individual `noqa` comments; safety
rules remain enabled elsewhere. Ruff upgrades can introduce new rules and findings.

Use `prek run --all-files` to run the file checks manually, or
`prek run ruff-check --all-files` for the strict Python lint checks alone.
Commit-message checks run separately at the `commit-msg` stage. Desktop/Neovim
configuration checks and Docker bootstrap tests remain in the Make targets rather
than running on every commit.

## Local choices

Machine-specific settings stay outside the repository:

- `~/.bash_aliases_local` for shell aliases and functions.
- `~/.zshrc_local` for machine-specific paths and shell startup.
- `~/.config/sway/config.local` for Sway variable or input overrides.

Both terminal configs are linked. Sway currently starts WezTerm; the Ghostty
config is available for manual use while the transition is in progress.
WezTerm, Ghostty, Google Chrome, Slack, and 1Password are intentionally not
installed by these Makefiles. Slack and 1Password are started only when found;
install the terminal/browser you use or override the Sway defaults locally.

## SSH agent

Local Zsh shells share a lazily started systemd SSH agent at
`$XDG_RUNTIME_DIR/dots-ssh-agent.socket`. Remote shells preserve a forwarded
agent instead. After login or reboot, load a key once and enter its passphrase:

```sh
ssh-add ~/.ssh/id_ed25519
```

## Included utilities

- `cmd-picker` selects tmux sessions, containers, pull requests, or worktrees.
- `pomo` is an interactive Pomodoro timer. Its database defaults to
  `~/.local/share/pomo/pomo.db`; set `POMO_DB_PATH` to override it.
