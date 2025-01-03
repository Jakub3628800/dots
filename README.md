<img src="dots-logo.svg" alt="logo" height="100">

Collection of dotfiles and scripts for my development environment.

- `core/`: minimal dotfiles usable on the server (shell + aliases and minimal vim config)
- `i3/`: desktop environment with i3, nvim, wezterm etc.. (still not wayland)


## Setting up dotfiles

Install apt packages:
```bash
make apt
```

Symlink dotfiles with stow:
```
make stow
```

Install python dependencies:

Since [PEP 668](https://peps.python.org/pep-0668/), debian and ubuntu package python dependencies in their apt repositories to be installable with `apt install python-<PACKAGE_NAME>`. I still want to install some tools from pypy, so I opt for managing the dependencies here in `uv.lock` and symlinking the tools I want to have globaly available in `i3/.local/bin`.

```
make python_packages
```


# Installing nvim from pre-built release:
https://github.com/neovim/neovim/blob/master/INSTALL.md#pre-built-archives-2
