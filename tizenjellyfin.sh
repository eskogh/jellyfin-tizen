#!/bin/bash
#
# Jellyfin for Samsung TV on Tizen OS
#

name=${TIZEN_NAME}
email=${TIZEN_EMAIL}
company=${TIZEN_COMPANY}
city=${TIZEN_CITY}
state=${TIZEN_STATE}
country=${TIZEN_COUNTRY}
password=${TIZEN_PASSWORD}
ip=${TIZEN_IP}

for i in name email company city state country; do
	[ -z "\$$i" ] && echo "\$$i cannot be null"
done

[ -z $password ] && password=1234

function tizencert() {
	tizen certificate -a TizenCert -p "$password" -c "$country" -s "$state" -ct "$city" -o "$company" -n "$name" -e "$email" -f tizencert
	[ ! $? -eq 0 ] && echo "Error create certificate." && exit $? 
	[ -f /home/jellyfin/tizen-studio-data/keystore/author/tizencert.p12 ] && echo "Certificate saved as /home/jellyfin/tizen-studio-data/keystore/author/tizencert.p12"

	tizen security-profiles add -n "$name" -a /home/jellyfin/tizen-studio-data/keystore/author/tizencert.p12 -p "$password"
	if ! grep -q "$name" `tizen security-profiles list`; then
		break
	fi

	cat > /home/jellyfin/tizen-studio-data/profile/profiles.xml <<-EOF
	<?xml version="1.0" encoding="UTF-8" standalone="no"?>
	<profiles active="$name" version="3.1">
	<profile name="$name">
	<profileitem ca="" distributor="0" key="/home/jellyfin/tizen-studio-data/keystore/author/tizencert.p12" password="$password" rootca=""/>	
	<profileitem ca="/home/jellyfin/tizen-studio/tools/certificate-generator/certificates/distributor/tizen-distributor-ca.cer" distributor="1" key="/home/jellyfin/tizen-studio/tools/certificate-generator/certificates/distributor/tizen-distributor-signer.p12" password="tizenpkcs12passfordsigner" rootca=""/>
	<profileitem ca="" distributor="2" key="" password="" rootca=""/>
	</profile>
	</profiles>
	EOF

	return 0
}

function tizenwgt() {
	cd /jellyfin/jellyfin-tizen
	tizen build-web -e ".*" -e gulpfile.js -e README.md -e "node_modules/*" -e "package*.json" -e "yarn.lock"
	[ ! $? -eq 0 ] && echo "Error building." && exit $? 

	tizen package -t wgt -o . -s $name -- .buildResult <<<$password
	[ ! $? -eq 0 ] && echo "Error create package." && exit $?

	return 0
}

function tizensend() {
	if [ -z "$ip" ]; then
		break
	else

		while [ `/usr/bin/whoami` -ne "jellyfin" ]; then
			/usr/bin/su - jellyfin
		done

		/home/jellyfin/tizen-studio/tools/sdb devices
		[ ! $? -eq 0 ] && echo "Error starting bridge." && exit $?
		/home/jellyfin/tizen-studio/tools/sdb connect $ip
		[ ! $? -eq 0 ] && echo "Error connect to TV." && exit $?
		tvid=$(/home/jellyfin/tizen-studio/tools/sdb devices | grep "$ip" | awk '{print $NF}')

		tizen install -n /jellyfin/jellyfin-tizen/Jellyfin.wgt -t "$tvid"

	fi
	return 0
}