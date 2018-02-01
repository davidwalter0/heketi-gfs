#!/bin/bash

if [[ ! ${SSH_PORT:-} ]]; then

cat <<EOF

SSH_PORT was not set, setting to 2722, if you want to use another port
for the ssh service in the container then set it before running or
overwrite the sshd_config file with a volume

EOF
export SSH_PORT=2722
fi

applytmpl < Dockerfile.tmpl > Dockerfile
applytmpl < sshd_config.tmpl > sshd_config
if docker build --tag davidwalter/gluster-centos:latest .; then
   docker push davidwalter/gluster-centos:latest
fi
