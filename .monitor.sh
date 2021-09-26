#!/bin/bash

# Easy way to configure my monitors with xrandr

# params
monitor=$1 # Which monitor am I setting?
on_off=$2 # Setting this monitor on or off?
left_right=$3 # Left or Right of the main monitor?

# set off flag for xrandr
if [ "$on_off" = "off" ]; then off_flag="--off";  else off_flag=""; fi

# set left or right of main monitor for xrandr
if [ "$left_right" = "right" ]; then position="--right-of eDP-1"; else position="--left-of eDP-1"; fi


case $monitor in

  1)
	# In-built monitor
	monitor="eDP-1"
	resolution="--mode 1920x1080"
	position=""
    ;;

  2)
	# External monitor
	monitor="HDMI-1"
	resolution="--mode 1920x1080"
    ;;
  *)
    echo -n "Unknown monitor"
    ;;
esac

if [ "$off_flag" = "--off" ]; then resolution=""; fi

commnd="xrandr --output $monitor $resolution $position $off_flag"
echo $commnd
eval " $commnd"
