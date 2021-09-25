#!/usr/bin/env bash

declare -A services=(
  [grafana]=3000
  [prometheus]=9090
  [alertmanager]=9093
#  [alerta]=8080
  [minio]=9000
)
declare -A services_ns=(
  [grafana]=monitoring
  [prometheus]=monitoring
  [alertmanager]=monitoring
#  [alerta]=alerta
  [minio]=monitoring
)

for key in "${!services[@]}"; do
  svc=$key
  port="${services[$key]}"
  ns="${services_ns[$key]}"
  kubectl port-forward -n $ns svc/$svc $port:$port &
  sleep 1
  echo "----> $svc: http://localhost:$port"
done
echo -e "\n\n ... press CTRL + C to stop the port-forwarding"
wait