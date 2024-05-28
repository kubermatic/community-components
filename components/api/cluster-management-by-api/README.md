# Cluster Provisioning by API via Bash/Curl

In the following folders, you find an example how to manage your KKP user clusters by using the KKP API.

## Architecture

Using the given example inside of any GitOps Tooling, the following workflow is given:

![KKP REST-API via Bash/Curl Architecture Overview](../.assets/kkp-rest-api-bash-arch.drawio.png)
> Image Source: local [kkp-rest-API-Terraform-Cluster-CRD-Architecture-Drawing.drawio.xml](../.assets/kkp-rest-API-Terraform-Cluster-CRD-Architecture-Drawing.drawio.xml) or [Google Drive](https://drive.google.com/file/d/1G8-AerEndAkR17ON4DOIrOAb_-OxEVnH/view?usp=sharing)

1) Use Authentication Token provided by the [KKP Service Accounts](https://docs.kubermatic.com/kubermatic/main/architecture/concept/kkp-concepts/service-account/using-service-account/)
2) Talk to the [KKP Rest API](https://docs.kubermatic.com/kubermatic/main/references/rest-api-reference/) with the given payload, what have been rendered by the terraform module
3) Kubermatic API transfers the API JSON payload to [Cluster](https://docs.kubermatic.com/kubermatic/main/references/crds/#cluster) object and applies it against the matching Seed Cluster Kubernetes API endpoint.
4) Seed Controller Managers use the [ClusterSpec](https://docs.kubermatic.com/kubermatic/main/references/crds/#clusterspec) and create the necessary specs for the Control Plan creation of a [KP user cluster](https://docs.kubermatic.com/kubermatic/main/architecture/#user-cluster)
5) Containerized Control Plane objects spins up (Deployments & StatefulSets) and seed controller manager creates necessary external cloud provider resources (e.g., a security group at the external cloud).

## Example
For easy start how the scripts works, take a look into the example [`example-run-env`](./example-run-env) folder. 
```bash
cd example-run-env
make help 
```
```
The makefile manage the different operations to the KKP API.
Please ensure your correct configured .kkp-env.sh
Therefore you can find the following operations:
usage: ENV=val make TARGET

[CLUSTER_SPEC=vsphere] make apply-cluster:
  applies cluster spec over the KKP API

make apply-all-clusters:
  executes make apply-cluster on all directories at the current location of the Makefile

CLUSTER_ID=xxxxx make apply-machine-deployment:
  applies machine deployment spec over the KKP API to a existing cluster

CLUSTER_ID=xxxxx make delete-cluster:
  delete cluster with specific cluster id

make delete-all-cluster:
  delete all clusters in specified project

make help:
  print help
```

## Relevant KKP Documentation:
- Rest-API: `/rest-api`
- Swagger JSON: `/api/swagger.json`
- Service Accounts for API: [KKP Docu: Guides > Service Accounts](https://docs.kubermatic.com/kubermatic/master/guides/service_account/)
  - [Using Service Accounts](https://docs.kubermatic.com/kubermatic/master/guides/service_account/using_service_account/)

Examples of API Usage:
- E2E Tests: https://github.com/kubermatic/kubermatic/blob/master/pkg/test/e2e/utils/client.go#L454 
- [Terraform REST API Provider](../terraform-kkp-cluster-provider/README.md)
- [Kubermatic Go library](https://github.com/kubermatic/go-kubermatic)
- Terraform Provider c: https://github.com/kubermatic/terraform-provider-kubermatic/blob/master/kubermatic/resource_cluster.go
- CLI `kkpctl` kkp-rest-api-terraform-provider-arch
  - [Blog: KKPCTL: The Command Line Tool for Kubermatic Kubernetes Platform](https://www.kubermatic.com/blog/kkpctl-the-command-line-tool-for-kubermatic-kubernetes-platform/)
  - [Github: cedi/kkpctl](https://github.com/cedi/kkpctl)

## Planned Improvements:
- https://github.com/kubermatic/kubermatic/issues/6414
  - Service Account API v2 (personalized access)
  - Manage User Cluster by Cluster Objects (end user facing)

## Declarative Stable API Objects
- JSON: Every support call from the KKP Rest API [REST-API Reference](https://docs.kubermatic.com/kubermatic/master/references/rest_api_reference/)
- YAML: Currently not all objects are manageable over YAML, but future improvement is planed. The following objects are stable to use: 
  - User Cluster - Machine Objects
    ```
    MachineDeployment
    MachineSet
    Machine
    ```
  - Management Objects
    ```
    AddonConfig
    ClusterTemplate
    ConstraintTemplate
    EtcdBackupConfig
    KubermaticConfiguration
    KubermaticSetting
    Preset
    Project
    Seed
    ```
