#!/bin/bash
cd $(dirname $(realpath $0))
FOLDER=$(pwd)
user='root'
if [[ $# != 1 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename \"$0\") 'username@172.14.16.1,root@root@jumphost.example.com'"
  exit 1
fi

set -euo pipefail
jumpConfig="$1"

### exclude '#' lines
grep -v '#' $FOLDER/hosts.exec.txt| while read -r host; do
  echo "$user@$host"
  ssh "$user@$host" -t 'sudo bash -s' < $FOLDER/exec.sh \
    && echo "------------- $host success!"
done
