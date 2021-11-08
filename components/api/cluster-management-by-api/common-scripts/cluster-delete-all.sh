#!/bin/bash

SCRIPT_FOLDER=$(dirname $(realpath $0))
source ${SCRIPT_FOLDER}/_common.sh

### environment variables managed external - e.g. by source ${SCRIPT_FOLDER}/.kkp-env file
set -euo pipefail

ids=$(getRequest "/projects/${KKP_PROJECT}/clusters" | jq -r .[].id)
getRequest "/projects/${KKP_PROJECT}/clusters" | jq
echo -e "delete clusters: \n$ids"

check_continue "delete all clusters?"
for id in $ids; do
  ${SCRIPT_FOLDER}/cluster-delete.sh $id
done




