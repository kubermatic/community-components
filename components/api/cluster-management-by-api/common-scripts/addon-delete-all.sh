#!/bin/bash

SCRIPT_FOLDER=$(dirname $(realpath $0))
source ${SCRIPT_FOLDER}/_common.sh

### environment variables managed external - e.g. by source ${SCRIPT_FOLDER}/.kkp-env file
set -euo pipefail

if [ "$#" -lt 2 ] || [ "${1}" == "--help" ]; then
  echo "Usage: $(basename $0) <KKP_TOKEN file> <cluster_id>"
  exit 0
fi
export KKP_TOKEN=$(cat "$1")
cluster_id=${2}
echo -e "cluster_id: $cluster_id"

ids=$(curl -k -X GET \
  "${KKP_API}/projects/${KKP_PROJECT}/clusters/${cluster_id}/addons" \
   -H  "accept: application/json" \
   -H  "Content-Type: application/json" \
   -H  "authorization: Bearer ${KKP_TOKEN}" \
   | jq -r .[].id)
echo -e "delete cluster $cluster_id addons: \n$ids"
for id in $ids; do
  ${SCRIPT_FOLDER}/addon-delete.sh $1 $cluster_id $id
done




