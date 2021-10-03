A list of steps I do on fresh install of OS (Ubuntu with gnome).

# 1. Install vim, with plugin manager
`sudo apt-get install vim`

https://github.com/junegunn/vim-plug

`curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim`

Use :PlugInstall inside vim to install plugins


# 2.Customize gnome

`sudo apt install compizconfig-settings-manager`

`sudo apt-get install gnome-tweak-tools`

Disable right super doing stuff in gnmome-tweak-tool in : Keybouard & Mouse - Overview Shortut Right Super
Appearance - dark theme
Disable Natural Scrolling
Hide dock:
`gnome-extensions disable ubuntu-dock@ubuntu.com`


# 3. Install other stuff

```sh
sudo apt install -y rofi vlc curl python3-virtualenv
```



# 4. Install pycharm
Install pycharm using the tutorial in the link. Add installation home
to path by editing `.profile` file in home directory.

https://www.jetbrains.com/help/pycharm/installation-guide.html#toolbox


# 5. Update &  Upgrade

sudo apt-get update
sudo apt-get upgrade -y

# install rofi launcher
# https://github.com/davatorium/rofi
sudoapt install rofi


# 6. Generate ssh key

ssh-keygen

# 7. Install python stuff

sudo apt install python3-virtualenv
sudo apt install python3.9-venv

# 8.
sudo apt-get install xclip

# 9. Install docker and docker-compose
And make sure it can be run without root
https://docs.docker.com/engine/install/ubuntu/
https://docs.docker.com/engine/install/linux-postinstall/
https://docs.docker.com/compose/install/


sudo apt install postgresql-client-common
