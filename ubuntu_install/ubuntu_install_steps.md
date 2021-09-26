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

https://github.com/davatorium/rofi
`sudo apt install rofi`
sudo apt install python3-virtualenv
sudo apt install vlc



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
sudo apt install python3-virtualenv

# 6. Generate ssh key

ssh-keygen






