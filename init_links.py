import os

cwd = os.getcwd()
dotfiles = [".bash_aliases",".monitor.sh",".sound.sh ",".vimrc ",".xinitrc",".Xmodmap", ".config/i3/config"]
dotfiles = [".config/i3/config"]

for dotfile in dotfiles:
    if not os.path.exists(f"~/{dotfile}"):
        os.system(f"cp '{cwd}/{dotfile}' ~/{dotfile}")
    else:
        os.system(f"ln -f ~/{dotfile} {cwd}/{dotfile}")
