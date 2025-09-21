#!/usr/bin/env bash
# Generate Tizen author certificate and security profile
set -euo pipefail

export TIZEN_STUDIO_HOME="${TIZEN_STUDIO_HOME:-/home/jellyfin/tizen-studio}"
export TIZEN_DATA_HOME="${TIZEN_DATA_HOME:-/home/jellyfin/tizen-studio-data}"
export PATH="$TIZEN_STUDIO_HOME/tools/ide/bin:$TIZEN_STUDIO_HOME/tools:$PATH"

name="${TIZEN_NAME:-}"
email="${TIZEN_EMAIL:-}"
company="${TIZEN_COMPANY:-}"
city="${TIZEN_CITY:-}"
state="${TIZEN_STATE:-}"
country="${TIZEN_COUNTRY:-SE}"
password="${TIZEN_PASSWORD:-}"

prompt_if_empty () {
  local var_name="$1" prompt="$2" default="${3:-}"
  local current="${!var_name:-}"
  if [[ -z "${current}" ]]; then
    read -r -p "$prompt${default:+ [$default]}: " current
    if [[ -z "$current" && -n "$default" ]]; then current="$default"; fi
    eval "$var_name=\"\$current\""
  fi
}

prompt_if_empty name    "Name"    "John Doe"
prompt_if_empty email   "E-mail"  "name@example.com"
prompt_if_empty company "Company" "Your Organisation"
prompt_if_empty city    "City"    "Stockholm"
prompt_if_empty state   "State"   "SE"
prompt_if_empty country "Country code (2 letters)" "SE"
if [[ -z "$password" ]]; then
  read -r -s -p "Password (author key): " password; echo
fi
: "${password:=1234}"

echo "Generating certificate..."
tizen certificate \
  -a TizenCert \
  -p "$password" \
  -c "$country" \
  -s "$state" \
  -ct "$city" \
  -o "$company" \
  -n "$name" \
  -e "$email" \
  -f tizencert

author_p12="$TIZEN_DATA_HOME/keystore/author/tizencert.p12"
if [[ ! -f "$author_p12" ]]; then
  echo "Author certificate not found at $author_p12" >&2
  exit 1
fi
echo "Certificate saved: $author_p12"

echo "Creating security profile..."
# Distributor certs shipped with the Studio; default distributor password per Tizen docs.
dist_ca="$TIZEN_STUDIO_HOME/tools/certificate-generator/certificates/distributor/tizen-distributor-ca.cer"
dist_p12="$TIZEN_STUDIO_HOME/tools/certificate-generator/certificates/distributor/tizen-distributor-signer.p12"
dist_pass="tizenpkcs12passfordsigner"

mkdir -p "$TIZEN_DATA_HOME/profile"
profile_xml="$TIZEN_DATA_HOME/profile/profiles.xml"

cat > "$profile_xml" <<EOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<profiles active="$name" version="3.1">
  <profile name="$name">
    <profileitem distributor="0" key="$author_p12" password="$password" rootca="" ca=""/>
    <profileitem distributor="1" key="$dist_p12" password="$dist_pass" rootca="" ca="$dist_ca"/>
  </profile>
</profiles>
EOF

tizen security-profiles add -n "$name" -a "$author_p12" -p "$password" || true
echo "Security profile '$name' is ready."
