#!/bin/bash

SCRIPT_FOLDER=$(dirname $(realpath $0))
source ${SCRIPT_FOLDER}/_common.sh

if [[ "$KKP_MACHINE_MANAGEMENT" == "md-yaml" ]]; then
  echo ">>> KKP_MACHINE_MANAGEMENT=$KKP_MACHINE_MANAGEMENT ---> manage MachineDeployment by yaml!"
  ${SCRIPT_FOLDER}/md-apply-yaml.sh $cluster_id
  exit $?
fi

### environment variables managed external - e.g. by source ${SCRIPT_FOLDER}/.kkp-env file
cluster_id=${1:-${CLUSTER_ID}}
echo $cluster_id
checkClusterIDSet $(basename $0) $cluster_id
set -euo pipefail
echo -e "cluster_id: $cluster_id"

echo "Update MachineDeployment of Cluster"

md_response=$(\
  cat ${KKP_CLUSTER_PAYLOAD} | jq .cluster |
  curl -k  -X GET \
  "${KKP_API}/projects/${KKP_PROJECT}/clusters/${cluster_id}/machinedeployments" \
   -H  "accept: application/json" \
   -H  "Content-Type: application/json" \
   -H  "authorization: Bearer ${KKP_TOKEN}" \
   )
echo "MachineDeployment RESPONSE:"
echo "$md_response" | jq

existing_md_ids=$(echo $md_response | jq -r .[].id)
echo "Existing MDs: $existing_md_ids"
### merge all definitions
machine_deployment_payload=$(cat <(cat ${KKP_CLUSTER_PAYLOAD} | jq '.nodeDeployment') <(cat ${KKP_CLUSTER_ADD_MACHINE_DEPLOYMENT}) | jq -s)
### filter out null values
machine_deployment_payload=$(echo $machine_deployment_payload | jq '.[] | select(. != null)' | jq -s)
#echo $machine_deployment_payload > temp.debug.json
#cat temp.debug.json | jq

spec_md_names=$(echo $machine_deployment_payload | jq -r ".[].name")
echo "Spec MDs: $spec_md_names"

echo -e "\n----- Actions -----"

echo "Duplicated -> PATCH"
patch_ids=$(echo -e "$existing_md_ids\n$spec_md_names" | sort | uniq -d)
echo $patch_ids

echo "Not existing MDs -> DELETE"
del_ids=$(echo -e "$existing_md_ids\n$patch_ids" | sort | uniq -u)
echo $del_ids

echo "Extra MDs -> POST"
post_ids=$(echo -e "$spec_md_names\n$patch_ids" | sort | uniq -u)
echo $post_ids

###### UPDATE machinedeployments
for md_id in $patch_ids; do
  echo -e "PATCH md_id: $md_id"
  patch_payload=$(echo ${machine_deployment_payload} | jq -r ".[] | select(.name == \"${md_id}\")")
  echo $patch_payload | jq
#  echo $patch_payload | jq > temp.md.payload.json
  response=$(\
    echo $patch_payload | \
      patchRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}/machinedeployments/${md_id}" "-"
     )
  echo "RESPONSE:"
  echo $response | jq
done
###### Delete not specified machinedeployments
for md_id in $del_ids; do
  echo -e "DELETE md_id: $md_id"
  response=$(deleteRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}/machinedeployments/${md_id}")
  echo "RESPONSE:"
  echo $response | jq
done
###### Create new specified machinedeployments
for md_id in $post_ids; do
  echo -e "POST md_id: $md_id"
  post_payload=$(echo ${machine_deployment_payload} | jq -r ".[] | select(.name == \"${md_id}\")")
  echo $post_payload | jq
  response=$(\
    echo $post_payload | \
      postRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}/machinedeployments" "-"
     )
  echo "RESPONSE:"
  echo $response | jq
done

echo -e "\n---- Result ------"
kubectl get md,ms,ma,node -A