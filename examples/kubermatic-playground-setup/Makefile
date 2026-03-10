SHELL := bash
TF_DIR := 00-terraform/aws
K1_DIR := 10-kubeone
KKP_DIR := 20-kkp
KKP_VERSION ?= v2.29.5
KKP_RELEASE = kubermatic-ce-$(KKP_VERSION)-linux-amd64
DNS_ZONE ?= lab.kubermatic.io
ROUTE53_ZONEID ?= /hostedzone/Z08267412VFVFOL4NEM4P

VPC_ID = $(shell jq -re '[.kubeone_workers.value[].providerSpec.cloudProviderSpec.vpcId][0]' "$(TF_DIR)/tf.json")
CLUSTER_NAME = $(shell jq -re .kubeone_hosts.value.control_plane.cluster_name "$(TF_DIR)/tf.json")
KUBECONFIG = $(CLUSTER_NAME)-kubeconfig
DOMAIN = $(CLUSTER_NAME).$(DNS_ZONE)


default: help

terraform-apply: ## Create/update the AWS infrastructure.
	./scripts/with-aws-login.sh terraform -chdir="$(TF_DIR)" apply

terraform-output:
	terraform -chdir="$(TF_DIR)" output -json > "$(TF_DIR)/tf.json"
	@for i in `seq 10`; do \
		if jq -e .kubeone_api.value.endpoint "$(TF_DIR)/tf.json" >/dev/null; then exit 0; fi; \
		echo KubeOne API endpoint is not yet available, waiting...; \
		sleep 10; \
		./scripts/with-aws-login.sh terraform -chdir="$(TF_DIR)" refresh; \
		terraform -chdir="$(TF_DIR)" output -json > "$(TF_DIR)/tf.json"; \
	done; \
	echo "ERROR: KubeOne API endpoint did not become available!" >&2; \
	exit 1

terraform-destroy: ## Destroy the AWS infrastructure (must run kubeone-destroy first).
	./scripts/with-aws-login.sh terraform -chdir="$(TF_DIR)" destroy

kubeone-apply: terraform-output ## Create/update the Kubernetes cluster.
	./scripts/with-aws-login.sh kubeone apply -m "$(K1_DIR)/kubeone-cluster.yaml" -t "$(TF_DIR)/tf.json"

kubeone-destroy: ## Destroy the Kubernetes cluster.
	kubeone reset -m "$(K1_DIR)/kubeone-cluster.yaml" -t "$(TF_DIR)/tf.json"

kubeone-test: ## Test the Kubernetes cluster connectivity (listing nodes).
	kubectl get nodes --kubeconfig="$(KUBECONFIG)"

kkp-values: kkp-values.yaml kkp-kubermatic.yaml kkp-seed-mla-values ## Generate the configuration files.

kkp-apply: kkp-apply-master kkp-apply-seed kkp-apply-preset kkp-dns ## Install/update KKP master and seed into the Kubernetes cluster.

kkp-apply-master: kkp-values ## Install/update KKP master into the Kubernetes cluster.
	export KUBECONFIG="$(KUBECONFIG)"; \
	$(KKP_DIR)/release/$(KKP_RELEASE)/kubermatic-installer deploy \
		--charts-directory=$(KKP_DIR)/release/$(KKP_RELEASE)/charts \
		--storageclass=aws \
		--config=$(KKP_DIR)/kubermatic.yaml \
		--helm-values=$(KKP_DIR)/values.yaml \
		--helm-timeout=15m

kkp-dns: ## Register DNS record for the cluster.
	@export KUBECONFIG="$(KUBECONFIG)"; \
	for i in `seq 10`; do \
		LB_HOSTNAME="`kubectl -n kubermatic get ingress kubermatic -o jsonpath={.status.loadBalancer.ingress[0].hostname}`" || exit 1; \
		if [ "$$LB_HOSTNAME" ]; then \
			echo "$(DOMAIN) -> $$LB_HOSTNAME"; \
			./scripts/route53-modify-record.sh UPSERT $(ROUTE53_ZONEID) $(DOMAIN) CNAME "$$LB_HOSTNAME" && \
			./scripts/route53-modify-record.sh UPSERT $(ROUTE53_ZONEID) '*.$(DOMAIN)' CNAME "$$LB_HOSTNAME" || exit 1; \
			echo "KKP dashboard is now available at https://$(DOMAIN)"; \
			exit 0; \
		fi; \
		echo Kubermatic Ingress does not have a load balancer hostname assigned yet, waiting...; \
		sleep $$i; \
	done; \
	echo "ERROR: KKP Ingress does not have a load balancer hostname assigned!" >&2; \
	exit 1

