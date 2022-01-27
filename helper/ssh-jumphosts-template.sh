#!/bin/bash

user=$1
target_env=$2
# ensure kubeone tooling container is running
cmd=${3:-'docker exec -it tooling bash'}
if [[ $# -lt 2 ]] || [[ "$1" == "--help" ]]; then
  echo -e "please specify at least USER and ENVIRONMENT!

  usage: `basename $0` USER ENVIRONMENT [COMMAND]
  USER:        YADxxxx account at your __CUSTOMER__ environment
                       (could also be lowercase)

  ENVIRONMENT: cld      -  Azure Cloud
               vsp  -  vSphere

  COMMAND:     any command you want to execute on the bastion
               default: '$cmd'
                         to connect directly into the tooling container
  "
  exit 1
fi

CUSTOMER_PROXY=proxy.__CUSTOMER__.corp
proxy_flag="ProxyCommand nc -X connect -x ${CUSTOMER_PROXY} %h %p"

case $target_env in
  "cld") TARGET_HOST="jumphost.cloud.__CUSTOMER__.com" ;;
  "vsp") TARGET_HOST="jumphost.vsphere.__CUSTOMER__.com" ;;
   *) echo "no target defined!" && exit 1 ;;
esac

set -euo pipefail
echo "--> connect trough vsoc to __CUSTOMER__ jumphost $TARGET_HOST"
echo "ssh $user@$TARGET_HOST -o \"$proxy_flag\" -t $cmd"
ssh $user@$TARGET_HOST -o "$proxy_flag" -t $cmd
