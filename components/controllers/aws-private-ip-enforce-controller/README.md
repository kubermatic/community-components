# Enforce private IP controller

This bash-controller watches over the MachineDeployments objects in user and seed cluster. It enforces the flag `.spec.template.spec.providerSpec.value.cloudProviderSpec.assignPublicIP` to `false`:

**seed cluster scope: [`aws-priv-ip-seed-cluster-controller-deployment.yaml`](aws-priv-ip-seed-cluster-controller-deployment.yaml)**

The controller runs in the `kubermatic` namespace and watches over all `machinedeployments` and enforces to setting of `assignPublicIP` to `false`. The controller is a workaround for https://github.com/kubermatic/kubeone/issues/635

**user cluster scope: [`aws-priv-ip-usercluster-controller-deployment.yaml`](aws-priv-ip-usercluster-controller-deployment.yaml)**

This controller also runs in the seed cluster, namespace `kube-system`, but is watching over all `machinedeployments` of every user `cluster` object and enforces inside of the user cluster the setting of `assignPublicIP` to `false`. The controllers is a workaround until https://github.com/kubermatic/kubermatic/issues/4155 is implemented