kkp-apply-seed: kkp-values kkp-apply-backup-storageclass kkp-apply-seed-config ## Install/update KKP seed into the Kubernetes cluster.
	export KUBECONFIG="$(KUBECONFIG)"; \
	$(KKP_DIR)/release/$(KKP_RELEASE)/kubermatic-installer deploy kubermatic-seed \
		--charts-directory=$(KKP_DIR)/release/$(KKP_RELEASE)/charts \
		--config=$(KKP_DIR)/kubermatic.yaml \
		--helm-values=$(KKP_DIR)/values.yaml \
		--helm-timeout=15m

kkp-apply-preset: ## Install/update the KKP Preset into the Kubernetes cluster.
	export VPC_ID="$(VPC_ID)"; \
	RULES='.spec.aws.accessKeyID=strenv(AWS_ACCESS_KEY_ID) | .spec.aws.secretAccessKey=strenv(AWS_SECRET_ACCESS_KEY) | .spec.aws.vpcID=strenv(VPC_ID)'; \
	./scripts/with-aws-login.sh sh -c "yq eval '$$RULES' $(KKP_DIR)/preset.example.yaml | kubectl apply -f - --kubeconfig='$(KUBECONFIG)'"

kkp-apply-seed-config:
	$(KKP_DIR)/release/$(KKP_RELEASE)/kubermatic-installer convert-kubeconfig "$(KUBECONFIG)" > $(KKP_DIR)/kubeconfig
	export KUBECONFIG="$(KUBECONFIG)"; \
	kubectl create secret generic --from-file=$(KKP_DIR)/kubeconfig kubeconfig-cluster -n kubermatic --dry-run=client -o yaml | kubectl apply -f -
	rm $(KKP_DIR)/kubeconfig
	export KUBECONFIG="$(KUBECONFIG)"; \
	kubectl apply -f $(KKP_DIR)/seed.yaml

kkp-apply-backup-storageclass:
	export KUBECONFIG="$(KUBECONFIG)"; \
	kubectl apply -f $(KKP_DIR)/kubermatic-backup-storageclass.yaml

kkp-apply-seed-mla: kkp-seed-mla-values ## Install/upgrade the seed cluster monitoring stack.
	export KUBECONFIG="$(KUBECONFIG)"; \
	$(KKP_DIR)/release/$(KKP_RELEASE)/kubermatic-installer deploy seed-mla \
		--charts-directory=$(KKP_DIR)/release/$(KKP_RELEASE)/charts \
		--helm-values=$(KKP_DIR)/mla-seed-values.yaml \
		--mla-include-iap
	# TODO: test --migrate-gateway-api here

kkp-apply-usercluster-mla: kkp-usercluster-mla-values ## Install/upgrade the user cluster monitoring stack.
	export KUBECONFIG="$(KUBECONFIG)"; \
	$(KKP_DIR)/release/$(KKP_RELEASE)/kubermatic-installer deploy usercluster-mla \
		--charts-directory=$(KKP_DIR)/release/$(KKP_RELEASE)/charts \
		--helm-values=$(KKP_DIR)/mla-usercluster-values.yaml \
		--mla-include-iap

kkp-destroy-userclusters: ## Destroy all KKP user clusters.
	kubectl delete clusters --all --kubeconfig="$(KUBECONFIG)"

