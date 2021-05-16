#!/usr/bin/env bash
flag=${1:-"--no-delete"}
set -euo pipefail

kubectl get ns --no-headers | awk '{print $1}' > ns-list

while read -r ns; do
   evicted_pods=$(kubectl get pods -o jsonpath='{.items[?(@.status.reason=="Evicted")].metadata.name}' -n $ns)
   for pod in $evicted_pods; do
    echo "$pod"
    if [[ "$flag" == "--delete" ]]; then
      kubectl delete pod $pod -n $ns
    fi
   done
done < ns-list
rm ns-list