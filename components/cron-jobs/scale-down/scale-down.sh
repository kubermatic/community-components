#!/bin/bash

set -euo pipefail

# Requirements:
# - jq

function echodate() {
  echo "[$(date)]" "$@"
}

function check_deployments() {
  # Check if there are any deployment objects across all namespaces with one
  # of the following labels.
  local -r labels=(
    "app.kubernetes.io/name=substra-backend-server"
    "app.kubernetes.io/part-of=substra-backend"
  )

  # Separate checks are needed for each label because we want to check for OR
  # instead of AND. At the moment `-l # key1=value1,key2=value2` is an AND
  # check and there doesn't appear to be any way to do an OR check in the same
  # kubectl get command.
  for label in "${labels[@]}"; do
    local count
    count=$(kubectl get deployment --all-namespaces -l "${label}" -o json | jq '.items | length')
    total_deployments=$((total_deployments + count))
  done
}

function scale_down_machinedeployments() {
  # Get all machinedeployment objects in the kube-system namespace where the cluster-cleanup label is NOT set to false.
  md_names=$(kubectl get md -n kube-system -l "cluster-cleanup!=false" -o jsonpath="{.items[*].metadata.name}")

  # Create an array of machinedeployment names.
  IFS=" " read -r -a md_array <<<"${md_names}"

  # Scale down each machinedeployment object to 0 replicas.
  for md in "${md_array[@]}"; do
    echodate "Scaling down machinedeployment ${md}."
    kubectl -n kube-system scale md "${md}" --replicas=0
  done
}

function wait_for_workers_deleted() {
  local total_expected_replicas

  total_expected_replicas=0
  for replicas in $(kubectl get md -n kube-system -o json | jq -r '.items[].spec.replicas'); do
    total_expected_replicas=$((total_expected_replicas + replicas))
  done

  function _check_workers_count() {
    local current_worker_nodes
    current_worker_nodes=$(kubectl get nodes -l node-role.kubernetes.io/master!="" -o json | jq '.items | length')

    if [[ "${current_worker_nodes}" -eq "${total_expected_replicas}" ]]; then
      echodate "Worker nodes have been deleted."
    else
      echodate "Waiting for worker nodes to be deleted..."
      sleep 10
      _check_workers_count
    fi
  }

  _check_workers_count
}

function main() {
  set -x

  total_deployments=0
  check_deployments
  if [[ "${total_deployments}" -eq 0 ]]; then
    echodate "Starting to scale down worker nodes."
    scale_down_machinedeployments
    wait_for_workers_deleted
    echodate "Scale down operation of worker nodes completed."
  else
    echodate 'Some deployment objects with restricted labels were found. Skipping scale down operation of worker nodes.'
  fi

  set +x
}

main "$@"
