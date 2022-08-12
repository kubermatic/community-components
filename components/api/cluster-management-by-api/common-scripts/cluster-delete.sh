#!/bin/bash

SCRIPT_FOLDER=$(dirname $(realpath $0))
source ${SCRIPT_FOLDER}/_common.sh

### environment variables managed external - e.g. by source ${SCRIPT_FOLDER}/.kkp-env file
cluster_id=${1:-${CLUSTER_ID}}
confirm=${2:-true}
echo $cluster_id
checkClusterIDSet $(basename $0) $cluster_id
set -euo pipefail
echo -e "cluster_id: $cluster_id"

getRequest "${KKP_API}/projects/${KKP_PROJECT}/clusters/${cluster_id}" | jq
if [[ "$confirm" != "false" ]]; then
  check_continue "delete cluster $cluster_id?"
fi

curl -k -X DELETE \
  "${KKP_API}/projects/${KKP_PROJECT}/clusters/${cluster_id}" \
   -H  "accept: application/json" \
   -H  "DeleteVolumes: true" \
   -H  "DeleteLoadBalancers: true" \
   -H  "authorization: Bearer ${KKP_TOKEN}" \
   && echo -e "\n DELETED cluster ${cluster_id}!"

echo "...wait" && sleep 5
getRequest "/projects/${KKP_PROJECT}/clusters" | jq



