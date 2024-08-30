<img src="dots-logo.svg" alt="logo" height="100">

A collection of dotfiles and scripts for optimizing my development environment.

## What are dotfiles?

Dotfiles are configuration files for various programs, typically hidden in your home directory (hence the leading dot in their names). This repository contains my personal dotfiles.

## Contents

- `core/`: Core dotfiles (usable on the server)
- `i3/`: Configuration for the i3 window manager and desktop environment.
- `install_packages.sh`: Script to install necessary packages trough apt & pip

## Installation

### Prerequisites

- [GNU Stow](https://www.gnu.org/software/stow/)
- Git

### Setting up dotfiles

1. Clone this repository:
   ```sh
   git clone https://github.com/yourusername/dots.git ~/.dots
   cd ~/.dots
   ```

2. Use GNU Stow to symlink the dotfiles:
   ```sh
   stow --target=$HOME core
   stow --target=$HOME i3
   ```

   This creates symlinks in your home directory, pointing to the files in this repository. GNU Stow may fail to create symlinks if the target files or directories already exist in your home directory, so you might need to manually move or delete conflicting files before running the stow commands.

### Installing packages

To install the required packages, run:

```sh
sh install_packages.sh
```
