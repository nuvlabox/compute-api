#!/bin/sh

PASSPHRASE=$(openssl rand -base64 32)
HOSTNAME=${HOST:-`hostname`}
DOCKER_TLS=${DOCKER_TLS:-`pwd`}
SHARED="/srv/nuvlabox/shared"

export RANDFILE=$DOCKER_TLS/.rnd

mkdir -p $DOCKER_TLS
rm -fr $RANDFILE || echo "INFO: openssl .RND file doesn't exist yet"

openssl genrsa -aes256 -out ${DOCKER_TLS}/ca-key.pem -passout pass:$PASSPHRASE 4096
openssl req -new -x509 -days 365 -key ${DOCKER_TLS}/ca-key.pem -sha256 -out ${DOCKER_TLS}/ca.pem \
    -passin pass:$PASSPHRASE -subj "/C=CH/L=Geneva/O=SixSq/CN=$HOSTNAME"
openssl genrsa -out ${DOCKER_TLS}/server-key.pem 4096
openssl req -subj "/CN=$HOSTNAME" -sha256 -new -key ${DOCKER_TLS}/server-key.pem -out ${DOCKER_TLS}/server.csr

echo subjectAltName = DNS:$HOSTNAME,IP:10.10.10.20,IP:127.0.0.1 > ${DOCKER_TLS}/extfile.cnf
openssl x509 -req -days 365 -sha256 -in ${DOCKER_TLS}/server.csr -CA ${DOCKER_TLS}/ca.pem -CAkey ${DOCKER_TLS}/ca-key.pem \
    -CAcreateserial -out ${DOCKER_TLS}/server-cert.pem -extfile ${DOCKER_TLS}/extfile.cnf -passin pass:$PASSPHRASE

# Generate client credentials
openssl genrsa -out ${DOCKER_TLS}/key.pem 4096
openssl req -subj '/CN=client' -new -key ${DOCKER_TLS}/key.pem -out ${DOCKER_TLS}/client.csr

echo extendedKeyUsage = clientAuth > ${DOCKER_TLS}/extfile.cnf
openssl x509 -req -days 365 -sha256 -in ${DOCKER_TLS}/client.csr -CA ${DOCKER_TLS}/ca.pem -CAkey ${DOCKER_TLS}/ca-key.pem \
    -CAcreateserial -out ${DOCKER_TLS}/cert.pem -extfile ${DOCKER_TLS}/extfile.cnf -passin pass:$PASSPHRASE

# cleanup
rm -v ${DOCKER_TLS}/client.csr ${DOCKER_TLS}/server.csr
chmod -v 0400 ${DOCKER_TLS}/ca-key.pem ${DOCKER_TLS}/key.pem ${DOCKER_TLS}/server-key.pem
chmod -v 0444 ${DOCKER_TLS}/ca.pem ${DOCKER_TLS}/server-cert.pem ${DOCKER_TLS}/cert.pem

cp ${DOCKER_TLS}/ca.pem ${DOCKER_TLS}/key.pem ${DOCKER_TLS}/cert.pem $SHARED

socat OPENSSL-LISTEN:2375,reuseaddr,fork,cafile=ca.pem,key=server-key.pem,cert=server-cert.pem UNIX:/var/run/docker.sock