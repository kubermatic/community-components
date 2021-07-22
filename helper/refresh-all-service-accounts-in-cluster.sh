#!/usr/bin/env bash
flag=${1:-"--no-delete"}

function check_continue() {
    read -p "$1 ([y]es or [N]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo "yes" && return 0;;
        *)     echo "no" && return 1;;
    esac
}

#kubectl get ns --no-headers | awk '{print $1}' > ns-list

secret_pattern='token-' ### spec service account token
if [ -z "$NAMESPACE" ]; then
  namespaces=`kubectl get ns --no-headers \
    | grep -iv 'kube-system' \
    | grep -iv 'metallb' \
    | awk '{print $1}'`
else
  namespaces=$NAMESPACE
fi
#namespaces=`kubectl get ns --no-headers | grep 'kube-system' | awk '{print $1}'`
set -euo pipefail

echo $namespaces
for ns in $namespaces; do
  set -euo pipefail
  kubectl config set-context --current --namespace=$ns

  sec_to_delete=$(kubectl -n $ns get pods -o json | jq -r '.items[].spec.volumes[]?.secret.secretName' | grep 'token-' | sort | uniq) || echo ""
  echo "-------- SECRETS from service accounts - pattern: $secret_pattern"
  echo $sec_to_delete
  echo "----------------------------------------------------------------"
  echo ""

  for sec in $sec_to_delete; do
    ### skip if delete is failing
    set +euo pipefail
    echo ">>>"
    kubectl get -n $ns secrets $sec -o wide || echo ""
    echo "kubectl delete -n $ns secrets $sec"
    if check_continue "delete SECRET: $sec"; then
      kubectl describe -n $ns secrets $sec
      if [[ "$flag" == "--delete" ]]; then
          kubectl delete -n $ns secrets $sec
      else echo "... skip '--delete' not set!"
      fi
    else
      echo "... skip, not confirmed"
    fi

    pods=$(kubectl -n $ns get pods -o json | jq -r '.items[].metadata.name') || echo "... pods"
    for pod in $pods; do
      echo ">>> check pod $pod"
      if kubectl -n $ns get pod $pod -o json | jq -r '.spec.volumes[]?.secret.secretName' | grep $sec; then
        kubectl -n $ns get pod $pod -o json | jq '.metadata.name, .spec.volumes'
        echo "kubectl delete pod $pod -n $ns"
        if check_continue "delete pod for restart: $pod"; then
          if [[ "$flag" == "--delete" ]]; then
            kubectl delete pod $pod -n $ns
          else echo "... skip '--delete' not set!"
          fi
        fi
      fi
      done

  done
done
#
#while read -r ns; do
#
#   evicted_pods=$(kubectl get pods -o jsonpath='{.items[?(@.status.reason=="Evicted")].metadata.name}' -n $ns)
#   for pod in $evicted_pods; do
#    echo "$pod"
#    if [[ "$flag" == "--delete" ]]; then
#      kubectl delete pod $pod -n $ns
#    fi
#   done
#   exit
#done < ns-list
#rm ns-list
