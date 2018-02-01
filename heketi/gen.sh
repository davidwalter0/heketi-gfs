#!/bin/bash

HEKETI_VERSION=v5.0.1

if [[ ! ${SSH_PORT:-} ]]; then

cat <<EOF

Assuming heketi version ${HEKETI_VERSION} for download

SSH_PORT was not set, setting to 2722, if you want to use another port
for the ssh service in the container then set it before running or
overwrite the sshd_config file with a volume

EOF
export SSH_PORT=2722
fi

if [[ ! -e heketi-${HEKETI_VERSION}.linux.amd64.tar.gz || ! -d heketi || ! -x heketi/heketi || ! -x heketi/heketi-cli ]]; then
    wget --continue https://github.com/heketi/heketi/releases/download/${HEKETI_VERSION}/heketi-${HEKETI_VERSION}.linux.amd64.tar.gz
    tar xzvf heketi-${HEKETI_VERSION}.linux.amd64.tar.gz
fi

if applytmpl < Dockerfile.tmpl > Dockerfile ; then
    docker build --tag davidwalter/heketi-centos:latest .
    docker push davidwalter/heketi-centos:latest
else
    echo "failed: applytmpl < Dockerfile.tmpl > Dockerfile"
    exit 1
fi

rm -f heketi-${HEKETI_VERSION}.linux.amd64.tar.gz
