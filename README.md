## Overview
This repository serves as an entry-point for multiple community-maintained components in the Kubermatic ecosystem. Feedback is highly encouraged 👍 

## Components
Dedicated components for customer purposes. 

Name|Description
---|---
[packer-ubuntu1804-vsphere-template](./components/packer-ubuntu1804-vsphere-template)|A packer template to customize an ubuntu 18.04 cloud-image on vSphere

## Helper
List of helper scripts and tools

Name|Description
---|---
[git-crypt](./helper/git-crypt)| [git-crypt](https://github.com/AGWA/git-crypt) is a tooling to encrypt git repositories based GPG keys
[kubeone-tool-container](./components/kubeone-tool-container)|A docker container with various tools to work with KubeOne and Kubernetes
[kubermatic-installer-script](helper/kubermatic-installer-script) | Contains a standalone usage of [kubermatic - deploy.sh](https://github.com/kubermatic/kubermatic/blob/master/hack/ci/deploy.sh) repo installation script for own installations.
[ssh-debug](helper/ssh-debug) | SSH Debug Client for quickly ssh to nodes in an internal network
[vault-k8s-mapper](helper/vault-k8s-mapper) | Maps Vault secret as native Kubernetes secret into a defined namespace/secret.
[delete-evicted-pods-all-ns.sh](helper/delete-evicted-pods-all-ns.sh) | Deletes pods in state `evicted` 
[headless.vnc.test.container.yaml](helper/headless.vnc.test.container.yaml) | [docker-headless-vnc-container](https://github.com/ConSol/docker-headless-vnc-container) container containing Linux UI exposed via webvnc for testing e.g. dashboards from internal cluster view 
[kill-kube-ns.sh](helper/kill-kube-ns.sh) | kills a pending kubernetes namespace
[kubeconfig-kubermatic-serviceaccount.sh](/helper/kubeconfig-kubermatic-serviceaccount.sh) | creates an `kubermatic` service account at an seed cluster
[machinedeployment-patch.gce.sh](helper/machinedeployment-patch.gce.sh) | Scripts patches some specification of an Cluster API `MachineDeployment` object.
[set-build-tags-to-image.sh](helper/set-build-tags-to-image.sh) | Set dedicated build tags to the [Kubermatic Charts](https://github.com/kubermatic/kubermatic/tree/master/charts)
[untaint_master.sh](helper/untaint_master.sh) | untaints all master nodes, to be able to schedule workload

## Knowledge Base
Helpful how-tos and detailed documentation:

Name | Description
--- | ---
[setup-checklist](./knowledge-base/setup-checklist) | Detailed requirement documentation to setup kubermatic at different environments
[how-to-convert-to-docx](./knowledge-base/how-to-convert-to-docx.md) | Commands to convert markdown to docx
[migrate-helm2-to-helm3](./knowledge-base/migrate-helm2-to-helm3.md) | This document shows you how to migrate Heml releases from using Helm version 2.x with Tiller to being managed by Helm version 3.x in place.
[node-health-check](knowledge-base/node-health-check.md)| This doc describes how Kubermatic node health checks works
[offline-setup](knowledge-base/offline-setup.md) | How to run kubermatic in offline environments

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