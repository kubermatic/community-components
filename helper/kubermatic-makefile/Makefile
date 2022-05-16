######### Define deployed version
KKP_VERSION = v2.17.0
KKP_RELEASE_ROOT_FOLDER="./releases"

##############  Custom CA
# CA issuer can only be applied after cert-manager is installed
### custom ca
#CA_SECRET ?= "./ca-certs/selfsigned-ca/secret.ca.yaml"
#CA_ISSUER ?= "./kubermatic-setup/certmanager.issuer.yaml"
#ca-apply-config:
#	kubectl apply -f ${CA_SECRET}
#	kubectl apply -f ${CA_ISSUER}

######### Kubermatic KKP
### Kubermatic configs
KKP_INSTALL_FILES ?= "${KKP_RELEASE_ROOT_FOLDER}/${KKP_VERSION}"
CHARTS ?= ${KKP_INSTALL_FILES}/charts
DEPLOY_SCRIPT ?= "../kubermatic-installer-script/kubermatic-deploy.sh"
CLUSTER_TYPE = "master"
VALUE_FILE ?= "./values.yaml"
KKP_CONFIG ?="./kubermatic.operator.config.yaml"
KKP_SETTINGS_FILE_FOLDER ?= "./settings/"
KKP_MASTER_KUBECONFIG ?= "./master-cluster-kubeconfig"
KKP_SECRET_MANIFESTS="../secrets"
KKP_ADDON_FOLDER="../../kubermatic/kubermatic-addons"
KKP_ADDON_MANIFEST ?= ${KKP_ADDON_FOLDER}/addon-manifests
KKP_PRE_OPERATOR_MANIFEST ?= "./pre-operator"
KKP_OPERATOR_ADD_FLAGS ?= --migrate-cert-manager --force
#TAG_POST_FIX="-2021-05-16"

check-env:
ifndef KKP_VERSION
	bash -c "echo -e 'KKP_VERSION is undefined, kubermatic charts are pointing to the following version:\n' \
		&& grep 'repository.*kubermatic/kubermatic' -C 2 ${CHARTS}/kubermatic/values.yaml \
		; exit 1"
endif

kkp-addon: check-env
	### update git module to latest
	cd ${KKP_ADDON_FOLDER} && \
		TAG_POST_FIX=${TAG_POST_FIX} KKP_VERSION=${KKP_VERSION} make docker-release
	echo -e "..... update now image tag in the ${KKP_CONFIG}!\n"

kkp-deployment-core:
	test -d ${KKP_PRE_OPERATOR_MANIFEST} && KUBECONFIG=${KKP_MASTER_KUBECONFIG} \
		kubectl apply -f ${KKP_PRE_OPERATOR_MANIFEST} && echo "applied " || echo "KKP_PRE_OPERATOR_MANIFEST manifest files ..."
	KUBECONFIG=${KKP_MASTER_KUBECONFIG} ${KKP_INSTALL_FILES}/kubermatic-installer --verbose --charts-directory ${CHARTS} deploy --config ${KKP_CONFIG} --helm-values ${VALUE_FILE} ${KKP_OPERATOR_ADD_FLAGS}
	echo ... && sleep 10
	KUBECONFIG=${KKP_MASTER_KUBECONFIG} kubectl get pod,svc -n cert-manager
	KUBECONFIG=${KKP_MASTER_KUBECONFIG} kubectl get pod,svc -n nginx-ingress-controller
	KUBECONFIG=${KKP_MASTER_KUBECONFIG} kubectl get pod,svc -n oauth
	KUBECONFIG=${KKP_MASTER_KUBECONFIG} kubectl get pod,svc -n kubermatic

