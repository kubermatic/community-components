########## K1 Helper for easy management
K1_CONFIG="."
TF_CONFIG="./tf-infra"    #relative from K1_CONFIG
# from K1_CONFIG location
K1_SSH_KEY="./secrets/id_rsa"
K1_CRED_FILE="./secrets/credentials.kubermatic.yml"
K1_CRED_FLAG=-c ${K1_CRED_FILE}
K1_KUBECONFIG?=k1-kubeconfig
K1_EXTRA_ARG?=""
#K1_EXTRA_ARG?="--force-upgrade"

##### GENERIC
CLOUD_CREDENTIALS_ENV_FILE="./secret/cloud_env.sh"
include ${CLOUD_CREDENTIALS_ENV_FILE}
export

##### VSPHERE
#VSPHERE_USER_CRED_FILE=./secrets/vsphere_cred_user.sh
#include ${VSPHERE_USER_CRED_FILE}
#### sometimes needed if "special characters in password or username is used
##VSPHERE_USER_CRED_FILE_OVERWRITE=./secrets/vsphere_cred_user.makefile.overwrite.env
##include ${VSPHERE_USER_CRED_FILE_OVERWRITE}
#export

######### KubeOne
k1-load-env:
	@test -d ${K1_CONFIG} && echo "[ok]" && echo "kubeone config folder found " || exit 1
	@cd ${K1_CONFIG} && test -f ${K1_SSH_KEY} && chmod 600 ${K1_SSH_KEY} && ssh-add ${K1_SSH_KEY} && echo "[ok] "|| (echo "ERROR: ssh key permission ..." && exit 2)
	### store kubeone version
	kubeone version > ${K1_CONFIG}/kubeone.version.json
	##### CHECK for vSphere user credentials
	#ifdef GOVC_USERNAME
	#	@echo "VSphere UserName sourced is: ${GOVC_USERNAME}"
	#else
	#	@echo "ERROR: Please source vSphere user details are present!" && exit 3
	#endif

k1-tf-init:
	cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
		terraform init

k1-tf-apply: k1-load-env k1-tf-init
	cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
		terraform apply

k1-tf-destroy: k1-load-env
	cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
		terraform destroy

k1-tf-refresh: k1-load-env
	cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
		terraform refresh

k1-tf-output: k1-load-env
	cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
		terraform output

k1-apply:k1-load-env
	cd ${K1_CONFIG} && \
		kubeone ${K1_CRED_FLAG} apply -m kubeone.yaml -t ${TF_CONFIG} --verbose ${K1_EXTRA_ARG}
	make k1-apply-md

k1-reset: k1-load-env
	cd ${K1_CONFIG} && \
		kubeone ${K1_CRED_FLAG} reset -m kubeone.yaml -t ${TF_CONFIG}  --verbose ${K1_EXTRA_ARG}

k1-apply-md: k1-load-env k1-kubeconfig
	kubectl apply --kubeconfig ${K1_KUBECONFIG} -f ${K1_CONFIG}/machines

k1-kubeconfig: k1-load-env
	cd ${K1_CONFIG} && \
		kubeone ${K1_CRED_FLAG} kubeconfig -m kubeone.yaml -t ${TF_CONFIG} > ${K1_KUBECONFIG}

######## VAULT
VAULT_ADDR="https://vault.example.com"
VAULT_ENGINE_PATH="project-kv-engine/k1.example.com"
VAULT_LOCAL="../secrets"
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