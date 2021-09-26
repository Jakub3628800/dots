#!bin/bash
first=${1:0:1}
second=${1:1:3}


if [[ "$first" = "+" ||  "$first" = "-" ]] ; then
	amixer -D pulse sset Master $second%$first
else
	amixer -D pulse sset Master ${1:0:3}%
fi
