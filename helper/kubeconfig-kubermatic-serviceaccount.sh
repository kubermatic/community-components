#!/usr/bin/env bash

# This script can be used to transform a kubeconfig file with
# ephemeral credentials (e.g. for EKS clusters with aws-iam-authenticator
# or GKE clusters) into a kubeconfig with static credentials.
# For this is creates a service account in each cluster, adds
# a new user with the account's token and then updates the
# context to use the new user.

set -euo pipefail

if [ "$#" -lt 1 ] || [ "${1}" == "--help" ]; then
  echo "Usage: $(basename $0) <output-kubeconfig file>  [--master-seed]"
  echo "kubectl access needs to be already provided"
  echo -e "\n [--master-seed] ONLY for combined master/seed setup: use in cluster service 'https://kubernetes.default.svc.cluster.local:443'"
  exit 0
fi

if ! [ -x "$(command -v jq)" ]; then
  echo "Please install jq(1) to parse JSON."
  echo "See https://stedolan.github.io/jq"
  exit 1
fi

output_kubeconfig="$1"
output_kubeconfig_yaml="${output_kubeconfig}.secret.yaml"

#############
# script was taken from https://gist.github.com/xtavras/98c6a2625079a78054a907219c976e2b
SERVICE_ACCOUNT_NAME="kubermatic-seed-sa"
NAMESPACE="kubermatic"
TMP_FOLDER=$(mktemp -d -t kube-sa-XXXXXXXXXX)
KUBECFG_FILE_NAME="${TMP_FOLDER}/${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-kubeconfig"

# Colors
BLUE="\e[01;34m"
COLOROFF="\e[00m"

clean_up () {
    echo "> clean_up"
    rm -rf $TMP_FOLDER
}
trap clean_up EXIT

create_service_account() {
    echo -e "\\Check namespace ${NAMESPACE} exist."
    kubectl create ns ${NAMESPACE} || echo "... done"
    echo -e "\\nCreating a service account in ${NAMESPACE} namespace: ${SERVICE_ACCOUNT_NAME}"
    kubectl create sa "${SERVICE_ACCOUNT_NAME}" --namespace "${NAMESPACE}"
}
get_secret_name_from_service_account() {
    echo -e "\\nGetting secret of service account ${SERVICE_ACCOUNT_NAME} on ${NAMESPACE}"
    SECRET_NAME=$(kubectl get sa "${SERVICE_ACCOUNT_NAME}" --namespace="${NAMESPACE}" -o json | jq -r .secrets[].name)
    echo "Secret name: ${SECRET_NAME}"
}

extract_ca_crt_from_secret() {
    echo -e -n "\\nExtracting ca.crt from secret..."
    kubectl get secret --namespace "${NAMESPACE}" "${SECRET_NAME}" -o json | jq \
    -r '.data["ca.crt"]' | base64 --decode  > "${TMP_FOLDER}/ca.crt"
    printf "done"
}

get_user_token_from_secret() {
    echo -e -n "\\nGetting user token from secret..."
    USER_TOKEN=$(kubectl get secret --namespace "${NAMESPACE}" "${SECRET_NAME}" -o json | jq -r '.data["token"]' | base64 --decode)
    printf "done"
}

set_kube_config_values() {
    context=$(kubectl config current-context)
    echo -e "\\nSetting current context to: $context"

    CLUSTER_NAME=$(kubectl config get-contexts "$context" | awk '{print $3}' | tail -n 1)
    echo "Cluster name: ${CLUSTER_NAME}"

    if [ ! -v ENDPOINT ]; then
      ENDPOINT=$(kubectl config view \
    -o jsonpath="{.clusters[?(@.name == \"${CLUSTER_NAME}\")].cluster.server}")
    echo -e ${BLUE} "Endpoint: ${ENDPOINT} ${COLOROFF}"
    fi

    # Set up the config
    echo -e "\\nPreparing k8s-${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-conf"
    echo -n "Setting a cluster entry in kubeconfig..."
    kubectl config set-cluster "${CLUSTER_NAME}" \
    --kubeconfig="${KUBECFG_FILE_NAME}" \
    --server="${ENDPOINT}" \
    --certificate-authority="${TMP_FOLDER}/ca.crt" \
    --embed-certs=true

    echo -n "Setting token credentials entry in kubeconfig..."
    kubectl config set-credentials \
    "${SERVICE_ACCOUNT_NAME}" \
    --kubeconfig="${KUBECFG_FILE_NAME}" \
    --token="${USER_TOKEN}"

    echo -n "Setting a context entry in kubeconfig..."
    kubectl config set-context \
    "${SERVICE_ACCOUNT_NAME}" \
    --kubeconfig="${KUBECFG_FILE_NAME}" \
    --cluster="${CLUSTER_NAME}" \
    --user="${SERVICE_ACCOUNT_NAME}" \
    --namespace="${NAMESPACE}"

    echo -n "Setting the current-context in the kubeconfig file..."
    kubectl config use-context "${SERVICE_ACCOUNT_NAME}" \
    --kubeconfig="${KUBECFG_FILE_NAME}"
}

apply_rbac() {
    echo -e -n "\\nApplying RBAC permissions..."
    # give admin permissions
    clusterrole="${SERVICE_ACCOUNT_NAME}-cluster-admin"
    echo " > assigning cluster role $clusterrole ..."
    kubectl apply -f - > /dev/null <<YAML
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $clusterrole
subjects:
- kind: ServiceAccount
  name: ${SERVICE_ACCOUNT_NAME}
  namespace: ${NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
YAML
}
create_output_file(){
    echo "temp file to target: ${KUBECFG_FILE_NAME} -> ${output_kubeconfig}"
    cp ${KUBECFG_FILE_NAME} ${output_kubeconfig}
    chmod 600 ${output_kubeconfig}

    kubectl create secret generic seed-kubeconfig -n $NAMESPACE --from-file kubeconfig="${output_kubeconfig}" --dry-run=client -o yaml > ${output_kubeconfig_yaml}

    echo -e "\n\n............................................."
    echo "${output_kubeconfig}:"
    cat ${output_kubeconfig}
    echo -e "\n\n............................................."
    echo "${output_kubeconfig_yaml}:"
    cat ${output_kubeconfig_yaml}
}

create_local_endpoint_conf(){
  local output_kubeconfig="${output_kubeconfig}-local"
  local output_kubeconfig_yaml="${output_kubeconfig}.secret.yaml"
  local ENDPOINT="https://kubernetes.default.svc.cluster.local:443"
  set_kube_config_values
  create_output_file
}

echo "TMP_FOLDER: $TMP_FOLDER"
create_service_account
get_secret_name_from_service_account
extract_ca_crt_from_secret
get_user_token_from_secret
set_kube_config_values
create_output_file
apply_rbac

if [ "$#" -gt 1 ] && [[ "${2}" == "--master-seed" ]]; then
 create_local_endpoint_conf
fi

echo -e "\n... SUCCESS!"
