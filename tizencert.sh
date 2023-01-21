#!/bin/bash
#
#  Tizen Certificate Generator
#  erik@skogh.dev
#

printf "Gadenerate certificate from tizen-studio"
printf "Please enter your information: \n\n"

name="John Doe"
read -p "Name [$name]: " name
email=name@domain.com
read -p "E-mail [$email]: " email
company="Your Organisation"
read -p "Company" [$company]: " company
city=Stockholm
read -p "City [$city]: " city
state=SE
read -p  "State [$state]: " state
country=SE
read -n 2 -p "Country code [$country]: " country
read -p "Password: " password

if [ -z {$name+x} ]; then
	echo "Name is mandatory"
	break
else if [ -z {$email+x} ]; then
	echo "E-mail is mandatory"
	break
else if [ -z {$company+x} ]; then
	echo "Company is mandatory"
	break
else if [ -z {$city+x} ]; then
	echo  "City is mandatory"
	break
else if [ -z {$state+x} ]; then
	echo "State is mandatory"
	break
else if [ -z {$country+x} ]; then
	echo "Country is mandatory"
	break
else if [ -z {$password+x} ]; then
	password=1234
	echo "Password is set to \'1234\'"
else
	echo "Generating certificate"
	tizen certificate -a TizenCert -p "$password" -c "$country" -s "$state" -ct "$city" -o "$company" -n "$name" -e "$email" -f tizencert
	[ ! $? -eq 0 ] && exit $?
fi

if [[ `tizen security-profiles list|wc -l` -lt 2 ]]; then
	tizen security-profiles add -n "$name" -a /home/jellyfin/tizen-studio-data/keystore/author/tizencert.p12 -p "$password"
else


cat > /home/jellyfin/tizen-studio-data/profile/profiles.xml << EOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<profiles active="$name" version="3.1">
<profile name="$name">
<profileitem ca="" distributor="0" key="/home/jellyfin/tizen-studio-data/keystore/author/tizencert.p12" password="$password" rootca=""/>
<profileitem ca="/home/jellyfin/tizen-studio/tools/certificate-generator/certificates/distributor/tizen-distributor-ca.cer" distributor="1" key="/home/jellyfin/tizen-studio/tools/certificate-generator/certificates/distributor/tizen-distributor-signer.p12" password="tizenpkcs12passfordsigner" rootca=""/>
<profileitem ca="" distributor="2" key="" password="" rootca=""/>
</profile>
</profiles>
EOF

cd /jellyfin/jellyfin-tizen
tizen build-web -e ".*" -e gulpfile.js -e README.md -e "node_modules/*" -e "package*.json" -e "yarn.lock"
 tizen package -t wgt -o . -s "$name" -- .buildResult
