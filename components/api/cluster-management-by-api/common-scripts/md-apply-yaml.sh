#!/bin/bash

SCRIPT_FOLDER=$(dirname $(realpath $0))
source ${SCRIPT_FOLDER}/_common.sh

### environment variables managed external - e.g. by source ${SCRIPT_FOLDER}/.kkp-env file
cluster_id=${1:-${CLUSTER_ID}}
echo $cluster_id
checkClusterIDSet $(basename $0) $cluster_id
set -euo pipefail
echo -e "cluster_id: $cluster_id"
MD_FILE_FILTER=${MD_FILE_FILTER:-"md*.yaml"}
echo "Update MachineDeployment of Cluster by Kubernetes User Cluster API Endpoint and MachineDeployment object"
${SCRIPT_FOLDER}/kubeconfig-get.sh  $cluster_id
export KUBECONFIG="${cluster_id}-kubeconfig"
kubectl cluster-info

kubectl -n kube-system get machinedeployment -o jsonpath='{.items[*].metadata.name}' | sort -u

md_response=$(kubectl -n kube-system get machinedeployment -o yaml)
echo "MachineDeployment RESPONSE: $md_response"

existing_md_ids=$(kubectl -n kube-system get machinedeployment -o jsonpath='{.items[*].metadata.name}' | tr -s ' ' '\n' | sort -u)
echo "Existing MDs: $existing_md_ids"

spec_md_names=$(sed -e '$s/$/\n---/' -s $MD_FILE_FILTER| yq e 'del(.metadata.name | select(length!=0)' -N - )
echo "Spec MDs: $spec_md_names"

echo -e "\n----- Actions -----"

echo "Duplicated -> APPLY"
patch_ids=$(echo -e "$existing_md_ids\n$spec_md_names" | sort | uniq -d)
echo $patch_ids
echo "Extra MDs -> APPLY"
post_ids=$(echo -e "$spec_md_names\n$patch_ids" | sort | uniq -u)
echo $post_ids

echo "Not existing MDs -> DELETE"
del_ids=$(echo -e "$existing_md_ids\n$patch_ids" | sort | uniq -u)
echo $del_ids

sed -e '$s/$/\n---/' -s $MD_FILE_FILTER | kubectl -n kube-system apply -f -
###### Delete not specified machinedeployments
for md_id in $del_ids; do
  echo -e "DELETE md_id: $md_id"
  kubectl -n kube-system delete md $md_id
done

echo -e "\n---- Result ------"
kubectl get md,ms,ma,node -A