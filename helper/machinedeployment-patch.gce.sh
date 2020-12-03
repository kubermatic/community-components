#!/usr/bin/env bash
# execute:
NS=kube-system
if [ -z "$1" ]; then
    REPLICAS=3
else
    REPLICAS=$1
fi

kubectl -n $NS patch md $(kubectl -n $NS get md --no-headers | awk '{print $1}') --type merge --patch "$(cat <<EOF
spec:
  replicas: $REPLICAS
  strategy:
    rollingUpdate:
      maxSurge: 3
      maxUnavailable: 0
    type: RollingUpdate
  template:
    spec:
      providerSpec:
        value:
          cloudProviderSpec:
            machineType: n1-standard-4
            preemptible: true
EOF
)"
