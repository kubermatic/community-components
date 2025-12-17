#!/usr/bin/env bash
# Kubermatic Deployment script based on helm3
set -euo pipefail
set +x

BASEDIR=$(dirname "$0")
source $BASEDIR/../hack/lib.sh

DEPLOY_S3_SYNCER="s3-syncer"
DEPLOY_RCLONE_S3_SYNCER="rclone-s3-syncer"
DEPLOY_SGW="service-gateway"
DEPLOY_THANOS_SEED_INGRESS="thanos-seed-ingress"
DEPLOY_VMWARE_EXPORTER="vmware-exporter"

if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename "$0") path/to/values1.yaml [values2.yaml ...] path/to/CHART_FOLDER ($DEPLOY_S3_SYNCER|$DEPLOY_SGW|$DEPLOY_RCLONE_S3_SYNCER|$DEPLOY_THANOS_SEED_INGRESS|$DEPLOY_VMWARE_EXPORTER)"
  exit 1
fi

args=("$@")

# at least 3 arguments
if [[ ${#args[@]} -lt 3 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename \"$0\") path/to/values1.yaml [values2.yaml ...] path/to/CHART_FOLDER ($DEPLOY_S3_SYNCER|$DEPLOY_SGW|$DEPLOY_RCLONE_S3_SYNCER|$DEPLOY_THANOS_SEED_INGRESS|$DEPLOY_VMWARE_EXPORTER)"
  exit 1
fi

# helm values files = args[0..-2]
HELM_VALUES_ARGS=()
for (( i=0; i<${#args[@]}-2; i++ )); do
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

HELM_EXTRA_ARGS=${HELM_EXTRA_ARGS:-""} #"--dry-run --debug"

#verify Helm3
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

  echodate "Fetching dependencies for chart $name ..."
  requiresUpdate=false
  chartname=$(yq eval .name $path/Chart.yaml )
  i=0
  for url in $(yq eval '.dependencies[]|select(.repository != null)|.repository' $path/Chart.yaml); do
    i=$((i + 1))
    helm repo add ${chartname}-dep-${i} ${url}
    requiresUpdate=true
  done

  if $requiresUpdate; then
    helm repo update
  fi

  TEST_NAME="[Helm] Deploy chart $name into namespace $namespace"
  echodate "Upgrading $TEST_NAME ..."
  helm upgrade --create-namespace --install --wait $HELM_EXTRA_ARGS --timeout $timeout "${HELM_VALUES_ARGS[@]}" --namespace "$namespace" "$name" "$path"

  unset TEST_NAME
}

echodate "Deploying $DEPLOY_STACK stack..."
case "$DEPLOY_STACK" in
  "$DEPLOY_SGW")
    deploy service-gateway service-gateway-server service-gateway
    ;;

  "$DEPLOY_S3_SYNCER")
    deploy s3-syncer-aws-cli s3-syncer s3/s3-syncer-aws-cli
    ;;

  "$DEPLOY_RCLONE_S3_SYNCER")
    deploy rclone-s3-syncer s3-syncer rclone-s3-syncer
    ;;

  "$DEPLOY_THANOS_SEED_INGRESS")
    deploy thanos-seed-ingress monitoring thanos-seed-ingress
    ;;

  "$DEPLOY_VMWARE_EXPORTER")
    deploy vmware-exporter monitoring vmware-exporter
    ;;
  *)
    echo "error: no DEPLOY_STACK defined"
esac
