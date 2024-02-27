KKP_VERSION=v2.23.6
INSTALL_DIR=/opt/kubermatic/releases/${KKP_VERSION}

# Install seed
install-kkp-dev:
	${INSTALL_DIR}/kubermatic-installer deploy \
	  --charts-directory ${INSTALL_DIR}/charts --config ./dev/vj1-master/k8cConfig.yaml --helm-values ./dev/vj1-master/values.yaml --storageclass aws \
	  --skip-charts='cert-manager,nginx-ingress-controller,dex'

create-long-lived-master-seed-kubeconfig:
	${INSTALL_DIR}/kubermatic-installer convert-kubeconfig /opt/personal/k8s-adventure/src/kubeone161/k1init/vj1-master-kubeconfig > ./seed-ready-kube-config

# Setup Seed1 - DEV Master
deploy-argo-dev-master:
	helm upgrade --install argocd --version 5.36.10 --namespace argocd --create-namespace argo/argo-cd -f values-argocd.yaml --set 'server.ingress.hosts[0]=argocd.vj1.lab.kubermatic.io' --set 'server.ingress.tls[0].hosts[0]=argocd.vj1.lab.kubermatic.io'

deploy-argo-apps-dev-master:
	helm template argo-apps --set kkpVersion=${KKP_VERSION} -f ./dev/vj1-master/argoapps-values.yaml /opt/kubermatic/community-components/ArgoCD-managed-seed | kubectl apply -f -

# Setup Seed2 - DEV India Seed
deploy-argo-dev-seed:
	helm upgrade --install argocd --version 5.36.10 --namespace argocd --create-namespace argo/argo-cd -f values-argocd.yaml --set 'server.ingress.hosts[0]=argocd.india.vj1.lab.kubermatic.io' --set 'server.ingress.tls[0].hosts[0]=argocd.india.vj1.lab.kubermatic.io'

deploy-argo-apps-dev-seed:
	helm template argo-apps --set kkpVersion=${KKP_VERSION} -f ./dev/india/argoapps-values.yaml /opt/kubermatic/community-components/ArgoCD-managed-seed | kubectl apply -f -

create-long-lived-seed-kubeconfig:
	${INSTALL_DIR}/kubermatic-installer convert-kubeconfig /opt/personal/k8s-adventure/src/kubeone161/k1init-seed/vj1-seed-kubeconfig > ./seed-ready-kube-config

### Local testing
create-kind-cluster:
	kind create cluster --config=./kind-install/cluster-nodeport.yaml --image kindest/node:v1.27.3
deploy-argo-kind-cluster:
	helm upgrade --install argocd --version 5.36.10 --namespace argocd --create-namespace argo/argo-cd -f values-argocd.yaml --set 'server.ingress.hosts[0]=argocd.dreamit.local' --set 'server.ingress.tls[0].hosts[0]=argocd.dreamit.local'
deploy-argo-apps-kind-cluster:
	helm template argo-apps --set kkpVersion=${KKP_VERSION} -f ./dev/kind/argoapps-values.yaml /opt/kubermatic/community-components/ArgoCD-managed-seed | kubectl apply -f -
