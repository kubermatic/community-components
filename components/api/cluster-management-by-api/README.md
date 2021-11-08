# Cluster Provisioning by API

In the following repo you find an example how to manage your KKP user clusters by using the KKP API. For easy start how the scripts works, take a look into the example [`example-run-env`](./example-run-env) folder. 
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
- Terraform Provider: https://github.com/kubermatic/terraform-provider-kubermatic/blob/master/kubermatic/resource_cluster.go
- CLI `kkpctl`
  - [Blog: KKPCTL: The Command Line Tool for Kubermatic Kubernetes Platform](https://www.kubermatic.com/blog/kkpctl-the-command-line-tool-for-kubermatic-kubernetes-platform/)
  - [Github: cedi/kkpctl](https://github.com/cedi/kkpctl)


## Planned Improvements:
- https://github.com/kubermatic/kubermatic/issues/6414
  - Service Account API v2 (personalized access)
  - Manage User Cluster by Cluster Objects (end user facing)
- Feature Complete Terraform provider

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
