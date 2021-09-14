#!/bin/bash
cd $(dirname $(realpath $0))
FOLDER=$(pwd)
user='ubuntu'
if [[ $# != 1 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename \"$0\") 'kubeadm join ...'"
  exit 1
fi

set -euo pipefail
k8s_join="$1"
### exclude '#' lines
grep -v '#' $FOLDER/hosts.txt| while read -r host; do
  echo "$user@$host"
  ssh "$user@$host" -t 'sudo bash -s' <<EOF
$k8s_join
EOF
done