kkp-seed-mla-values: kkp kkp-values.yaml
	# TODO: remove minio since it has been set up for the seed already
	@[ -f "$(KKP_DIR)/mla-seed-values.yaml" ] || ( \
	echo Generating initial $(KKP_DIR)/mla-seed-values.yaml with random secrets; \
	export DOMAIN="$(DOMAIN)"; \
	export MINIO_ACCESS_KEY="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	export MINIO_SECRET_KEY="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	export GRAFANA_ADMIN_PASSWORD="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c14 | base64 -w0`"; \
	export GRAFANA_CLIENT_SECRET="`yq eval '.dex.config.staticClients[] | select(.id == "grafana").secret' "$(KKP_DIR)/values.yaml"`"; \
	export GRAFANA_ENCRYPTION_KEY="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	export KARMA_CLIENT_SECRET="`yq eval '.dex.config.staticClients[] | select(.id == "karma").secret' "$(KKP_DIR)/values.yaml"`"; \
	export KARMA_ENCRYPTION_KEY="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	export ALERTMANAGER_CLIENT_SECRET="`yq eval '.dex.config.staticClients[] | select(.id == "alertmanager").secret' "$(KKP_DIR)/values.yaml"`"; \
	export ALERTMANAGER_ENCRYPTION_KEY="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	export PROMETHEUS_CLIENT_SECRET="`yq eval '.dex.config.staticClients[] | select(.id == "prometheus").secret' "$(KKP_DIR)/values.yaml"`"; \
	export PROMETHEUS_ENCRYPTION_KEY="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	RULES='.minio.credentials.accessKey=strenv(MINIO_ACCESS_KEY) | .minio.credentials.secretKey=strenv(MINIO_SECRET_KEY)'; \
	RULES="$$RULES"' | .grafana.password=strenv(GRAFANA_ADMIN_PASSWORD)'; \
	RULES="$$RULES"' | .iap.oidc_issuer_url="https://"+strenv(DOMAIN)+"/dex"'; \
	RULES="$$RULES"' | .iap.deployments.grafana.encryption_key=strenv(GRAFANA_ENCRYPTION_KEY)'; \
	RULES="$$RULES"' | .iap.deployments.grafana.client_secret=strenv(GRAFANA_CLIENT_SECRET)'; \
	RULES="$$RULES"' | .iap.deployments.karma.encryption_key=strenv(KARMA_ENCRYPTION_KEY)'; \
	RULES="$$RULES"' | .iap.deployments.karma.client_secret=strenv(KARMA_CLIENT_SECRET)'; \
	RULES="$$RULES"' | .iap.deployments.alertmanager.encryption_key=strenv(ALERTMANAGER_ENCRYPTION_KEY)'; \
	RULES="$$RULES"' | .iap.deployments.alertmanager.client_secret=strenv(ALERTMANAGER_CLIENT_SECRET)'; \
	RULES="$$RULES"' | .iap.deployments.prometheus.encryption_key=strenv(PROMETHEUS_ENCRYPTION_KEY)'; \
	RULES="$$RULES"' | .iap.deployments.prometheus.client_secret=strenv(PROMETHEUS_CLIENT_SECRET)'; \
	yq eval "$$RULES" "$(KKP_DIR)/mla-seed-values.example.yaml" > $(KKP_DIR)/mla-seed-values.yaml)

	@echo Updating domain and client secrets within $(KKP_DIR)/mla-seed-values.yaml; \
	export SEED_DOMAIN="kubermatic.$(DOMAIN)"; \
	RULES='.'; \
	RULES="$$RULES"' | .grafana.host="grafana."+strenv(SEED_DOMAIN)'; \
	RULES="$$RULES"' | .alertmanager.host="alertmanager."+strenv(SEED_DOMAIN)'; \
	RULES="$$RULES"' | .prometheus.host="prometheus."+strenv(SEED_DOMAIN)'; \
	RULES="$$RULES"' | .iap.deployments.grafana.ingress.host="grafana."+strenv(SEED_DOMAIN)'; \
	RULES="$$RULES"' | .iap.deployments.alertmanager.ingress.host="alertmanager."+strenv(SEED_DOMAIN)'; \
	RULES="$$RULES"' | .iap.deployments.prometheus.ingress.host="prometheus."+strenv(SEED_DOMAIN)'; \
	RULES="$$RULES"' | .iap.deployments.karma.ingress.host="karma."+strenv(SEED_DOMAIN)'; \
	yq eval -i "$$RULES" "$(KKP_DIR)/mla-seed-values.yaml"

