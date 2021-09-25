########## K1 seed cluster
K1_CONFIG="."
TF_CONFIG="./tf-infra"    #relative from K1_CONFIG
# from K1_CONFIG location
#K1_SSH_KEY="../.env/wacker"
#K1_CRED_FILE="../.env/credentials.kubermatic.yml"

######### KubeOne
k1-load-env:
	test -d ${K1_CONFIG} && echo "[ok]" && echo "kubeone config folder found "
	cd ${K1_CONFIG} && test -f ${K1_SSH_KEY} && chmod 600 ${K1_SSH_KEY} && ssh-add ${K1_SSH_KEY} && echo "[ok] "|| echo "ssh key permission ..."

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

k1-apply:k1-load-env
	cd ${K1_CONFIG} && kubeone apply -m kubeone.yaml --verbose --auto-approve
	make k1-apply-md

k1-reset: k1-load-env
	cd ${K1_CONFIG} && kubeone reset -m kubeone.yaml --verbose

k1-get-kubeconfig: k1-load-env
	cd ${K1_CONFIG} && kubeone kubeconfig -m kubeone.yaml > k1-kubeconfig

k1-apply-addons: k1-load-env
	kubectl apply -f ${K1_CONFIG}/addons

k1-apply-md: k1-load-env
	kubectl apply -f ${K1_CONFIG}/machines
