#!/bin/bash
cd $(dirname $(realpath $0))
FOLDER=$(pwd)

if [[ $# -lt 3 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename \"$0\") K8S_VERSION OS_FLAVOR PATH_TO_KUBECONFIG"
  echo "e.g $(basename \"$0\") 1.23.12 ubuntu ~/Downloads/kubeconfig-admin-xxxxx"
  exit 1
fi
set -euo pipefail
set -x
k8s_version="$1"
os_flavor="$2"
kconfig=$(realpath "$3")

cd $FOLDER/kubeadm
docker build -t local/kubeadm --build-arg K8S_VERSION=$k8s_version -f Dockerfile-${os_flavor} .
docker run -it -v "$kconfig":/kubeconfig local/kubeadm  kubeadm token --kubeconfig kubeconfig create --print-join-command
cd -

echo ".... copy-paste now the toke to 'kubeadm join' command"