kkp-values.yaml: kkp $(KKP_DIR)/password
	@[ -f "$(KKP_DIR)/values.yaml" ] || ( \
	echo Generating initial $(KKP_DIR)/values.yaml with random secrets; \
	export CLIENT_SECRET="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	export ISSUER_CLIENT_SECRET="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	export MINIO_ACCESS_KEY="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	export MINIO_SECRET_KEY="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	export SEED_GRAFANA_CLIENT_SECRET="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	export SEED_ALERTMANAGER_CLIENT_SECRET="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	export SEED_KARMA_CLIENT_SECRET="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	export SEED_PROMETHEUS_CLIENT_SECRET="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	export USER_GRAFANA_CLIENT_SECRET="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	export USER_ALERTMANAGER_CLIENT_SECRET="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	export TELEMETRY_UUID=`uuidgen`; \
	RULES='.dex.config.staticClients[0].secret=strenv(CLIENT_SECRET) | .dex.config.staticClients[1].secret=strenv(ISSUER_CLIENT_SECRET)'; \
	RULES="$$RULES"' | .dex.config.staticClients += [{"id":"grafana", "name":"Grafana", "secret":strenv(SEED_GRAFANA_CLIENT_SECRET)}]'; \
	RULES="$$RULES"' | .dex.config.staticClients += [{"id":"alertmanager", "name":"Alertmanager", "secret":strenv(SEED_ALERTMANAGER_CLIENT_SECRET)}]'; \
	RULES="$$RULES"' | .dex.config.staticClients += [{"id":"karma", "name":"Karma", "secret":strenv(SEED_KARMA_CLIENT_SECRET)}]'; \
	RULES="$$RULES"' | .dex.config.staticClients += [{"id":"prometheus", "name":"Prometheus", "secret":strenv(SEED_PROMETHEUS_CLIENT_SECRET)}]'; \
	RULES="$$RULES"' | .dex.config.staticClients += [{"id":"mla-grafana", "name":"Grafana (user cluster)", "secret":strenv(USER_GRAFANA_CLIENT_SECRET)}]'; \
	RULES="$$RULES"' | .dex.config.staticClients += [{"id":"mla-alertmanager", "name":"Alertmanager (user cluster)", "secret":strenv(USER_ALERTMANAGER_CLIENT_SECRET)}]'; \
	RULES="$$RULES"' | .minio.storeSize="125Gi" | .minio.storageClass="kubermatic-backup"'; \
	RULES="$$RULES"' | .minio.credentials={"accessKey":strenv(MINIO_ACCESS_KEY), "secretKey":strenv(MINIO_SECRET_KEY)}'; \
	RULES="$$RULES"' | .telemetry.uuid=strenv(TELEMETRY_UUID)'; \
	yq eval "$$RULES" "$(KKP_DIR)/release/$(KKP_RELEASE)/examples/values.example.yaml" > $(KKP_DIR)/values.yaml)

	@echo Updating domain and password within $(KKP_DIR)/values.yaml; \
	export DOMAIN="$(DOMAIN)"; \
	export SEED_DOMAIN="kubermatic.$(DOMAIN)"; \
	export PASSWD_HASH="`cat "$(KKP_DIR)/password" | htpasswd -inBC 10 '' | tr -d ':\n' | sed 's/$$2y/$$2a/'`"; \
	RULES='.dex.ingress.hosts[0].host=strenv(DOMAIN) | .dex.ingress.tls[0].hosts[0]=strenv(DOMAIN) | .dex.config.issuer="https://"+strenv(DOMAIN)+"/dex"'; \
	RULES="$$RULES"' | (.dex.config.staticClients[] | select(.id=="kubermatic")) |= . + {"RedirectURIs":["https://"+strenv(DOMAIN),"https://"+strenv(DOMAIN)+"/projects"]}'; \
	RULES="$$RULES"' | (.dex.config.staticClients[] | select(.id=="kubermaticIssuer")) |= . + {"RedirectURIs":["https://"+strenv(DOMAIN)+"/api/v1/kubeconfig","https://"+strenv(DOMAIN)+"/api/v2/kubeconfig/secret","https://"+strenv(DOMAIN)+"/api/v2/dashboard/login"]}'; \
	RULES="$$RULES"' | (.dex.config.staticClients[] | select(.id=="grafana")) |= . + {"RedirectURIs":["https://grafana."+strenv(SEED_DOMAIN)]}'; \
	RULES="$$RULES"' | (.dex.config.staticClients[] | select(.id=="alertmanager")) |= . + {"RedirectURIs":["https://alertmanager."+strenv(SEED_DOMAIN)]}'; \
	RULES="$$RULES"' | (.dex.config.staticClients[] | select(.id=="karma")) |= . + {"RedirectURIs":["https://karma."+strenv(SEED_DOMAIN)]}'; \
	RULES="$$RULES"' | (.dex.config.staticClients[] | select(.id=="prometheus")) |= . + {"RedirectURIs":["https://prometheus."+strenv(SEED_DOMAIN)]}'; \
	RULES="$$RULES"' | (.dex.config.staticClients[] | select(.id=="mla-grafana")) |= . + {"RedirectURIs":["https://grafana.usercluster."+strenv(SEED_DOMAIN)]}'; \
	RULES="$$RULES"' | (.dex.config.staticClients[] | select(.id=="mla-alertmanager")) |= . + {"RedirectURIs":["https://alertmanager.usercluster."+strenv(SEED_DOMAIN)]}'; \
	RULES="$$RULES"' | .dex.config.staticPasswords[0].hash=strenv(PASSWD_HASH)'; \
	yq eval -i "$$RULES" "$(KKP_DIR)/values.yaml"

