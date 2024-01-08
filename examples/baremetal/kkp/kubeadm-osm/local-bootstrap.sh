#!/bin/bash
# fail on any error
set -e
# This script is used to provision a node as part of an existing KKP cluster.

# Provide the Kubeconfig for the cluster
export KUBECONFIG=${KUBECONFIG:-$(cat ./kubeconfig)}

kubectl apply -f ./manifests
until kubectl -n cloud-init-settings get secret manual-edge-kube-system-provisioning-config; do sleep 5; done

#check if yq is installed
if ! [ -x "$(command -v yq)" ]; then
  echo 'Error: yq is not installed.' >&2
  exit 1
fi

# check if node_ip and node_username are provided via env variables, if not prompt for them
if [ -z "$NODE_IP" ]; then
    read -p "Enter the IP of the node: " NODE_IP
fi
if [ -z "$NODE_USERNAME" ]; then
    read -p "Enter the username: " NODE_USERNAME
fi

# check if ssh access to NODE_IP is possible
if ! ssh $NODE_USERNAME@$NODE_IP exit; then
  echo "Error: ssh access to $NODE_USERNAME@$NODE_IP is not possible. Please check your ssh key and the username." >&2
  exit 1
fi

kubectl -n cloud-init-settings get secret manual-edge-kube-system-provisioning-config -o jsonpath='{.data.cloud-config}'| base64 -d | yq 'del(.hostname)' | yq 'del(.write_files[] | select(.path == "/etc/machine-name"))' > manual-edge-kube-system-provisioning-config.cfg
# send manual-edge-kube-system-bootstap-config.cfg to node
scp manual-edge-kube-system-provisioning-config.cfg $NODE_USERNAME@$NODE_IP:/tmp
# send all scripts to node
scp ./remote-provisioning.sh $NODE_USERNAME@$NODE_IP:/tmp
scp ./supervise.sh $NODE_USERNAME@$NODE_IP:/tmp

# run remote-provisioning.sh on node
ssh -t $NODE_USERNAME@$NODE_IP sudo /tmp/remote-provisioning.sh

# check for pending certificatesigningrequest
until kubectl get csr | grep kubernetes.io/kubelet-serving; do sleep 5; done
# then approve / sign it
kubectl get csr | grep kubernetes.io/kubelet-serving | awk '{ print $1}' | xargs -I {} kubectl certificate approve {}
