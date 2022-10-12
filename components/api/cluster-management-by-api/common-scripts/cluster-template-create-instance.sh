#!/bin/bash

SCRIPT_FOLDER=$(dirname $(realpath $0))
source ${SCRIPT_FOLDER}/_common.sh

### environment variables managed external - e.g. by source ${SCRIPT_FOLDER}/.kkp-env file
set -euo pipefail
#set +x

clustertemplate_name=$1
clustertemplate_count=${2:-1}
clustertemplate_payload="{\"replicas\": $clustertemplate_count}"

echo "Check cluster template exists: $clustertemplate_name"
project_response=$(getRequest "/projects/${KKP_PROJECT}/clustertemplates")
echo "RESPONSE:" && echo $project_response| jq
                                                  # jq -r ".[] | select( .name == \"aws-team-a\" ) | .id"
clustertemplate_id=$(echo $project_response | jq -r ".[] | select(.name == \"${clustertemplate_name}\") | .id")
if [[ -n "$clustertemplate_id" ]]; then
  echo "Create $clustertemplate_count cluster(s) from $clustertemplate_name"
  echo ${clustertemplate_payload}
  response=$(postRequestRaw "/projects/${KKP_PROJECT}/clustertemplates/${clustertemplate_id}/instances" "${clustertemplate_payload}")
  echo "RESPONSE:" && echo $response|  jq
#  cluster_id=$(echo $response | jq -r .id)
else
  echo "Didn't identify the cluster template '$clustertemplate_name'"
fi
exit
# TODO continue later, fetch cluster IDs
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