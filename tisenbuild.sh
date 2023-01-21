
#!/bin/bash
#
#  Tizen Jellyfin build v0.1
#  erik@skogh.dev  ----  2022-01-15
#

echo "Building..."
cd /jellyfin/jellyfin-tizen
tizen build-web -e ".*" -e gulpfile.js -e README.md -e "node_modules/*" -e "package*.json" -e "yarn.lock"
[ ! $? -eq 0 ] && echo "Error building." && exit $? 

if [ -z "$password" ]; then
	read -p "Please enter password for certificate: " password
fi
echo "Packaging..."
tizen package -t wgt -o . -s $name -- .buildResult <<<$password
[ ! $? -eq 0 ] && echo "Error create package." && exit $? 

