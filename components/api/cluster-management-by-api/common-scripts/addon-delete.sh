#!/bin/bash

SCRIPT_FOLDER=$(dirname $(realpath $0))
source ${SCRIPT_FOLDER}/_common.sh

### environment variables managed external - e.g. by source ${SCRIPT_FOLDER}/.kkp-env file
cluster_id=${1:-${CLUSTER_ID}}
echo $cluster_id
checkClusterIDSet $(basename $0) $cluster_id
set -euo pipefail
echo -e "cluster_id: $cluster_id"

addon_id=${3}
echo -e "addon_id: $addon_id"

curl -k -X DELETE \
  "${KKP_API}/projects/${KKP_PROJECT}/clusters/${cluster_id}/addons/${addon_id}" \
   -H  "accept: application/json" \
   -H  "authorization: Bearer ${KKP_TOKEN}" \
   && echo -e "\n DELETED cluster ${cluster_id} addon $addon_id!"

echo "...wait" && sleep 5
curl -k -X GET \
  "${KKP_API}/projects/${KKP_PROJECT}/clusters/${cluster_id}/addons" \
   -H  "accept: application/json" \
   -H  "Content-Type: application/json" \
   -H  "authorization: Bearer ${KKP_TOKEN}"\
   | jq



