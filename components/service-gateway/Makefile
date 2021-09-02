
#### Upload secrets
######## VAULT
# https://vault.loodse.support/ui/vault/secrets/wacker/list
VAULT_ADDR=https://vault.loodse.support
VAULT_SCRIPT ?= "../../../helper/vault-ops.sh"
VAULT_PATH_SECRETS_DEV="wacker/service-gateway/vpn-client-secrets-dev"
VAULT_PATH_SECRETS_PROD="wacker/service-gateway/vpn-client-secrets-prod"
PATH_SECRETS_DEV="../../../secrets/dev-setup/service-gateway-server"
PATH_SECRETS_PROD="../../../secrets/prod-setup/service-gateway-server"

vault-download:
	VAULT_ADDR=${VAULT_ADDR} VAULT_ENGINE_PATH=${VAULT_PATH_SECRETS_DEV} LOCAL=${PATH_SECRETS_DEV} ${VAULT_SCRIPT}
	VAULT_ADDR=${VAULT_ADDR} VAULT_ENGINE_PATH=${VAULT_PATH_SECRETS_PROD} LOCAL=${PATH_SECRETS_PROD} ${VAULT_SCRIPT}

vault-upload:
	VAULT_ADDR=${VAULT_ADDR} VAULT_ENGINE_PATH=${VAULT_PATH_SECRETS_DEV} LOCAL=${PATH_SECRETS_DEV} ${VAULT_SCRIPT} --upload
	VAULT_ADDR=${VAULT_ADDR} VAULT_ENGINE_PATH=${VAULT_PATH_SECRETS_PROD} LOCAL=${PATH_SECRETS_PROD} ${VAULT_SCRIPT} --upload

vault-login:
	VAULT_ADDR=${VAULT_ADDR} vault login --method=oidc --path=loodse

