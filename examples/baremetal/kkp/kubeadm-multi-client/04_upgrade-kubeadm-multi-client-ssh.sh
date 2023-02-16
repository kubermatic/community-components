#!/bin/bash
cd $(dirname $(realpath $0))
FOLDER=$(pwd)
user='root'
if [[ $# -lt 4 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename \"$0\") JUMPCONFIG OS_FLAVOR K8S_VERSION KUBECONFIG"
  echo "e.g $(basename \"$0\") 'username@172.14.16.1,root@jumphost.example.com' ubuntu 1.24.6 ~/user-cluster-kubeconfig"
  exit 1
fi
set -euo pipefail
jumpConfig="$1"
os_flavor="$2"
k8s_version="$3"
kconfig="$4"


### exclude #
grep -v '#' $FOLDER/upgradehosts.txt| while IFS="," read -r host nodename; do
  echo "$user@$host"
  echo "$nodename"
  scp -p $kconfig "$user@$host:/tmp/kubeconfig"
  ssh "$user@$host" -J $jumpConfig -t 'sudo bash -s' < $FOLDER/kubeadm/kubeadm-upgrade.sh $nodename \
    && ssh "$user@$host" -J $jumpConfig -t 'sudo bash -s' < $FOLDER/kubeadm/kubeadm-setup-${os_flavor}.sh $k8s_version \
    && echo "------------- Upgrade success! Please join the node back to the cluster"
done
