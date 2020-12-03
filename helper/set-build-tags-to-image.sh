#!/usr/bin/env bash

export GIT_HEAD_HASH=efe61ad8f8edf7322cab55ece091ff72fd870180
export LATEST_DASHBOARD=b356284988717fe076d91e1413700273524780edc4a09286f327540962d489e9

CHART_FOLDER=$(realpath "$1")
if [[ ! -d "$CHART_FOLDER" ]]; then
    echo "$(date -Is)" "CHART_FOLDER not found! $CHART_FOLDER"
    exit 1
fi

set -x
sed -i "s/__DASHBOARD_TAG__/$LATEST_DASHBOARD/g" $CHART_FOLDER/kubermatic/*.yaml
sed -i "s/__KUBERMATIC_TAG__/${GIT_HEAD_HASH}/g" $CHART_FOLDER/kubermatic/*.yaml
sed -i "s/__KUBERMATIC_TAG__/${GIT_HEAD_HASH}/g" $CHART_FOLDER/kubermatic-operator/*.yaml
sed -i "s/__KUBERMATIC_TAG__/${GIT_HEAD_HASH}/g" $CHART_FOLDER/nodeport-proxy/*.yaml