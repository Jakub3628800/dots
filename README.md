<img src="dots-logo.svg" alt="logo" height="100">

Collection of dotfiles and scripts for my development environment.

The repository:
- installs packages through multiple package managers
- manages dotfiles with stow

It's divided into two subpackages:

- `core/`: minimal dotfiles usable on the server
- `desktop/`: sway desktop environment


## Setting up dotfiles

```bash
make install
```

Without desktop environment:
```
make install-core
```

## Update

```bash
make update
```

Without desktop environment:
```bash
make update-core
```
