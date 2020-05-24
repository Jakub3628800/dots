alias monitor2on="xrandr --output HDMI-1 --mode 1920x1080 --auto"
alias monitor1off="xrandr --output eDP-1 --off"
alias monitor1on="xrandr --output eDP-1 --mode 1920x1080 --auto"
alias monitor2off="xrandr --output HDMI-1 --off"
alias monitor2l="xrandr --output HDMI-1 --mode 1920x1080 --left-of eDP-1"
alias monitor2r="xrandr --output HDMI-1 --mode 1920x1080 --right-of eDP-1"
alias monitor2r="xrandr --output HDMI-1 --mode 1920x1080 --same-as eDP-1"


alias sound="~/.sound.sh"
alias soundmute="~/.sound.sh -100"

alias lock="i3lock"

alias ls="ls -G -CF"
alias la="ls -a"
alias ll="ls -lG -la"
alias cd..="cd .."

alias python="python3"
alias pip="pip3"


alias dots='/usr/bin/git --git-dir=$HOME/dots/ --work-tree=$HOME'


alias g='git'
alias gs='git status'
alias gc='git checkout'
alias gl='git log'
alias gb='git branch'
alias g trash='git reset HEAD && git checkout -- .'

alias d='docker'
alias dc='docker-compose'

