#!/usr/bin/env bash
# Kubermatic Deployment script based on helm3
set -euo pipefail

BASEDIR=$(dirname "$0")
source $BASEDIR/../../hack/lib.sh

if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename \"$0\") (master|seed) path/to/VALUES_FILE1 [path/to/VALUES_FILE2 ...] path/to/CHART_FOLDER (monitoring|logging|backup|kubermatic|kubermatic-deployment-only)"
  echo "FYI: kubermatic|kubermatic-deployment-only is deprecated due to new kubermatic-installer binary"
  exit 1
fi

DEPLOY_TYPE="$1"
if [[ "$DEPLOY_TYPE" = master ]]; then
  MASTER_FLAG="--set=kubermatic.isMaster=true"
elif [[ "$DEPLOY_TYPE" = seed ]]; then
  MASTER_FLAG="--set=kubermatic.isMaster=false"
else
  echo "invalid deploy type, expected (master|seed), got $DEPLOY_TYPE"
fi

args=("$@")

# at least 4 arguments
if [[ ${#args[@]} -lt 4 ]]; then
  echo "Usage: $(basename "$0") (master|seed) values1.yaml [values2.yaml ...] path/to/CHART_FOLDER (monitoring|logging|backup|kubermatic|kubermatic-deployment-only)"
  exit 1
fi

# helm values files = args[1..-3]
HELM_VALUES_ARGS=()
for (( i=1; i<${#args[@]}-2; i++ )); do
  VALUES_FILE="$(realpath "${args[$i]}")"
  if [[ ! -f "$VALUES_FILE" ]]; then
    echodate "'values.yaml' not found: $VALUES_FILE"
    exit 1
  fi
  HELM_VALUES_ARGS+=( --values "$VALUES_FILE" )
done

if [[ ${#HELM_VALUES_ARGS[@]} -eq 0 ]]; then
  echodate "At least one values.yaml must be provided."
  exit 1
fi

# CHART_FOLDER = penultimate argument
CHART_FOLDER=$(realpath "${args[-2]}")
if [[ ! -d "$CHART_FOLDER" ]]; then
    echodate "CHART_FOLDER not found! $CHART_FOLDER"
    exit 1
fi
### verification is checked in case expresion
# DEPLOY_STACK = last argument
DEPLOY_STACK="${args[-1]}"

DEPLOY_CERTMANAGER=true
DEPLOY_MINIO=true
DEPLOY_ALERTMANAGER=true
DEPLOY_LOKI=true
DEPLOY_IAP=true
#CANARY_DEPLOYMENT=true

# verify Helm3
[[ $(helm version --short) =~ ^v3.*$ ]] && echo "helm3 detected!" || (echo "This script requires helm3! Please install helm3: https://helm.sh/docs/intro/install" && exit 1)

function deploy {
  local name="$1"
  local namespace="$2"
  local path="$CHART_FOLDER/$3"
  local timeout="${4:-300s}"

  if [[ ! -d "$path" ]]; then
    echo "chart not found! $path"
    exit 1
  fi
  TEST_NAME="[Helm] Deploy chart $name"

  if [[ -v CANARY_DEPLOYMENT ]]; then
    inital_revision="$(helm history $name --output=json | jq '.Releases[0].Revision')"
  fi

  echodate "Fetching dependencies for chart $name ..."
  requiresUpdate=false
  chartname=$(yq eval .name $path/Chart.yaml )
  i=0
  for url in $(yq eval '.dependencies[]|select(.repository != null)|.repository' $path/Chart.yaml); do
    # Remove quotes from the URL
    url=${url//\"/}
    # Skip OCI repositories as they don't need to be added to helm repos
    if [[ "$url" == oci://* ]]; then
      echodate "Skipping OCI repository: $url"
      continue
    fi
    i=$((i + 1))
    helm repo add ${chartname}-dep-${i} ${url}
    requiresUpdate=true
  done

  if $requiresUpdate; then
    helm repo update
  fi

  echodate "Upgrading [$namespace] $name ..."
  kubectl create namespace "$namespace" || true
  helm dependency build $path
  helm upgrade --install --wait --timeout $timeout $MASTER_FLAG "${HELM_VALUES_ARGS[@]}" --namespace "$namespace" "$name" "$path"

  if [[ -v CANARY_DEPLOYMENT ]]; then
    TEST_NAME="[Helm] Rollback chart $name"
    echodate "Rolling back $name to revision $inital_revision as this was only a canary deployment"
    helm rollback --wait --timeout "$timeout" "$name" "$inital_revision"
  fi
  unset TEST_NAME
}

function deployBackup() {
      # CI has its own Minio deployment as a proxy for GCS, so we do not install the default Helm chart here.
    if [[ -v DEPLOY_MINIO ]]; then
      deploy    minio minio minio/
      deploy    s3-exporter kube-system s3-exporter/
    fi
    if [[ -d "$CHART_FOLDER/backup/velero/crd" ]]; then
      kubectl apply -f "$CHART_FOLDER/backup/velero/crd"
    fi
    deploy velero velero backup/velero
}

function deployCertManager() {
    if [[ -v DEPLOY_CERTMANAGER ]]; then
      #### CERT-MANAGER
      kubectl apply -f "$CHART_FOLDER/cert-manager/crd"
      deploy    cert-manager cert-manager cert-manager/
    fi
}

function deployIAP() {
    # We might have not configured IAP which results in nothing being deployed. This triggers https://github.com/helm/helm/issues/4295 and marks this as failed
    # We hack around this by grepping for a string that is mandatory in the values file of IAP
    # to determine if its configured, because an empty chart leads to Helm doing weird things
    if [[ -v DEPLOY_IAP ]]; then
      # Check all values files to see if oidc_issuer_url occurs
      local iap_configured=false
      for value_file in "${HELM_VALUES_ARGS[@]}"; do
        # Array elements have the following form: --values "/abs/path"
        # We only need the path:
        if [[ "$value_file" == --values ]]; then
          continue
        fi
        ### not used until iap ca field is not in chart
        if grep -q 'oidc_issuer_url' "$value_file"; then
          iap_configured=true
          break
        fi
      done
      
      if [[ "$iap_configured" == true ]]; then
        deploy iap iap iap/
      else
        echodate "Skipping IAP deployment because discovery_url is unset in values file"
      fi
    fi
}

echodate "Deploying $DEPLOY_STACK stack..."

case "$DEPLOY_STACK" in
  monitoring)
    deployIAP
    deploy      node-exporter monitoring monitoring/node-exporter/
    deploy      kube-state-metrics monitoring monitoring/kube-state-metrics/
    deploy      grafana monitoring monitoring/grafana/
    deploy      blackbox-exporter monitoring monitoring/blackbox-exporter/
    if [[ -v DEPLOY_ALERTMANAGER ]]; then
      deploy    alertmanager monitoring monitoring/alertmanager/
    fi
    deploy      prometheus monitoring monitoring/prometheus/ 900s
    ;;

  logging)
    #### elastic stack removed -> Loki
    if [[ "${DEPLOY_LOKI}" = true ]]; then
      deploy "loki" "logging" logging/loki/
      if [[ -d "$CHART_FOLDER/logging/alloy" ]]; then
        deploy "alloy" "logging" logging/alloy/ 900s
      else
        deploy "promtail" "logging" logging/promtail/ 900s
      fi
    fi
    ;;

  kubermatic)
    deploy nginx-ingress-controller nginx-ingress-controller nginx-ingress-controller/
    deployCertManager
    if [[ "$DEPLOY_TYPE" == master ]]; then
      deploy    oauth oauth oauth/
    fi
    deployBackup
    ;;

  cert-manager)
    deployCertManager
    ;;
  backup)
    deployBackup
    ;;

  *)
    echo "error: no DEPLOY_STACK defined"
esac
