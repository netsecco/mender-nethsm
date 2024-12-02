# Test Environment to test mender-artifact together with a virtual Nitrokey NetHSM

# Container Management
## create container image locally
```
docker compose build
```

## start and stop the service (using test environment)
```
docker compose up -d
docker compose down
```


## check log files of the container
```
docker compose logs
```

# HSM
The test environment contains a virtual NetHSM and a HSM manager containter.
## connect to HSM manager
To connect to the HSM manager containter use
```
docker exec -ti signing_mender_hsm_adm_test bash
```

## init HSM
There is a script to init the HSM. This will to the following steps
* initialize the HSM
* set admin user password
* create the namespaces Mender with an NS admin and a NS operator
* create an EC P384 and an RSA 2048 key

### execute the init script
```
/usr/local/bin/init-nethsm.sh
```

# Mender artifcat signing with HSM keys

## connect to signing container
To connect to the HSM manager containter use
```
docker exec -ti signing_mender_hsm bash
```

## exectue the key verification script
There is a script that verifies the correct funktion of the HSM. It executes the following steps:
* create a random file
* sign the random file with a HSM key
* verify the signature with the public key from the HMS
* extract the public key from the HSM
* verify the signature with the extracted public key

```
/usr/local/bin/test_keys.sh
```

## Signing Script
There is a script that execute the following steps with a mender artificat:
* re-sign the artifact with a HSM key
* verify the signature with the public key from the HMS
* extract the public key from the HSM
* verify the signature with the extracted public key

The signing container mounts /tmp of the docker host to /work. The signing script expects the mender artifact in /tmp of the docker host.

```
/usr/local/bin/mender_sign.sh <mender artifact>
```
<mender artifact> is the .mender file without a path
The script also creates a log file (<mender artifact>.log) and a public key file (<mender artifact>.pubkey.pem)
