# KKP installation files

Many of the files within this directory are not versioned since they are either downloaded or generated and contain secrets.
The `kkp-apply` target of the `Makefile` within the repo's root directory downloads and prepares those files:
* `release`: This directory contains the KKP release(s), one sub directory per release.
* `password`: The generated admin password. You can edit the file to set a custom password but you have to re-install KKP afterwards.
* `values.yaml`: The Helm values file provided to the KKP installer.
* `kubermatic.yaml`: The KubermaticConfiguration object.

The KKP installation documentation can be found [here](https://docs.kubermatic.com/kubermatic/v2.29/installation/install-kkp-ce/).
