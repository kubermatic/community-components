#!/bin/bash

SCRIPT_FOLDER=$(dirname $(realpath $0))
source ${SCRIPT_FOLDER}/_common.sh

### environment variables managed external - e.g. by source ${SCRIPT_FOLDER}/.kkp-env file
cluster_id=${1:-${CLUSTER_ID}}
echo $cluster_id
checkClusterIDSet $(basename $0) $cluster_id
set -euo pipefail
echo -e "cluster_id: $cluster_id"

######### Download kubeconfig
export KUBECONFIG="${cluster_id}-kubeconfig"
curl -k -X GET \
  "${KKP_API}/projects/${KKP_PROJECT}/clusters/${cluster_id}/kubeconfig" \
   -H  "accept: application/json" \
   -H  "Content-Type: application/json" \
   -H  "authorization: Bearer ${KKP_TOKEN}" > $KUBECONFIG

echo -e "\n .... check cluster objects\n"
kubectl get pod,md,ms,ma,node -A
