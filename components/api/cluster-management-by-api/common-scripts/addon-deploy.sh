#!/bin/bash

SCRIPT_FOLDER=$(dirname $(realpath $0))
source ${SCRIPT_FOLDER}/_common.sh

### environment variables managed external - e.g. by source ${SCRIPT_FOLDER}/.kkp-env file
cluster_id=${1:-${CLUSTER_ID}}
echo $cluster_id
checkClusterIDSet $(basename $0) $cluster_id
set -euo pipefail
echo -e "cluster_id: $cluster_id"

echo "Checking pre-installed addons, if any"
addon_response=$(curl -k -X GET \
  "${KKP_API}/projects/${KKP_PROJECT}/clusters/${cluster_id}/addons" \
    -H  "accept: application/json" \
    -H  "Content-Type: application/json" \
    -H  "authorization: Bearer ${KKP_TOKEN}")
echo "Existing addons: "
echo "$addon_response" | jq

existing_addon_ids=$(echo $addon_response | jq -r .[].id)
echo "Existing Addons: $existing_addon_ids"

if [[ $(ls ${KKP_CLUSTER_ADDON}) ]];
  then addons_to_deploy_payload=$(cat ${KKP_CLUSTER_ADDON} | jq -s)   #combine json
  else addons_to_deploy_payload="{}"
fi
addons_to_deploy_names=$(echo "$addons_to_deploy_payload" | jq -r ".[].name")
echo "To Deploy Addons: $addons_to_deploy_names"

echo "Duplicated addons -> PATCH"
patch_ids=$(echo -e "$existing_addon_ids\n$addons_to_deploy_names" | sort | uniq -d)
echo $patch_ids

echo "Not existing addons -> DELETE"
del_ids=$(echo -e "$existing_addon_ids\n$patch_ids" | sort | uniq -u)
echo $del_ids

echo "New Extra addons -> POST"
post_ids=$(echo -e "$addons_to_deploy_names\n$patch_ids" | sort | uniq -u)
echo $post_ids

### Patch existing addons
for addon_id in $patch_ids; do
  echo -e "PATCH addon_id: $addon_id"
  patch_payload=$(echo "${addons_to_deploy_payload}" | jq -r ".[] | select(.name == \"${addon_id}\")")
  echo "$patch_payload" | jq
  response=$(\
    echo "$patch_payload" | \
      patchRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}/addons/${addon_id}" "-" \
     )
  echo "RESPONSE:"
  echo "$response" | jq
done
### Delete addons not found in spec
for addon_id in $del_ids; do
  echo -e "DELETE addon_id: $addon_id"
  response=$(deleteRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}/addons/${addon_id}")
  echo "RESPONSE:"
  echo "$response" | jq
done

### Create new addons found in spec
for addon_id in $post_ids; do
  echo -e "POST addon_id: $addon_id"
  post_payload=$(echo "${addons_to_deploy_payload}" | jq -r ".[] | select(.name == \"${addon_id}\")")
  echo "$post_payload" | jq
  response=$(\
    echo "$post_payload" | \
      postRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}/addons" "-"
     )
  echo "RESPONSE:"
  echo "$response" | jq
done
