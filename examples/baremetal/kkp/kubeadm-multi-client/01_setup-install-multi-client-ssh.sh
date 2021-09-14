#!/bin/bash
cd $(dirname $(realpath $0))
FOLDER=$(pwd)
user='ubuntu'
if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename \"$0\") K8S_VERSION"
  echo "e.g $(basename \"$0\") 1.18.10"
  exit 1
fi
set -euo pipefail
k8s_version="$1"

### exclude #
grep -v '#' $FOLDER/hosts.txt| while read -r host; do
  echo "$user@$host"
  ssh "$user@$host" -t 'sudo bash -s' < $FOLDER/kubeadm/kubeadm-setup-ubuntu.sh $k8s_version \
    && echo "------------- $host success!"
done

