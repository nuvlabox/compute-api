#!/bin/sh

# The HOSTNAME and HOST_ADDRESSES **MUST** be set externally when
# running within a container.  The default values from hostname from
# within the container will be **INCORRECT**.

HOSTNAME=${HOST:-`hostname`}
HOST_ADDRESSES=${HOST_ADDRESSES:-`hostname -i`}

LOCAL_ADDRESSES="127.0.0.1 0000:0000:0000:0000:0000:0000:0000:0001"
HOST_ADDRESSES="${HOST_ADDRESSES} 127.0.0.1 0000:0000:0000:0000:0000:0000:0000:0001"

SUBJECT_ALT_NAMES="DNS:${HOSTNAME}"
for addr in $HOST_ADDRESSES; do
    expended_addr=`ipv6calc -q --printfulluncompressed ${addr}`
    $SUBJECT_ALT_NAMES="$SUBJECT_ALT_NAMES,IP:${expanded_addr}"
done

PASSPHRASE=$(openssl rand -base64 32)
DOCKER_TLS=${DOCKER_TLS:-`pwd`}
SHARED="/srv/nuvlabox/shared"

export RANDFILE=$DOCKER_TLS/.rnd

mkdir -p $DOCKER_TLS
rm -fr $RANDFILE || echo "INFO: openssl .RND file doesn't exist yet"

if [[ ! -f $SHARED/key.pem ]]
then
    openssl genrsa -aes256 -out ${DOCKER_TLS}/ca-key.pem -passout pass:$PASSPHRASE 4096
    openssl req -new -x509 -days 365 -key ${DOCKER_TLS}/ca-key.pem -sha256 -out ${DOCKER_TLS}/ca.pem \
        -passin pass:$PASSPHRASE -subj "/C=CH/L=Geneva/O=SixSq/CN=$HOSTNAME"
    openssl genrsa -out ${DOCKER_TLS}/server-key.pem 4096
    openssl req -subj "/CN=$HOSTNAME" -sha256 -new -key ${DOCKER_TLS}/server-key.pem -out ${DOCKER_TLS}/server.csr

    echo subjectAltName = ${SUBJECT_ALT_NAMES} > ${DOCKER_TLS}/extfile.cnf
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

    cp ${DOCKER_TLS}/ca.pem ${DOCKER_TLS}/key.pem ${DOCKER_TLS}/cert.pem ${SHARED}
    mkdir -p ${SHARED}/server_tls || echo "server_tls folder already exists"
    cp ${DOCKER_TLS}/ca-key.pem ${DOCKER_TLS}/server-key.pem ${DOCKER_TLS}/server-cert.pem ${SHARED}/server_tls
else
    cp ${SHARED}/ca.pem ${SHARED}/key.pem ${SHARED}/cert.pem ${SHARED}/server_tls/*pem ${DOCKER_TLS}
fi

socat OPENSSL-LISTEN:5000,reuseaddr,fork,cafile=${DOCKER_TLS}/ca.pem,key=${DOCKER_TLS}/server-key.pem,cert=${DOCKER_TLS}/server-cert.pem UNIX:/var/run/docker.sock
