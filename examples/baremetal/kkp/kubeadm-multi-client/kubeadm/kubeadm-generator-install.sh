#!/bin/bash
#### install kubeadm on rocky
set -euo pipefail


#grep -i rocky /etc/os-release && echo "rocky detected!" || (echo "This script requires rocky!" && exit 1)
#if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]]; then
#  echo "Usage: $(basename \"$0\") K8S_VERSION"
#  echo "e.g $(basename \"$0\") 1.22.5"
#  exit 1
#fi

#### Install kubeadm and kubectl
K8S_VERSION="$1"
DOWNLOAD_DIR=/usr/local/bin
mkdir -p $DOWNLOAD_DIR

RELEASE=v$K8S_VERSION
ARCH="amd64"
cd $DOWNLOAD_DIR
curl -L --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubelet,kubectl}
chmod +x {kubeadm,kubectl}
ln -s /usr/local/bin/kubeadm /usr/bin/kubeadm
ln -s /usr/local/bin/kubectl /usr/bin/kubectl
