#!/bin/bash

SCRIPT_FOLDER=$(dirname $(realpath $0))
source ${SCRIPT_FOLDER}/_common.sh

### environment variables managed external - e.g. by source ${SCRIPT_FOLDER}/.kkp-env file
set -euo pipefail
set +x

cluster_name=$(cat $KKP_CLUSTER_PAYLOAD | jq -r .cluster.name)
echo "Check cluster exists: $cluster_name"
project_response=$(getRequest "/projects/${KKP_PROJECT}/clusters")
echo "RESPONSE:" && echo $project_response| jq

cluster_id=$(echo $project_response | jq -r ".[] | select(.name == \"${cluster_name}\") | .id")

if [[ -z "$cluster_id" ]]; then
  echo "Create Cluster $cluster_name"
  cat ${KKP_CLUSTER_PAYLOAD}
  response=$(postRequest "/projects/${KKP_PROJECT}/clusters" "${KKP_CLUSTER_PAYLOAD}")
  echo "RESPONSE:" && echo $response|  jq
  cluster_id=$(echo $response | jq -r .id)
else
  echo "Patch Cluster $cluster_id:"
  cat ${KKP_CLUSTER_PAYLOAD} | jq .cluster
  response=$(cat ${KKP_CLUSTER_PAYLOAD} | jq .cluster | \
    patchRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}" "-")
fi


echo "-------------------------"
echo "Cluster ID: $cluster_id"


echo  "...wait for provisioning" && sleep 5
waitForClusterHealth ${cluster_id}
echo "Cluster healthy: $cluster_id"

echo "apply machinedeployments"
${SCRIPT_FOLDER}/md-apply.sh $cluster_id

echo "-------------------------"
echo "Download kubeconfig"
${SCRIPT_FOLDER}/kubeconfig-get.sh  $cluster_id

echo "-------------------------"
echo "Deploy Addons"
${SCRIPT_FOLDER}/addon-deploy.sh  $cluster_id
echo "-------------------------"