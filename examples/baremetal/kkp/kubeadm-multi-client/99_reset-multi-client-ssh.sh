#!/bin/bash
cd $(dirname $(realpath $0))
FOLDER=$(pwd)
user='root'
if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename \"$0\") JUMP_CONFIG"
  echo "e.g $(basename \"$0\") 'username@172.14.16.1,root@jumphost.example.com'"
  exit 1
fi
set -euo pipefail
jumpConfig="$1"

### exclude '#' lines
grep -v '#' $FOLDER/hosts.reset.txt| while read -r host; do
  echo "$user@$host"
#  ssh "$user@$host" -t 'sudo bash -s' < $FOLDER/kubeadm/kubeadm-reset.sh\
  ssh "$user@$host" -J $jumpConfig -t 'sudo bash -s' < $FOLDER/kubeadm/kubeadm-reset.sh \
    && echo "------------- $host success!"
done
