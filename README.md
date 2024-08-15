# Dots

Collection of dotfiles and scripts I use for development.

# Installation

Dotfiles are managed with GNU Stow. They are installed with:

```sh
stow --target=$HOME core
stow --target=$HOME i3
```

To install packages, run:

```sh
sh install_packages.sh
```
