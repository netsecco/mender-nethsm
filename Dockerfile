FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND="noninteractive"
ARG NETHSM_PKCS11_VERSION="nethsm-pkcs11-vv1.5.0-x86_64-debian.12.so"


RUN apt update \
 && apt upgrade --no-install-recommends -y \
 && apt install --no-install-recommends -y \
    bc bsdmainutils opensc iputils-ping libengine-pkcs11-openssl openssl \
    curl apt-transport-https ca-certificates gnupg-agent software-properties-common \
 && apt autoremove -y \
 && apt clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN update-ca-certificates \
 && curl -fsSL https://downloads.mender.io/repos/debian/gpg | tee /etc/apt/trusted.gpg.d/mender.asc \
 && echo "deb [arch=$(dpkg --print-architecture)] https://downloads.mender.io/repos/debian debian/bookworm/stable main" | tee /etc/apt/sources.list.d/mender.list > /dev/null \
 && apt update \
 && apt install --no-install-recommends -y mender-artifact \
 && apt autoremove -y \
 && apt clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install nethsm-pks11, download package from https://github.com/Nitrokey/nethsm-pkcs11/tags
RUN curl -L https://github.com/Nitrokey/nethsm-pkcs11/releases/download/v1.5.0/${NETHSM_PKCS11_VERSION} -o /usr/lib/x86_64-linux-gnu/pkcs11/${NETHSM_PKCS11_VERSION}

RUN --mount=type=bind,target=/host-bind/ \
 sed -e "s/__NETHSM_PKCS11_VERSION__/${NETHSM_PKCS11_VERSION}/" host-bind/install/etc/ssl/openssl.cnf.template >> /etc/ssl/openssl.cnf \
 && cp host-bind/install/mender_sign.sh /usr/local/bin/mender_sign.sh \
 && cp host-bind/install/test_keys.sh /usr/local/bin/test_keys.sh \
 && chmod +x /usr/local/bin/mender_sign.sh /usr/local/bin/test_keys.sh

CMD ["/bin/bash"]