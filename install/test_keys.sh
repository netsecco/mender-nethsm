#!/bin/bash
# check hsm keys


echo "check HSM keys"
echo "HSM Slot is ${PKCS11_TOKEN}"
echo "Signing Key is ${EC_SIGNING_KEY}"

cd work
echo "create random data"
{ tr -d '\n' </dev/urandom | head -c 1m; printf '\n'; } > msg.txt

echo "create signature of random data with HSM key"
openssl dgst -engine pkcs11 -sign "pkcs11:token=$PKCS11_TOKEN;object=$EC_SIGNING_KEY;type=private" -keyform engine -sha256 msg.txt > msg.sig
echo "verify signature of random data with HSM key"
openssl dgst -engine pkcs11 -verify "pkcs11:token=$PKCS11_TOKEN;object=$EC_SIGNING_KEY;type=public" -keyform engine -sha256 -signature msg.sig < msg.txt
echo "export public key from HSM"
openssl pkey -engine pkcs11 -pubout -out ${EC_SIGNING_KEY}.pem -inform engine -in "pkcs11:token=$PKCS11_TOKEN;object=$EC_SIGNING_KEY;type=public"
echo "verify signature of random data with exported public key"
openssl dgst  -verify ${EC_SIGNING_KEY}.pem -sha256 -signature msg.sig < msg.txt
