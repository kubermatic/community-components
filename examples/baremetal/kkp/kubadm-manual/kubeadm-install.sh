#!/bin/bash
#### install kubeadm on ubuntu
set -euo pipefail

grep -i ubuntu /etc/os-release && echo "ubuntu detected!" || (echo "This script requires ubuntu!" && exit 1)
if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename \"$0\") K8S_VERSION"
  echo "e.g $(basename \"$0\") 1.17.9"
  exit 1
fi
K8S_VERSION="$1"

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

echo "---------- Install packages for Kubernetes $K8S_VERSION"
apt-get update && apt-get install -y \
  docker.io \
  kubelet=${K8S_VERSION}-00 \
  kubeadm=${K8S_VERSION}-00 \
  kubectl=${K8S_VERSION}-00

