######### Define deployed version
KUBERMATIC_VERSION = v2.15.6
K8C_RELEASE_ROOT_FOLDER="./releases"

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
K8C_INSTALL_FILES ?= "${K8C_RELEASE_ROOT_FOLDER}/${KUBERMATIC_VERSION}"
CHARTS ?= ${K8C_INSTALL_FILES}/charts
K8C_SETTINGS_FILE_FOLDER ?= "./settings/"
DEPLOY_SCRIPT ?= "../kubermatic-installer-script/kubermatic-deploy.sh"
CLUSTER_TYPE = "master"
VALUE_FILE ?= "./values.yaml"
KUBERMATIC_CONFIG ?="./kubermatic.operator.config.yaml"
KUBERMATIC_SECRET_MANIFESTS="../secrets"
KUBERMATIC_ADDON_FOLDER="../../kubermatic/kubermatic-addons"
KUBERMATIC_ADDON_MANIFEST=${KUBERMATIC_ADDON_FOLDER}/addon-manifests
KUBERMATIC_PRE_OPERATOR_MANIFEST="./pre-operator"

check-env:
ifndef KUBERMATIC_VERSION
	bash -c "echo -e 'KUBERMATIC_VERSION is undefined, kubermatic charts are pointing to the following version:\n' \
		&& grep 'repository.*kubermatic/kubermatic' -C 2 ${CHARTS}/kubermatic/values.yaml \
		; exit 1"
endif

k8c-addon: check-env
	cd ${KUBERMATIC_ADDON_FOLDER} && KUBERMATIC_VERSION=${KUBERMATIC_VERSION} make docker-release
	echo -e "..... update now the values.yaml image tag!\n"
	kubectl apply -f ${KUBERMATIC_ADDON_MANIFEST}

k8c-deployment-core:
	test -d ${KUBERMATIC_PRE_OPERATOR_MANIFEST} && kubectl apply -f ${KUBERMATIC_PRE_OPERATOR_MANIFEST} && echo "applied " || echo "KUBERMATIC_PRE_OPERATOR_MANIFEST manifest files ..."
	${K8C_INSTALL_FILES}/kubermatic-installer --verbose --charts-directory ${CHARTS} deploy --config ${KUBERMATIC_CONFIG} --helm-values ${VALUE_FILE} --force
	echo ... && sleep 10
	${DEPLOY_SCRIPT} ${CLUSTER_TYPE} ${VALUE_FILE} ${CHARTS} cert-manager
	kubectl get pod,svc -n cert-manager
	kubectl get pod,svc -n nginx-ingress-controller
	kubectl get pod,svc -n oauth
	kubectl get pod,svc -n kubermatic

k8c-apply-settings:
	test -d ${KUBERMATIC_SECRET_MANIFESTS} && kubectl apply -f ${KUBERMATIC_SECRET_MANIFESTS} && echo "applied " || echo "SECRET manifest files ..."
	test -f ${KUBERMATIC_CONFIG} && kubectl apply -f ${KUBERMATIC_CONFIG} && echo "applied " || echo "settings files ..."
	test -d ${K8C_SETTINGS_FILE_FOLDER} && kubectl apply -f ${K8C_SETTINGS_FILE_FOLDER} && echo "applied " || echo "settings files ..."
	test -d ${KUBERMATIC_ADDON_MANIFEST} && kubectl apply -f ${KUBERMATIC_ADDON_MANIFEST} && echo "applied " || echo "addon manifest files ..."

k8c-deployment: k8c-deployment-core k8c-apply-settings

k8c-kubermatic-deployment-helm:
	${DEPLOY_SCRIPT} ${CLUSTER_TYPE} ${VALUE_FILE} ${CHARTS} kubermatic
	make k8c-apply-settings

k8c-kubermatic-deployment-only:
	${DEPLOY_SCRIPT} ${CLUSTER_TYPE} ${VALUE_FILE} ${CHARTS} kubermatic-deployment-only
	make k8c-apply-settings

logging-deployment:
	${DEPLOY_SCRIPT} ${CLUSTER_TYPE} ${VALUE_FILE} ${CHARTS} logging

monitoring-deployment:
	${DEPLOY_SCRIPT} ${CLUSTER_TYPE} ${VALUE_FILE} ${CHARTS} monitoring

backup-deployment:
	${DEPLOY_SCRIPT} ${CLUSTER_TYPE} ${VALUE_FILE} ${CHARTS} backup

### SEED
#K8C_SEED_SETTINGS_FILE_FOLDER ?= "./kubermatic-setup/settings-seed/"
#K8C_SEED_KUBECONFIG ?= "./secrects/seed-kubeconfig"
#
#k8c-seed-deployment:
#	KUBECONFIG=${K8C_SEED_KUBECONFIG} ${DEPLOY_SCRIPT} seed ${VALUE_FILE} ${CHARTS} kubermatic
#	make k8c-seed-apply-settings
#
#k8c-seed-apply-settings:
#	test -d ${K8C_SEED_SETTINGS_FILE_FOLDER} && kubectl apply -f ${K8C_SEED_SETTINGS_FILE_FOLDER} && echo "applied " || echo "settings files ..."

all-deployment: k8c-deployment logging-deployment monitoring-deployment backup-deployment #k8c-seed-deployment

################## Helpers
download-k8c-release:
	mkdir -p ${K8C_RELEASE_ROOT_FOLDER}/${KUBERMATIC_VERSION}
	wget https://github.com/kubermatic/kubermatic/releases/download/${KUBERMATIC_VERSION}/kubermatic-ee-${KUBERMATIC_VERSION}-linux-amd64.tar.gz -O- | tar -xz --directory ${K8C_RELEASE_ROOT_FOLDER}/${KUBERMATIC_VERSION}/
	rm -rf ${K8C_RELEASE_ROOT_FOLDER}/{KUBERMATIC_VERSION}/.kube

######## VAULT
VAULT_ADDR="https://vault.example.com"
VAULT_ENGINE_PATH="project-kv-engine/kubermatic.example.com"
VAULT_LOCAL="../secrets/kubermatic.example.com"
vault-upload:
	VAULT_ADDR=${VAULT_ADDR} VAULT_ENGINE_PATH=${VAULT_ENGINE_PATH} LOCAL="${VAULT_LOCAL}" \
		"../vault-kv-management.sh" --upload

vault-download:
	VAULT_ADDR=${VAULT_ADDR} VAULT_ENGINE_PATH=${VAULT_ENGINE_PATH} LOCAL="${VAULT_LOCAL}" \
    		"../vault-kv-management.sh"

vault-login:
	@read -p "Enter vault username:" user; \
	VAULT_ADDR=${VAULT_ADDR} vault login -method=userpass username=$$user

vault-login-oidc:
	VAULT_ADDR=${VAULT_ADDR} vault login --method=oidc --path=OIDC_PATH
