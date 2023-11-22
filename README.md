# Dots

Collection of dotfiles and scripts I use on my machines for development. I3, vim, zsh, xinit keyboard layout, etc.

# Installation

All the dotfiles are in `/home` directory, and I link them with:
```bash
./init_links.sh
```
This script creates hard links to files in home directory.

# Keyboard layout
For keyboard, I use `/home/.local/bin/keyboard` (xinit) to detect which
keyboard I'm currently using and set preferred layout - mostly just swap
capslock and escape.

# Monitor layout
I use autorandr to detect which monitor setup I'm using and set it up. Monitor layouts aren't yet saved in this repo.

# Helper scripts

## Pre-commit
`/home/.local/bin/pre-commit` is a script that I use for running pre-commit.
It saves time from typing `--from-ref` and `--to-ref` every time I want to
run it on previous commits.

## GitHub Pull Request
`home/.local/bin/ghpr` is a script that I use for opening pull requests with
gh cli. It's a nice alias and it also sends notification when the PR checks are finished.
