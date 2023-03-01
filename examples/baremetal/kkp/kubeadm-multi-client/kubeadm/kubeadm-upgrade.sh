#!/bin/bash
set -xeuo pipefail

if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename \"$0\") NODENAME OS_FLAVOR K8S_VERSION"
  echo "e.g $(basename \"$0\") worker-node-01 ubuntu 1.24.6"
  exit 1
fi

nodename="$1"

# Drain the node
echo "Drain the worker node"
kubectl drain $nodename --ignore-daemonsets --delete-emptydir-data --kubeconfig /tmp/kubeconfig

# Remove the node
echo "Remove the worker node"
kubectl delete node $nodename --kubeconfig /tmp/kubeconfig

# Stop the kubelet service and cleanup
systemctl stop kubelet
rm -rf /etc/kube*
rm -f /var/lib/kubelet/config.yaml
ipvsadm --clear

# Verify the node 
kubectl get node --kubeconfig /tmp/kubeconfig
