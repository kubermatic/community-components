#!/bin/bash

SCRIPT_FOLDER=$(dirname $(realpath $0))
source ${SCRIPT_FOLDER}/_common.sh
# set -x

# ### environment variables managed external - e.g. by source ${SCRIPT_FOLDER}/.kkp-env file
cluster_id=${1:-${CLUSTER_ID}}
echo $cluster_id
checkClusterIDSet $(basename $0) $cluster_id
set -euo pipefail
echo -e "cluster_id: $cluster_id"

echo "Checking pre-installed Alertmanager-rules, if any"
alertmanager_rules=$(curl -k -X GET \
  "${KKP_API}/projects/${KKP_PROJECT}/clusters/${cluster_id}/rulegroups" \
    -H  "accept: application/json" \
    -H  "Content-Type: application/json" \
    -H  "authorization: Bearer ${KKP_TOKEN}")
#echo "Existing Alertmanager Rules: "
#echo "$alertmanager_rules" | jq


existing_rule_names=`echo $alertmanager_rules | jq -r '.[].data' | while IFS= read -r item; do echo $item | base64 -d | yq eval '.name' - ; done;`
echo "Existing AlertManager Rule names: $existing_rule_names"

if [[ $(ls ${KKP_CLUSTER_ALERTMANAGER_RULES}) ]];
  # Logic: finds all files which are alertrules-*.yaml, base64 encodes them, places them in template json needed for kkp and combines all such jsons in a single array.
  then rules_to_deploy_payload=$(find . -name "$KKP_CLUSTER_ALERTMANAGER_RULES" | xargs -I {} sh -c 'base64 -w0 {};echo' | xargs -I {} sed 's/XXXX/{}/g' ./template-alertrules.json | jq -s)   #combine json
  else rules_to_deploy_payload="{}"
fi
rules_to_deploy_names=$(echo "$rules_to_deploy_payload" | jq -r '.[].data' | while IFS= read -r item; do echo $item | base64 -d | yq eval '.name' - ; done;)
echo "To Deploy Rules: $rules_to_deploy_names"

echo "Duplicated Rules -> PATCH"
patch_ids=$(echo -e "$existing_rule_names\n$rules_to_deploy_names" | sort | uniq -d)
echo $patch_ids

echo "Not existing Rules -> DELETE"
del_ids=$(echo -e "$existing_rule_names\n$patch_ids" | sort | uniq -u)
echo $del_ids

echo "New Extra Rules -> POST"
post_ids=$(echo -e "$rules_to_deploy_names\n$patch_ids" | sort | uniq -u)
echo $post_ids

### Update existing Rules
# different behavior since the json does not contain id directly.
len=$(echo $rules_to_deploy_payload | jq '. | length')
# echo rules to deploy $len
for ((i=0; i< $len; i++))
do
  # echo current iteration $i
  patch_payload=$(echo "${rules_to_deploy_payload}" | jq -r ".[$i]")
  patch_payload_id=$(echo "${rules_to_deploy_payload}" | jq -r ".[$i].data" | base64 -d | yq eval '.name' - )
  for rule_id in $patch_ids; do
    # echo $rule_id " ------ " $patch_payload_id
    if [ $rule_id = $patch_payload_id ]; then
      echo -e "Update rule_id: $rule_id"
      response=$(\
        echo "$patch_payload" | \
          putRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}/rulegroups/${rule_id}" "-" \
        )
      echo "RESPONSE:"
      echo "$response" | jq
    fi
  done
done

## Delete Rules not found in spec
for rule_id in $del_ids; do
  echo -e "DELETE rule_id: $rule_id"
  response=$(deleteRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}/rulegroups/${rule_id}")
  echo "RESPONSE:"
  echo "$response" | jq
done

### Create new rules found in spec
# different behavior since the json does not contain id directly.
len=$(echo $rules_to_deploy_payload | jq '. | length')
# echo rules to deploy $len
for ((i=0; i< $len; i++))
do
  # echo current iteration $i
  # echo $rules_to_deploy_payload | jq -r ".[$i]"
  post_payload=$(echo "${rules_to_deploy_payload}" | jq -r ".[$i]")
  post_payload_id=$(echo "${rules_to_deploy_payload}" | jq -r ".[$i].data" | base64 -d | yq eval '.name' - )
  for rule_id in $post_ids; do
    # echo $rule_id " ------ " $post_payload_id
    if [ $rule_id = $post_payload_id ]; then
      echo -e "POST rule_id: $rule_id"
      response=$(\
        echo "$post_payload" | \
          postRequest "/projects/${KKP_PROJECT}/clusters/${cluster_id}/rulegroups" "-"
        )
      echo "RESPONSE:"
      echo "$response" | jq
    fi
  done
done
