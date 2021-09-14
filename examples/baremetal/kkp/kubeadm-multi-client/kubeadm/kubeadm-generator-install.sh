#!/bin/bash
#### install kubeadm on ubuntu
set -euo pipefail


grep -i ubuntu /etc/os-release && echo "ubuntu detected!" || (echo "This script requires ubuntu!" && exit 1)
if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename \"$0\") K8S_VERSION"
  echo "e.g $(basename \"$0\") 1.18.10"
  exit 1
fi

#### based on kubeadm doc / container-runtime
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/
echo "---------- Install general packages"
UBUNTU_LSB_RELEASE=${UBUNTU_LSB_RELEASE:-"focal"}
sudo apt-get update && sudo apt-get install -y \
  apt-transport-https ca-certificates curl software-properties-common gnupg2 \
  && sudo apt-get clean


#### Install kubeadm
K8S_VERSION="$1"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

echo "---------- Install packages for Kubernetes $K8S_VERSION"
apt-get update && apt-get install -y \
  kubeadm=${K8S_VERSION}-00 \
  kubectl=${K8S_VERSION}-00 \
  && sudo apt-get clean
