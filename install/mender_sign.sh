#!/bin/bash
# sign a mender artifact with a key stored in the HSM
# usage: mender_sign <image>

die() {
    echo "$@"
    exit 1
}

check_command_available() {
    if ! which "$1" &> /dev/null; then
        die "ERROR: The command $1 is not available."
    fi

}

usage() {
    echo "Usage:"
    echo "  $0 <image>"
    echo "  Sign Mender artifact, where <image> is the image to be signed"
    exit 0
}

SIGNING_POOL="/work"
# variables are defined in defaults.env
SIGNING_KEY=$EC_SIGNING_KEY
HSM_SLOT=$PKCS11_TOKEN

export OPENSSL_CONF=/etc/ssl/openssl.cnf

# Parse command line
if [ $# -eq 1 ]; then
    FILE_TO_SIGN="${SIGNING_POOL}/$1"
else
    usage
fi

if [[ ! -f "$FILE_TO_SIGN" ]]; then
    echo "$FILE_TO_SIGN does not exist."
    exit 3
fi

# check if all needed commands are available
check_command_available pkcs11-tool
check_command_available openssl
check_command_available mender-artifact

logSuccess() {
    echo "successfully signed mender artifact $FILE_TO_SIGN with signing key $SIGNING_KEY" >> "${FILE_TO_SIGN}.log"
    echo "WARNING: Signing key is NOT from HSM" >> "${FILE_TO_SIGN}.log"
    }

logMenderVersion() {
    version=$(mender-artifact --version)
    echo "mender-artifact version=$version" > "${FILE_TO_SIGN}.log"
}

logMenderVersion

exportPublicKey() {
    openssl pkey -engine pkcs11 -pubout -out "${FILE_TO_SIGN}.pubkey.pem" -outform PEM -inform engine -in "pkcs11:token=$HSM_SLOT;object=$SIGNING_KEY;type=public"
}


echo -n "signing mender artifact with HSM key=$SIGNING_KEY ..."
if result=$(mender-artifact sign --force --key-pkcs11 "pkcs11:token=$HSM_SLOT;object=$SIGNING_KEY;type=private" "${FILE_TO_SIGN}" 2>&1); then
    stdout=$result
    echo "done"
else
    rc=$?
    stderr=$result
    echo "Error: signing failed with exit_code=$rc ($stderr)"
    exit 1
fi

echo -n "verify signature with HSM public key... "
if result=$(mender-artifact validate --key-pkcs11 "pkcs11:token=$HSM_SLOT;object=$SIGNING_KEY;type=private" "${FILE_TO_SIGN}" 2>&1); then
    stdout=$result
    echo "done"
else
    rc=$?
    stderr=$result
    echo "Error: signature validation with HSM public key failed with exit code=$rc ($stderr)"
    exit 2
fi

echo "exporting public key from HSM ... "

exportPublicKey

echo -n "verify signature with exported public key ... "
if result=$(mender-artifact validate --key "${FILE_TO_SIGN}.pubkey.pem" "${FILE_TO_SIGN}" 2>&1); then
    stdout=$result
    echo "done"
else
    rc=$?
    stderr=$result
    echo "Error: signature validation with exported public key failed with exit code=$rc ($stderr)"
    exit 3
fi

logSuccess
exit 0
