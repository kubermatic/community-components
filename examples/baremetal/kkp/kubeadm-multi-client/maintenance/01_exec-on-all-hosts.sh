#!/bin/bash
cd $(dirname $(realpath $0))
FOLDER=$(pwd)
user='northern'
set -xeuo pipefail

### exclude #
grep -v '#' $FOLDER/../hosts.txt| while read -r host; do
  echo "$user@$host"
  ssh "$user@$host" -t 'sudo bash -s' < $FOLDER/exec.sh \
    && echo "------------- $host success!"
done
