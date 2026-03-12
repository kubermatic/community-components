#!/bin/bash

# Fetches AWS credentials from Vault and exports them as env vars.
# A command can be passed as arguments that is then run as a child process.
# Usage: ./with-aws-login.sh [COMMAND]

set -euo pipefail

: ${VAULT_ADDR:=https://vault.kubermatic.com}
: ${VAULT_OIDC_AUTH_PATH:=loodse}
: ${VAULT_AWS_PATH:=dev/aws-playground}

export VAULT_ADDR

if ! vault token lookup &>/dev/null; then
	echo "Logging in to Vault..."
	vault login --method=oidc --path="$VAULT_OIDC_AUTH_PATH"
fi

echo "Fetching AWS credentials from Vault..."

export AWS_ACCESS_KEY_ID=$(vault kv get -field=accessKeyID "$VAULT_AWS_PATH")
export AWS_SECRET_ACCESS_KEY=$(vault kv get -field=secretAccessKey "$VAULT_AWS_PATH")
export AWS_REGION=$(vault kv get -field=region "$VAULT_AWS_PATH")

aws sts get-caller-identity >/dev/null
echo Logged in to AWS successfully

if [ $# -ge 1 ]; then
	echo Running "$@"
	exec "$@"
fi
