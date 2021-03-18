########## K1 seed cluster
K1_CONFIG="."
TF_CONFIG="./tf-infra"    #relative from K1_CONFIG
# from K1_CONFIG location
K1_SSH_KEY="./credentials/id_rsa"
K1_CRED_FILE="./credentials/credentials.yaml"
K1_KUBECONFIG="./eksd-kubeconfig"

######### KubeOne
## load all files & configs we need for KubeOne
k1-load-env:
	test -d ${K1_CONFIG} && echo "[ok]" && echo "kubeone config folder found "
	cd ${K1_CONFIG} && test -f ${K1_SSH_KEY} && chmod 600 ${K1_SSH_KEY} && ssh-add ${K1_SSH_KEY} && echo "[ok] "|| echo "ssh key permission ..."
###
## Run Terraform Init
k1-tf-init:
	cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
	terraform init

## Run Terraform apply
k1-tf-apply: k1-load-env k1-tf-init
	cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
	terraform apply

## Run Terraform destroy to unprovision
k1-tf-destroy: k1-load-env
	cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
	terraform destroy

## run Terraform refresh to refresh state
k1-tf-refresh: k1-load-env
	cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
	terraform refresh

## run kubeone apply
k1-apply:k1-load-env
	cd ${K1_CONFIG} && kubeone -c ${K1_CRED_FILE} apply -m kubeone.yaml -t ${TF_CONFIG} --verbose --auto-approve

##run kubeone reset
k1-reset: k1-load-env
	cd ${K1_CONFIG} && kubeone -c ${K1_CRED_FILE} reset -m kubeone.yaml -t ${TF_CONFIG}  --verbose

k1-kubeconfig: k1-load-env
	cd ${K1_CONFIG} && kubeone -c ${K1_CRED_FILE} kubeconfig -m kubeone.yaml -t ${TF_CONFIG} > ${K1_KUBECONFIG}

