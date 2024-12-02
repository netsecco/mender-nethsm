#!/bin/bash

set -euxo pipefail
set +x

export PATH=$PATH:/root/.local/bin
export NETHSM_HOST="hsmtest:8443"
export ALLOW_ROOT=1
OPERATOR_PW=operatoroperator


nitropy nethsm --host ${NETHSM_HOST} --no-verify-tls provision \
  --unlock-passphrase unlockunlock --admin-passphrase adminadmin

hsm-admin() {
    nitropy nethsm --host $NETHSM_HOST --no-verify-tls --username admin --password adminadmin "$@"
}

NETHSM_NAMESPACE=Mender
hsm-admin add-user --role Administrator --user-id admin --real-name "Namespace ${NETHSM_NAMESPACE} Admin" \
  --passphrase nsadminnsadmin --namespace $NETHSM_NAMESPACE
hsm-admin add-namespace $NETHSM_NAMESPACE

hsm1() {
        nitropy nethsm --host $NETHSM_HOST --no-verify-tls --username $NETHSM_NAMESPACE~admin --password nsadminnsadmin "$@"
}

hsm1 add-user --role Operator --user-id operator --real-name Operator --passphrase $OPERATOR_PW --namespace $NETHSM_NAMESPACE
hsm1 generate-key --type EC_P384 --length 384 --mechanism ECDSA_Signature --key-id MenderSignEC384
hsm1 generate-key --type RSA --length 2048 --mechanism RSA_Signature_PKCS1 --key-id MenderSignRSA2048

echo "********************************************"
echo "keys in Namespace $NETHSM_NAMESPACE"
echo "********************************************"

hsm1 list-keys
