## Overview

This repository serves as an entry-point for multiple community-maintained components in the Kubermatic ecosystem.
Feedback is highly encouraged 👍

## Components

Dedicated components for customer purposes.

| Name                                                                                                      | Description                                                                                                                                                                                                                                                  |
|-----------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [certificates/self-signed-ca](components/certificates/self-signed-ca)                                     | How to create and managed self-signed CA at KKP                                                                                                                                                                                                              |
| [controllers/aws-private-ip-enforce-controller](components/controllers/aws-private-ip-enforce-controller) | Enforces the `assignPublicIP: false` flag on all user cluster machine deployments                                                                                                                                                                            |
| [controllers/component-override-controller](components/controllers/component-override-controller)         | This bash-controller watches over Cluster objects and controls part of the spec.componentOverride.                                                                                                                                                           |
| [controllers/external-dns-route53](components/controllers/external-dns-route53)                           | [external-dns](https://github.com/kubernetes-sigs/external-dns) is a controller that automatically creates dns records for your ingresses and loadbalancer services. This is a chart that deploys an opinionated configuration for working with AWS Route 53 |
| [controllers/pod-cidr-controller](components/controllers/pod-cidr-controller)                             | This bash-controller watches over Cluster objects and patches spec.clusterNetwork.pods.cidrBlocks                                                                                                                                                            |
| [cron-jobs/scale-down](components/cron-jobs/scale-down)                                                   | running a cron job that scales down worker nodes during non work hours and weekends.                                                                                                                                                                         |
| [id-management/active-directory](components/id-management/active-directory)                               | Example how to configure KKP with Active Directory                                                                                                                                                                                                           |
| [id-management/openldap](./components/id-management/openldap)                                             | Helm based [OpenLDAP](https://www.openldap.org/) setup to deploy a indipendent LDAP server into Kubernetes for testing purposes                                                                                                                              |
| [id-management/keycloak](./components/id-management/keycloak)                                             | Example on how to configure and integrate KeyCloak setup as custom OIDC provider into Kubermatic KKP                                                                                                                                                         |
| [loadbalancers/metallb](components/loadbalancers/metallb)                                                 | Example config for MetalLB what aims to redress this imbalance by offering a Network LB implementation that integrates with standard network equipment                                                                                                       |
| [logging/audit/static-audit-log](components/logging/audit/static-audit-log)                               | Description how static audit logging could get configured                                                                                                                                                                                                    |
| [vm-images/packer-ubuntu1804-vsphere-template](./components/vm-images/packer-ubuntu1804-vsphere-template) | A packer template to customize an ubuntu 18.04 cloud-image on vSphere                                                                                                                                                                                        |
| [s3/s3-syncer-aws-cli](./components/s3/s3-syncer-aws-cli)                                                 | s3-syncer based CronJob on the `aws s3` cli to sync two different S3 locations as well Azure (by Minio Azure Gateway)                                                                                                                                        |
| [s3/s3-dbdump-syncer](./components/s3/s3-dbdump-syncer)                                                   | s3-syncer based CronJob creates a DB dump of a postgres SQL database and sync it via the `aws s3` cli to a target S3 location.                                                                                                                               |
| [api/cluster-management-by-api](components/api/cluster-management-by-api)                                 | Bash based management scripts to specify your KKP cluster by API for CI/CD or GitOPs purposes.                                                                                                                                                               | 
| [vmware-exporter](components/vmware-exporter)                                                             | Helm chart for VMware Exporter and Dashboard for Prometheus and Grafana for monitoring of vSphere environments in the KKP MLA stack.                                                                                                                         |
| [nutanix-exporter](components/nutanix-exporter)                                                           | Helm chart for [nutanix-exporter](https://github.com/claranet/nutnix-exporter) - exporter for Prometheus that can be used for monitoring of Nutanix-based environments.                                                                                      |

## Kubermatic Example Setups

| Name                                                                                      | Description                                                                                                                                                                                                                                                              |
|-------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [vSphere kubeOne / Kubermatic demo](./examples/vsphere-kubeone-kubermatic)                | an example for running kubermatic on vSphere with kubeOne to install the                                                                                                                                                                                                 |
| [AWS EKS -D kubeOne demo](./examples/amazon-eks-d)                                        | an example for creating a Cluster running Amazon EKS-D                                                                                                                                                                                                                   |
| [Bare Metal - KubeOne Static Hosts](./examples/baremetal/kubeone/vsphere-static-machines) | Example how to managed static bare metal workers. The "bare metal" workers are simulated with vSphere by terraform automation                                                                                                                                            |
| [Bare Metal - KKP and kubeadm join implementation examples](examples/baremetal/kkp)       | Example how to use [kubeadm](https://kubernetes.io/docs/setup/independent/install-kubeadm/) to join the KKP managed controlplan: [1 Manual Example](examples/baremetal/kkp/kubadm-manual), [2 SSH Multi Client join script](examples/baremetal/kkp/kubeadm-multi-client) |

## Kubermatic Addons

Configuration and tooling for common
used [KKP - Guides - Addon](https://docs.kubermatic.com/kubermatic/main/architecture/concept/kkp-concepts/addons/) for user cluster
customization.

| Name                                                                                          | Description                                                                                                                                                                                                                                                 |
|-----------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Makefile](kubermatic-addons/Makefile)                                                        | Wrapper for building KKP addons for a dedicated version                                                                                                                                                                                                     |
| [addon-manifests](kubermatic-addons/addon-manifests)                                          | Holding the `AddonConfig` custom resource specifications for a set of addons to configure KKP UI                                                                                                                                                            |
| [custom-addon/dns-resolve-overwrite](kubermatic-addons/custom-addon/dns-resolve-overwrite)    | A DaemonSet with privileged permissions to overwrite the host DNS at the kubernetes nodes                                                                                                                                                                   |
| [custom-addon/echoserver](kubermatic-addons/custom-addon/echoserver)                          | Simple echo server application as an example workload deployment with ingress config                                                                                                                                                                        |
| [custom-addon/ingress-nginx](kubermatic-addons/custom-addon/ingress-nginx)                    | Deploys the [Ingress Nginx Controller](https://github.com/kubernetes/ingress-nginx) to the user cluster                                                                                                                                                     |
| [custom-addon/trident-installer](kubermatic-addons/custom-addon/trident-installer)            | Addon for [NetApp Trident](https://github.com/NetApp/trident) storage support into a user cluster                                                                                                                                                           |
| [custom-addon/openebs](kubermatic-addons/custom-addon/openebs)                                | [OpenEBS](https://openebs.io/) addon for on-premise users without distributed storage                                                                                                                                                                       |
| [custom-addon/amd-gpu](kubermatic-addons/custom-addon/amd-gpu)                                | [AMD-GPU](https://github.com/RadeonOpenCompute/k8s-device-plugin) device plugin addon                                                                                                                                                                       |
| [custom-addon/kubeflow](kubermatic-addons/custom-addon/kubeflow)                              | [Kubeflow](https://github.com/kubermatic/flowmatic) Machine Learning Toolkit                                                                                                                                                                                |
| [custom-addon/ntp-sync](kubermatic-addons/custom-addon/ntp-sync)                              | DaemonSet to execute `ntpdate primary secondary` scheduled on every node of a cluster                                                                                                                                                                       |
| [custom-addon/docker-pull](kubermatic-addons/custom-addon/docker-pre-pull)                    | DaemonSet to pull e.g. `docker.io` based images on every node with a docker-secret, to prevent rate-limited infrastructure pods.                                                                                                                            |
| [custom-addon/flux2](kubermatic-addons/custom-addon/flux2)                                    | Deploys [Flux](https://github.com/fluxcd/flux2/) for keeping your Kubernetes clusters in sync with sources of configuration (like Git repositories).                                                                                                        |
| [custom-addon/argocd](kubermatic-addons/custom-addon/argocd)                                  | Deploys [ArgoCD](https://github.com/argoproj/argo-cd/) - a declarative, GitOps continuous delivery tool for Kubernetes (as high availability installation).                                                                                                 |
| ------- ARCHIVED ---                                                                          |                                                                                                                                                                                                                                                             |
| [custom-addon/helm-operator](kubermatic-addons/custom-addon/helm-operator)                    | Deploys the [FluxCD - Helm Operator](https://github.com/fluxcd/helm-operator) for managing additional deployment trough Helm by CRD                                                                                                                         |
| [custom-addon/loki-stack](kubermatic-addons/custom-addon/loki-stack)                          | (Requires Helm Operator) Add Grafana Loki stack based on [Grafana Loki Charts](https://grafana.github.io/loki/charts)                                                                                                                                       |
| [custom-addon/theia-ide](kubermatic-addons/custom-addon/theia-ide)                            | Customized KKP addon for quickly using [Eclipse Theia IDE](https://theia-ide.org/) at your Kubernetes cluster.                                                                                                                                              |
| [custom-addon/metallb](kubermatic-addons/custom-addon/metallb)                                | MetalLB cluster addon for on-premise user cluster without native LB support                                                                                                                                                                                 |
| [custom-addon/metallb-v2](kubermatic-addons/custom-addon/metallb-v2)                          | [MetalLB](https://metallb.universe.tf) cluster addon for on-premise user cluster without native LB support - with advanced config options, see [MetalLB - Configuration](https://metallb.universe.tf/configuration). Used if IP range config is not enough. |
| [custom-addon/archive/kube-proxy-ipvs-patch](kubermatic-addons/archive/kube-proxy-ipvs-patch) | Custom overwrite Addon to patch IPVS mode to `strictARP: true`.                                                                                                                                                                                             |

## Kubermatic Applications

Configuration and tooling for common
used [KKP - Guides - Application](https://docs.kubermatic.com/kubermatic/main/tutorials-howtos/applications/) for user cluster
customization.

| Name                                                                | Description                                               |
|---------------------------------------------------------------------|-----------------------------------------------------------|
| [README.md - Values](kubermatic-applications/README.md)             | Sample values yaml for the Applications                   |
| [argocd-app](kubermatic-applications/argocd-app.yaml)               | Argo CD - Declarative Continuous Delivery for Kubernetes. |
| [echoserver-app](kubermatic-applications/echoserver-app.yaml)       | Echo Server Example App                                   |
| [eclipse-che-app](kubermatic-applications/eclipse-che-app.yaml)     | Preconfigured Eclipse Che IDE App                         |
| [flux2-app](kubermatic-applications/flux2-app.yaml)                 | Flux GitOps sync tool for application deployment          |
| [harbor-app](kubermatic-applications/harbor-app.yaml)               | Harbor App for user Clusters                              |
| [sysdig-secure-app](kubermatic-applications/sysdig-secure-app.yaml) | [Sysdig Secure](https://sysdig.com/products/secure/) Integration for KKP User Clusters       |
| [hivemq-app](kubermatic-applications/hivemq-app.yaml)               | HiveMQ Operator App to manage HiveMQ clusters in KKP user clusters                           |

## Containers
Some useful containers to work with KubeOne and KKP

| Name                                                       | Description                                                                                                              |
|------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| [kubeone-tool-container](container/kubeone-tool-container) | A docker container with various tools to work with KubeOne and Kubernetes                                                |
| [kubermatic-dev-ui](container/kubermatic-dev-ui)           | Complete DEV UI Container including KubeOne and various tools to work with KubeOne, KKP and Kubernetes via a Frontend UI |

## Helper

List of helper scripts and tools

| Name                                                                                            | Description                                                                                                                                                                                                      |
|-------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [git-crypt](./helper/git-crypt)                                                                 | [git-crypt](https://github.com/AGWA/git-crypt) is a tooling to encrypt git repositories based GPG keys                                                                                                           |
| [kubeone-makefile](helper/kubeone-makefile/Makefile)                                            | Contains a template `Makefile` to manage KubeOne deployments                                                                                                                                                     |
| [kubermatic-installer-script](helper/kubermatic-installer-script)                               | Contains a standalone usage of [kubermatic - deploy.sh](https://github.com/kubermatic/kubermatic/blob/master/hack/ci/deploy.sh) repo installation script for own installations.                                  |
| [kubermatic-makefile](helper/kubermatic-makefile/Makefile)                                      | Contains a template `Makefile` to manage kubermatic deployments                                                                                                                                                  |
| [ssh-debug](helper/ssh-debug)                                                                   | SSH Debug Client for quickly ssh to nodes in an internal network                                                                                                                                                 |
| [vault/vault-k8s-mapper](helper/vault/vault-k8s-mapper)                                         | Maps Vault secret as native Kubernetes secret into a defined namespace/secret.                                                                                                                                   |
| [vault/vault-kv-management.sh](helper/vault/vault-kv-management.sh)                             | Management script to up/download secrets to a vault secret kv store.                                                                                                                                             |
| [delete-evicted-pods-all-ns.sh](helper/delete-evicted-pods-all-ns.sh)                           | Deletes pods in state `evicted`                                                                                                                                                                                  |
| [headless.vnc.test.container.yaml](helper/headless.vnc.test.container.yaml)                     | [docker-headless-vnc-container](https://github.com/ConSol/docker-headless-vnc-container) container containing Linux UI exposed via webvnc for testing e.g. dashboards from internal cluster view                 |
| [kill-kube-ns.sh](helper/kill-kube-ns.sh)                                                       | kills a pending kubernetes namespace                                                                                                                                                                             |
| [kubeconfig-kubermatic-serviceaccount.sh](/helper/kubeconfig-kubermatic-serviceaccount.sh)      | creates an `kubermatic` service account at an seed cluster                                                                                                                                                       |
| [machinedeployment-patch.gce.sh](helper/machinedeployment-patch.gce.sh)                         | Scripts patches some specification of an Cluster API `MachineDeployment` object.                                                                                                                                 |
| [set-build-tags-to-image.sh](helper/set-build-tags-to-image.sh)                                 | Set dedicated build tags to the [Kubermatic Charts](https://github.com/kubermatic/kubermatic/tree/master/charts)                                                                                                 |
| [untaint_master.sh](helper/untaint_master.sh)                                                   | untaints all master nodes, to be able to schedule workload                                                                                                                                                       |
| [bash-port-scanner.sh](helper/linux-port-scan-without-dependencies/scan.sh)                     | A Bash bases Port-Scanner which is able to scan ports without any dependencies or tools like nmap                                                                                                                |
| [pvc.test.yaml](helper/pvc.test.yaml)                                                           | small pod + pvc to test if storage provisioning works                                                                                                                                                            |
| [refresh-all-service-accounts-in-cluster.sh](helper/refresh-all-service-accounts-in-cluster.sh) | script to refresh all service accounts token (stored as secrets) and restart dependent pods semi-automatic                                                                                                       |
| [local-connect-k8s-services.sh](helper/local-connect-k8s-services.sh)                           | A small helper script to `kubectl port-forward` a handful of service, in the example the typical MLA services `prometheus`, `grafana`, `alertmanager`                                                            |
| [ssh-jumphosts-template.sh](helper/ssh-jumphosts-template.sh)                                   | Template to create a jumphost script with predefined enviroments.                                                                                                                                                |
| [Infrastructure benchmarking](helper/benchmarking)                                              | Documentation on how to benchmark various infrastrucutre elements used for hosting a kubernetes cluster.                                                                                                         |


## Knowledge Base

Helpful how-tos and detailed documentation:

| Name                                                                                        | Description                                                                                                                                 |
|---------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| [setup-checklist/kkp](./knowledge-base/setup-checklist/kkp)                                 | Detailed requirement documentation to setup Kubermatic KKP at different environments                                                        |
| [setup-checklist/kubeone](./knowledge-base/setup-checklist/kubeone)                         | Detailed requirement documentation to setup KubeOne at different environments                                                               |
| [how-to-convert-to-docx](./knowledge-base/how-to-convert-to-docx.md)                        | Commands to convert markdown to docx                                                                                                        |
| [migrate-helm2-to-helm3](./knowledge-base/migrate-helm2-to-helm3.md)                        | This document shows you how to migrate Heml releases from using Helm version 2.x with Tiller to being managed by Helm version 3.x in place. |
| [node-health-check](knowledge-base/node-health-check.md)                                    | This doc describes how Kubermatic node health checks works                                                                                  |
| [nvidia-gpu-operator](knowledge-base/nvidia-gpu-operator.md)                                | How to enable GPU support for KKP clusters by [NVIDIA - GPU Operator](https://github.com/NVIDIA/gpu-operator/)                              |
| [offline-setup](knowledge-base/offline-setup.md)                                            | How to run kubermatic in offline environments                                                                                               |
| [upload-ova-with-govc](knowledge-base/upload-ova-with-govc.md)                              | How to upload ova by using `govc`                                                                                                           |
| [how-to-collect-cluster-cpu-memory.md](knowledge-base/how-to-collect-cluster-cpu-memory.md) | How to collect the provisioned CPU/Memory of Kubernetes Clusters                                                                            |

## Runbook

Guides how to operate KubeOne / KKP.

| Name                                                                                                                      | Description                                                           |
|---------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------|
| [metallb-service-connection-drops-ipvs-strict-arp](./runbook/metallb/metallb-service-connection-drops-ipvs-strict-arp.md) | Connection Drops of Service Type LoadBalancer provided by MetalLB.    |
| [user-cluster-prometheus.md](./runbook/user-cluster-prometheus.md)                                                        | Crash Looping Prometheus at KKP user cluster namespace                |
| [manual-backup](./runbook/manual-backup.md)                                                                               | How to create manual backup for your KKP/KubeOne setup.               |
| [k8s-kubeconfig-expiring-failure.md](./runbook/k8s-kubeconfig-expiring-failure.md)                                        | Expiring `kubeconfig` client certificate (at KubeOne Cluster example) |

## Troubleshooting

If you encounter issues [file an issue][1] or talk to us on the [#kubermatic channel][12] on the [Kubermatic Slack][15].

## Contributing

Thanks for taking the time to join our community and start contributing!

Feedback and discussion are available on [#kubermatic channel][12].

### Before you start

* Please familiarize yourself with the [Code of Conduct][4] before contributing.
* See [CONTRIBUTING.md][2] for instructions on the developer certificate of origin that we require.

### Pull requests

* We welcome pull requests. Feel free to dig through the [issues][1] and jump in.

## Changelog

See [the list of releases][3] to find out about feature changes.

[1]: https://github.com/kubermatic-labs/community-components/issues

[2]: https://github.com/kubermatic-labs/community-components/blob/master/CONTRIBUTING.md

[3]: https://github.com/kubermatic-labs/community-components/releases

[4]: https://github.com/kubermatic-labs/community-components/blob/master/CODE_OF_CONDUCT.md

[11]: https://groups.google.com/forum/#!forum/kubermatic-dev

[12]: https://kubermatic.slack.com/messages/kubermatic

[13]: https://github.com/kubermatic-labs/community-components/blob/master/Zenhub.md

[15]: http://slack.kubermatic.io/
