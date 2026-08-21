##################################################################################################################################################
# This Bash script automates the operating system update process for Kubernetes control plane nodes while                                        #
# ensuring the etcd cluster remains healthy throughout the procedure. It performs the following steps:                                           #
#                                                                                                                                                #
# 1. Identify the etcd leader node                                                                                                               #
#   - Retrieves the IP address and node name of the current etcd leader using etcdctl and kubectl.                                               #
# 2. Prepare the update sequence                                                                                                                 #
#   - Collects all control plane nodes and reorders them so the etcd leader is updated last.                                                     #
# 3. Update each node                                                                                                                            #
#   - Drains the node to safely evict workloads.                                                                                                 #
#   - Connects via SSH to perform apt update, upgrade packages, remove unused packages, and reboot the node.                                     #
#   - Waits for the node to become Ready again and then uncordons it.                                                                            #
# 4. Verify etcd health after each update                                                                                                        #
#   - Checks the health of the etcd cluster using etcdctl endpoint health and retries if necessary.                                              #
# 5. Completion                                                                                                                                  #
#   - Confirms that all control plane nodes have been successfully updated.                                                                      #
#                                                                                                                                                #
# The script uses strict error handling (set -euo pipefail) and includes retry mechanisms to ensure cluster stability during the update process. #
##################################################################################################################################################

#!/bin/bash

set -euo pipefail

# function: determine etcd-Leader-Node
get_etcd_leader_node_name() {
  any_etcd_pod=$(kubectl -n kube-system get pods -l component=etcd -o jsonpath='{.items[0].metadata.name}')
  if [ -z "${any_etcd_pod}" ]; then
    echo "***********************"
    echo "* No etcd pods found! *"
    echo "***********************"
    echo ""
    return 1
  fi

  leader_ip=$(kubectl exec -n kube-system "${any_etcd_pod}" -- sh -c "ETCDCTL_API=3 etcdctl --cluster \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
    --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
    endpoint status --write-out=json" \
  | jq -r '.[]
      | select(.Status.header.member_id == .Status.leader)
      | .Endpoint
      | sub("https://"; "")
      | split(":")[0]')

  kubectl get nodes -o json \
    | jq -r --arg ip "$leader_ip" '
        .items[] 
        | select(.status.addresses[]? 
            | select(.type == "InternalIP" and .address == $ip)) 
        | .metadata.name'
}

# function: determine internal IP of node
get_internal_ip_for_node() {
  local node_name=$1
  kubectl get node "$node_name" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'
}

# function: check etcd-Health
verify_etcd_health() {
  local max_retries=10
  local retry=0
  local any_etcd_pod

  echo "*********************************"
  echo "* Verifying etcd cluster health *"
  echo "*********************************"
  echo ""

  any_etcd_pod=$(kubectl -n kube-system get pods -l component=etcd -o jsonpath='{.items[0].metadata.name}')
  if [ -z "${any_etcd_pod}" ]; then
    echo "***********************"
    echo "* No etcd pods found! *"
    echo "***********************"
    echo ""
    return 1
  fi

  while [ $retry -lt $max_retries ]; do
    if kubectl -n kube-system exec "${any_etcd_pod}" -- \
      etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt \
      --cert /etc/kubernetes/pki/etcd/server.crt \
      --key /etc/kubernetes/pki/etcd/server.key \
      endpoint health --cluster | grep -q "is healthy"; then

      echo "***************************"
      echo "* Etcd cluster is healthy *"
      echo "***************************"
      echo ""
      return 0
    fi
    
    echo "Waiting for etcd cluster to be healthy... (${retry}/${max_retries})"
    echo ""
    sleep 15
    ((retry++))
  done

  echo "************************************"
  echo "* Etcd cluster health check failed *"
  echo "************************************"
  echo ""
  return 1
}

# function: wait until node is ready again
wait_for_node_ready() {
  local node_name=$1
  local max_retries=20
  local retry=0

  echo "*********************************************"
  echo "* Waiting for node ${node_name} to be ready *"
  echo "*********************************************"
  echo ""

  while [ $retry -lt $max_retries ]; do
    if kubectl get nodes | grep "${node_name}" | grep -q "Ready"; then
      echo "******************************"
      echo "* Node ${node_name} is ready *"
      echo "******************************"
      echo ""
      return 0
    fi
    echo "Waiting for node ${node_name} to be ready... (${retry}/${max_retries})"
    sleep 5
    ((retry++))
  done

  echo "*****************************************************"
  echo "* Timeout waiting for node ${node_name} to be ready *"
  echo "*****************************************************"
  echo ""
  return 1
}

# function: update node
update_node() {
  local node=$1
  echo "*******************************"
  echo "* Updating Node: $node *"
  echo "*******************************"
  echo ""

  kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data

  node_ip=$(get_internal_ip_for_node "$node")
  ssh -i ../secrets/kone-key-ecdsa kone@"$node_ip" "sudo apt update && apt list --upgradable && sudo apt upgrade -y && sudo apt autoremove -y && sudo reboot" || true

  echo ""
  echo "************************************************************"
  echo "* Waiting 20 seconds so kubernetes is aware of node reboot *"
  echo "************************************************************"
  echo ""
  sleep 20

  wait_for_node_ready "$node"
  kubectl uncordon "$node"

  echo ""
  echo "**********************"
  echo "* Verify etcd health *"
  echo "**********************"
  echo ""

  if ! verify_etcd_health; then
    echo "*************************************************************"
    echo "* Error: etcd is not healthy after updating of $node *"
    echo "*************************************************************"
    echo ""
    exit 1
  fi
}

# main
main() {
  echo ""
  echo "*******************************************"
  echo "* Start OS update for control plane nodes *"
  echo "*******************************************"
  echo ""

  all_nodes=($(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[*].metadata.name}'))
  leader_node=$(get_etcd_leader_node_name)

  echo "********************************"
  echo "* etcd-Leader is: $leader_node *"
  echo "********************************"
  echo ""

  # move leader to the end of the list
  nodes=()
  for n in "${all_nodes[@]}"; do
    [[ "$n" != "$leader_node" ]] && nodes+=("$n")
  done
  nodes+=("$leader_node")

  for node in "${nodes[@]}"; do
    update_node "$node"
    # echo $node
  done

  echo "***********************************************************"
  echo "* All control plane nodes have been successfully updated. *"
  echo "***********************************************************"
  echo ""
}

main