kkp-kubermatic.yaml: kkp-values.yaml
	@[ -f "$(KKP_DIR)/kubermatic.yaml" ] || ( \
	echo Generating initial $(KKP_DIR)/kubermatic.yaml with random secrets; \
	export ISSUER_COOKIE_KEY="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	export SERVICE_ACCOUNT_KEY="`cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c32`"; \
	RULES='.spec.auth.issuerCookieKey=strenv(ISSUER_COOKIE_KEY) | .spec.auth.serviceAccountKey=strenv(SERVICE_ACCOUNT_KEY)'; \
	RULES="$$RULES"' | .spec.featureGates.UserClusterMLA=true'; \
	yq eval "$$RULES" "$(KKP_DIR)/release/$(KKP_RELEASE)/examples/kubermatic.example.yaml" > $(KKP_DIR)/kubermatic.yaml)

	@echo Updating domain and issuer client secret within $(KKP_DIR)/kubermatic.yaml; \
	export DOMAIN="$(DOMAIN)"; \
	export ISSUER_CLIENT_SECRET="`yq eval '.dex.config.staticClients[] | select(.id=="kubermaticIssuer").secret' "$(KKP_DIR)/values.yaml"`"; \
	RULES='.spec.ingress.domain=strenv(DOMAIN) | .spec.auth.tokenIssuer="https://"+strenv(DOMAIN)+"/dex"'; \
	RULES="$$RULES | .spec.auth.issuerClientSecret=strenv(ISSUER_CLIENT_SECRET)"; \
	yq eval -i "$$RULES" "$(KKP_DIR)/kubermatic.yaml"
	# TODO: configure let's encrypt prod issuer?!

$(KKP_DIR)/password:
	cat /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c14 > "$(KKP_DIR)/password"

kkp: $(KKP_DIR)/release/$(KKP_RELEASE)
$(KKP_DIR)/release/$(KKP_RELEASE):
	mkdir -p "$(KKP_DIR)/release/$(KKP_RELEASE).tmp"
	curl -fsSL "https://github.com/kubermatic/kubermatic/releases/download/$(KKP_VERSION)/$(KKP_RELEASE).tar.gz" | tar -C "$(KKP_DIR)/release/$(KKP_RELEASE).tmp" -xzf -
	mv "$(KKP_DIR)/release/$(KKP_RELEASE).tmp" "$(KKP_DIR)/release/$(KKP_RELEASE)"

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
