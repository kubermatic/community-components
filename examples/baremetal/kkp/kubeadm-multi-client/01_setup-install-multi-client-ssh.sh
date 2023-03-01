#!/bin/bash
cd $(dirname $(realpath $0))
FOLDER=$(pwd)
user='root'
if [[ $# -lt 3 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename \"$0\") JUMP_CONFIG OS_FLAVOR K8S_VERSION"
  echo "e.g $(basename \"$0\") 'username@172.14.16.1,root@jumphost.example.com' ubuntu 1.23.12"
  exit 1
fi
set -euo pipefail
jumpConfig="$1"
os_flavor="$2"
k8s_version="$3"



### exclude #
grep -v '#' $FOLDER/hosts.txt| while read -r host; do
  echo "$user@$host"
#  ssh "$user@$host" -t 'sudo bash -s' < $FOLDER/kubeadm/kubeadm-setup-${os_flavor}.sh $k8s_version \
  ssh "$user@$host" -J $jumpConfig -t 'sudo bash -s' < $FOLDER/kubeadm/kubeadm-setup-${os_flavor}.sh $k8s_version \
    && echo "------------- $host success!"
done

