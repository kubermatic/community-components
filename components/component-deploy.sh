#!/usr/bin/env bash
# Kubermatic Deployment script based on helm3
set -euo pipefail
set +x

BASEDIR=$(dirname "$0")
source $BASEDIR/../hack/lib.sh

DEPLOY_S3_SYNCER="s3-syncer"
DEPLOY_RCLONE_S3_SYNCER="rclone-s3-syncer"
DEPLOY_SGW="service-gateway"
DEPLOY_CERT="cert-update-svc"
DEPLOY_THANOS_SEED_INGRESS="thanos-seed-ingress"
DEPLOY_VMWARE_EXPORTER="vmware-exporter"

if [[ $# -lt 4 ]] || [[ "$1" == "--help" ]]; then
  echo "ARGUMENTS:"$*
  echo ""
  echo "Usage: $(basename \"$0\") path/to/VALUES_FILES path/to/VALUE_FILE_OVERRIDE path/to/CHART_FOLDER ($DEPLOY_S3_SYNCER|$DEPLOY_SGW|$DEPLOY_WACKER_CERT)"
  exit 1
fi

VALUES_FILE=$(realpath "$1")
if [[ ! -f "$VALUES_FILE" ]]; then
    echodate -e "'values.yaml' in folder not found! \nCONTENT $VALUES_FILE:\n`ls -l $VALUES_FILE/..`"
    exit 1
fi

VALUE_FILE_OVERRIDE=$(realpath "$2")
if [[ ! -f "$VALUE_FILE_OVERRIDE" ]]; then
    VALUE_FILE_OVERRIDE=""
fi

CHART_FOLDER=$(realpath "$3")
if [[ ! -d "$CHART_FOLDER" ]]; then
    echodate "CHART_FOLDER not found! $CHART_FOLDER"
    exit 1
fi

### verification is checked in case expresion
DEPLOY_STACK="$4"

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
  helm upgrade --create-namespace --install --wait $HELM_EXTRA_ARGS --timeout $timeout --values "$VALUES_FILE" --values "$VALUE_FILE_OVERRIDE" --namespace "$namespace" "$name" "$path"

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
