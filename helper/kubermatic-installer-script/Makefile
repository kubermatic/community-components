######### Kubermatic KKP ########

######### Define deployed version
KUBERMATIC_VERSION = v2.15.5
K8C_RELEASE_ROOT_FOLDER="./releases"

########## Kubermatic configs
CHARTS ?= "${K8C_RELEASE_ROOT_FOLDER}/${KUBERMATIC_VERSION}/charts"
VALUE_FILE ?= "./vault/values.yaml"
PERSETS_FILE ?= "./vault/presets.yaml"
DEPLOY_SCRIPT ?= "./kubermatic-deploy.sh"
CLUSTER_TYPE ?= "master"
KUBERMATIC_CONFIG ?="./kubermatic-config"
K8C_SETTINGS_FILE_FOLDER ?= "${KUBERMATIC_CONFIG}"
KUBERMATIC_ADDON_FOLDER ?="../../kubermatic-addons"
KUBERMATIC_ADDON_MANIFEST ?= "${KUBERMATIC_ADDON_FOLDER}/addon-manifests"

check-env:
ifndef KUBERMATIC_VERSION
	bash -c "echo -e 'KUBERMATIC_VERSION is undefined, kubermatic charts are pointing to the following version:\n' \
		&& grep 'repository.*kubermatic/kubermatic' -C 2 ${CHARTS}/kubermatic/values.yaml \
		; exit 1"
endif

k8c-addon: check-env
	cd ${KUBERMATIC_ADDON_FOLDER} && \
#		git pull && \
		KUBERMATIC_VERSION=${KUBERMATIC_VERSION} make docker-release
	echo -e "..... update now the values.yaml image tag!\n"
	kubectl apply -f ${KUBERMATIC_ADDON_MANIFEST}

k8c-deployment-core:
	${K8C_INSTALL_FILES}/kubermatic-installer --verbose --charts-directory ${CHARTS} deploy --config ${KUBERMATIC_CONFIG} --helm-values ${VALUE_FILE} --force
	echo ... && sleep 10
	kubectl get pod,svc -n cert-manager
	kubectl get pod,svc -n nginx-ingress-controller
	kubectl get pod,svc -n oauth
	kubectl get pod,svc -n kubermatic

k8c-apply-settings:
	test -f ${KUBERMATIC_CONFIG} && kubectl apply -f ${KUBERMATIC_CONFIG} && echo "applied " || echo "settings files ..."
	test -d ${K8C_SETTINGS_FILE_FOLDER} && kubectl apply -f ${K8C_SETTINGS_FILE_FOLDER} && echo "applied " || echo "settings files ..."
	test -d ${KUBERMATIC_ADDON_MANIFEST} && kubectl apply -f ${KUBERMATIC_ADDON_MANIFEST} && echo "applied " || echo "addon manifest files ..."
	test -d ${PERSETS_FILE} && kubectl apply -f ${PERSETS_FILE} && echo "applied " || echo "preset manifest files ..."

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

all-deployment: k8c-deployment-core logging-deployment monitoring-deployment

################## Helpers
download-k8c-release:
	mkdir -p ${K8C_RELEASE_ROOT_FOLDER}/${KUBERMATIC_VERSION}
	wget https://github.com/kubermatic/kubermatic/releases/download/${KUBERMATIC_VERSION}/kubermatic-ee-${KUBERMATIC_VERSION}-linux-amd64.tar.gz -O- | tar -xz --directory ${K8C_RELEASE_ROOT_FOLDER}/${KUBERMATIC_VERSION}/
	rm -rf ${K8C_RELEASE_ROOT_FOLDER}/{KUBERMATIC_VERSION}/.kube

### SEED
K8C_SEED_SETTINGS_FILE_FOLDER ?= "./kubermatic-setup/settings-seed/"
K8C_SEED_KUBECONFIG ?= "${K8C_SEED_SETTINGS_FILE_FOLDER}/seed-kubeconfig"

k8c-seed-deployment:
	KUBECONFIG=${K8C_SEED_KUBECONFIG} ${DEPLOY_SCRIPT} seed ${VALUE_FILE} ${CHARTS} kubermatic
	make k8c-seed-apply-settings

k8c-seed-apply-settings:
	test -d ${K8C_SEED_SETTINGS_FILE_FOLDER} && kubectl apply -f ${K8C_SEED_SETTINGS_FILE_FOLDER} && echo "applied " || echo "settings files ..."