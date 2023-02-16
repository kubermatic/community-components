#!/bin/bash
cd $(dirname $(realpath $0))
FOLDER=$(pwd)
user='root'
if [[ $# != 2 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename \"$0\") 'username@172.14.16.1,root@jumphost.example.com' 'kubeadm join ...'"
  exit 1
fi

set -euo pipefail
jumpConfig="$1"
k8s_join="$2"

### exclude '#' lines
grep -v '#' $FOLDER/hosts.txt| while read -r host; do
  echo "$user@$host"
  #ssh "$user@$host" -t 'sudo bash -s' <<EOF
  ssh "$user@$host" -J $jumpConfig -t 'sudo bash -s' <<EOF
$k8s_join
EOF
done
