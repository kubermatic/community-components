# How to run kubermatic in offline environments
Date: 2020-05-13

## Create master cluster with k1

- Configure your distribution to use a package mirror that provides the official docker and kubernetes packages.
  You can realize that with apt-mirror, artifactory, squid or many others
- Integrate this in the image templates that will be used by k1 for the control plane and by machine controller
  for workers.
- Populate the K1 config as usual, but include the following setting, which instructs k1 not the mess with the
  package sources:
```
systemPackages:
  configureRepositories: no
```
- Execute `kubeone install`.

## Kubermatic

- Use either a docker registry that contains all the images kubermatic needs or mirror the docker hub repo, 
  quay and gcr. Can be seperate logical registries or some subpaths of a single one.
- Fetch the kubermatic-installer repo. 
- Edit the values.yaml and replace all the 50 image definitions with the ones that are specific to the registry.
  That sucks but there is not really a generic way to automate that.
- Install kubermatic as usual

