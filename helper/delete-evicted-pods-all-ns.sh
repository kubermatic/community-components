#!/usr/bin/env bash
set -x

kubectl get ns --no-headers | awk '{print $1}' > ns-list

while read -r ns; do
   kubectl get pods -o jsonpath='{.items[?(@.status.reason=="Evicted")].metadata.name}' -n $ns
done < ns-list
rm ns-list