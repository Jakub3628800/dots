import os

cwd = os.getcwd()
for dotfile in [".bash_aliases",".monitor.sh",".sound.sh ",".vimrc ",".xinitrc",".Xmodmap"]:

    if not os.path.exists(f"~/{dotfile}"):
        os.system(f"cp '{cwd}/{dotfile}' ~/{dotfile}")
    else:
        os.system(f"ln -f ~/{dotfile} {cwd}/{dotfile}")
