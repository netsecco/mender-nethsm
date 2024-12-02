FROM debian:bookworm-slim

RUN apt update -y && apt install -y pipx build-essential python3-all-dev libpcsclite-dev opensc libengine-pkcs11-openssl curl byacc flex iputils-ping
RUN pipx ensurepath && pipx install pynitrokey

COPY ./install/init-nethsm.sh /usr/local/bin
RUN chmod +x /usr/local/bin/init-nethsm.sh

CMD ["/bin/bash"]
