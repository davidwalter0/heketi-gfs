#!/bin/bash

DIR=$(dirname $(readlink -f ${0}))
pushd ${DIR}
. setup

# disable STORAGE_MOUNTS
export STORAGE_MOUNTS=""

mkdir -p appl
applytmpl < heketi.environment.tmpl > appl/heketi.environment
# applytmpl < topology.json.tmpl | json2yaml | yaml2json --compress > appl/topology.json
applytmpl < topology.json.tmpl > appl/topology.json
applytmpl < heketi.json.tmpl > appl/heketi.json
applytmpl < heketi-config-secret.yaml.tmpl > appl/heketi-config-secret.yaml
applytmpl < statefulset-glusterfs.yaml.tmpl > appl/statefulset-glusterfs.yaml
applytmpl < statefulset-heketi.yaml.tmpl    > appl/statefulset-heketi.yaml
applytmpl < statefulset-glusterfs-service.yaml.tmpl > appl/statefulset-glusterfs-service.yaml

<<EOF
    iptables -N HEKETI
    iptables -A HEKETI -p tcp -m state --state NEW -m tcp --dport 24007 -j ACCEPT
    iptables -A HEKETI -p tcp -m state --state NEW -m tcp --dport 24008 -j ACCEPT
    iptables -A HEKETI -p tcp -m state --state NEW -m tcp --dport 2222 -j ACCEPT
    iptables -A HEKETI -p tcp -m state --state NEW -m multiport --dports 49152:49251 -j ACCEPT
    iptables-save
EOF

exit

${GOPATH}/bin/kubectl ${kubeconfig} delete -f appl/heketi-config-secret.yaml
${GOPATH}/bin/kubectl ${kubeconfig} delete -f appl/statefulset-glusterfs.yaml
${GOPATH}/bin/kubectl ${kubeconfig} delete -f appl/statefulset-heketi.yaml

${GOPATH}/bin/kubectl ${kubeconfig} apply -f appl/heketi-config-secret.yaml
${GOPATH}/bin/kubectl ${kubeconfig} apply -f appl/statefulset-glusterfs.yaml
${GOPATH}/bin/kubectl ${kubeconfig} apply -f appl/statefulset-heketi.yaml

# heketi-cli topology load --json=topology.json

cat <<EOF 
heketi-cli topology load --json=topology.json
heketi-cli setup-openshift-heketi-storage && kubectl delete -f appl/heketi-storage.json && kubectl create -f appl/heketi-storage.json && heketi-cli volume list
EOF
