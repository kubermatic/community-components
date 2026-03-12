#!/bin/bash

# Fetches AWS and Route53 credentials from Vault
# To be sourced within another script

set -euo pipefail

: ${VAULT_ADDR:=https://vault.kubermatic.com}
: ${VAULT_OIDC_AUTH_PATH:=loodse}
: ${VAULT_ROUTE53_PATH:=dev/seed-clusters/dev.kubermatic.io}

export VAULT_ADDR

if ! vault token lookup &>/dev/null; then
	echo "Logging in to Vault..."
	vault login --method=oidc --path="$VAULT_OIDC_AUTH_PATH"
fi

echo "Fetching Route53 credentials from Vault..."

export AWS_ACCESS_KEY_ID=$(vault kv get -field=route53AccessKeyID "$VAULT_ROUTE53_PATH")
export AWS_SECRET_ACCESS_KEY=$(vault kv get -field=route53SecretAccessKey "$VAULT_ROUTE53_PATH")
