#!/bin/bash
cd $(dirname $(realpath $0))
FOLDER=$(pwd)
user='root'
IP_LOGFILE="ip_addresses.log"

set -euo pipefail
kubectl get nodes --no-headers -o wide | awk '{print $7}' > $FOLDER/hosts.txt
cat $FOLDER/hosts.txt

### exclude '#' lines
function call_ip_addr() {
  grep -v '#' $FOLDER/hosts.txt| while read -r host; do
    echo "-----------------------------------"
    echo "$user@$host"
    echo "-----------------------------------"
    ssh "$user@$host" -oStrictHostKeyChecking=no -t 'bash -s' <<EOF
ip addr
EOF
    echo "-----------------------------------"
done
}
call_ip_addr | tee -a $IP_LOGFILE

