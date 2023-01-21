#!/bin/bash

printf "Set your IP in Developer Mode in Apps in Tizen OS on your TV. \
\( Press 1-2-3-4-5 when have Apps open pn TV \) \
Enter the IP of your docker host when enable Developer mode, not the IP of docker container.\n\n"

read -n1 -p "Are Samsung your TV in developer mode? [y/N]" devmode

case $devmode in
	[Yy]) tizensend ;;
	*) break ;;
esac

function tizensend() {
	while [ -z "$ip"]; then
		read -p "Enter IP of Samsung TV: " ip
	done

	while [ `/usr/bin/whoami` -ne "jellyfin" ]; then
		/usr/bin/su - jellyfin
	done

	/home/jellyfin/tizen-studio/tools/sdb devices
	[ ! $? -eq 0 ] && echo "Error starting bridge." && exit $?
	/home/jellyfin/tizen-studio/tools/sdb connect $ip
	[ ! $? -eq 0 ] && echo "Error connect to TV." && exit $?
	tvid=$(/home/jellyfin/tizen-studio/tools/sdb devices | grep "$ip" | awk '{print $NF}')

	tizen install -n /jellyfin/jellyfin-tizen/Jellyfin.wgt -t "$tvid"
}