kkp-apply-settings:
	test -d ${KKP_SECRET_MANIFESTS} && KUBECONFIG=${KKP_MASTER_KUBECONFIG} \
		kubectl apply -f ${KKP_SECRET_MANIFESTS} && echo "applied " || echo "SECRET manifest files ..."
	test -f ${KKP_CONFIG} && KUBECONFIG=${KKP_MASTER_KUBECONFIG} \
		kubectl apply -f ${KKP_CONFIG} && echo "applied " || echo "settings files ..."
	test -d ${KKP_SETTINGS_FILE_FOLDER} && KUBECONFIG=${KKP_MASTER_KUBECONFIG} \
		kubectl apply -f ${KKP_SETTINGS_FILE_FOLDER} && echo "applied " || echo "settings files ..."
	test -d ${KKP_ADDON_MANIFEST} && KUBECONFIG=${KKP_MASTER_KUBECONFIG} \
		kubectl apply -f ${KKP_ADDON_MANIFEST} && echo "applied " || echo "addon manifest files ..."

kkp-deployment: kkp-deployment-core kkp-apply-settings

logging-deployment:
	KUBECONFIG=${KKP_MASTER_KUBECONFIG} ${DEPLOY_SCRIPT} ${CLUSTER_TYPE} ${VALUE_FILE} ${CHARTS} logging

monitoring-deployment:
	KUBECONFIG=${KKP_MASTER_KUBECONFIG} ${DEPLOY_SCRIPT} ${CLUSTER_TYPE} ${VALUE_FILE} ${CHARTS} monitoring

backup-deployment:
	KUBECONFIG=${KKP_MASTER_KUBECONFIG} ${DEPLOY_SCRIPT} ${CLUSTER_TYPE} ${VALUE_FILE} ${CHARTS} backup

### SEED
#KKP_SEED_SETTINGS_FILE_FOLDER ?= "./kubermatic-setup/settings-seed/"
#KKP_SEED_KUBECONFIG ?= "./secrects/seed-kubeconfig"
#
#kkp-seed-deployment:
#	KUBECONFIG=${KKP_SEED_KUBECONFIG} ${DEPLOY_SCRIPT} seed ${VALUE_FILE} ${CHARTS} kubermatic
#	make kkp-seed-apply-settings
#
#kkp-seed-apply-settings:
#	test -d ${KKP_SEED_SETTINGS_FILE_FOLDER} && KUBECONFIG=${KKP_MASTER_KUBECONFIG} kubectl apply -f ${KKP_SEED_SETTINGS_FILE_FOLDER} && echo "applied " || echo "settings files ..."

all-deployment: kkp-deployment logging-deployment monitoring-deployment backup-deployment #kkp-seed-deployment

################## Helpers
BIN_ARCH ?= linux-amd64    #use e.g. for MAC OS: BIN_ARCH=darwin-amd64 make download-kkp-release
download-kkp-release:
	mkdir -p ${KKP_RELEASE_ROOT_FOLDER}/${KKP_VERSION}
	wget https://github.com/kubermatic/kubermatic/releases/download/${KKP_VERSION}/kubermatic-ee-${KKP_VERSION}-${BIN_ARCH}.tar.gz -O- | tar -xz --directory ${KKP_RELEASE_ROOT_FOLDER}/${KKP_VERSION}/
	rm -rf ${KKP_RELEASE_ROOT_FOLDER}/{KKP_VERSION}/.kube

######## VAULT
VAULT_ADDR="https://vault.example.com"
VAULT_ENGINE_PATH="project-kv-engine/kubermatic.example.com"
VAULT_LOCAL="../secrets"
VAULT_SCRIPT="../vault/vault-kv-management.sh"
OIDC_PATH=TODO
vault-upload:
	VAULT_ADDR=${VAULT_ADDR} VAULT_ENGINE_PATH=${VAULT_ENGINE_PATH} LOCAL="${VAULT_LOCAL}" \
		${VAULT_SCRIPT} --upload

vault-download:
	VAULT_ADDR=${VAULT_ADDR} VAULT_ENGINE_PATH=${VAULT_ENGINE_PATH} LOCAL="${VAULT_LOCAL}" \
		${VAULT_SCRIPT}

vault-login-user:
	@read -p "Enter vault username:" user; \
	VAULT_ADDR=${VAULT_ADDR} vault login -method=userpass username=$$user

vault-login:
	VAULT_ADDR=${VAULT_ADDR} vault login --method=oidc --path=$OIDC_PATH