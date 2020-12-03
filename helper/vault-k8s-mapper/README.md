# Vault k8s manual secret mapper

Maps Vault secret as native Kubernetes secret into a defined namespace/secret.

## What to do:

### payload/
=======
- Log into the docker registry of your choice
- Run `make image`

### chart/

- Allow the secret mapper to access the vault:
  - Create the policy `<namespace>` inside the vault.:
    ``` hcl
    path "<namespace>/*" {
        capabilities = ["read"]
    }
    ```
  - Execute `vault write auth/kubernetes/role/<namespace> bound_service_account_names=mapsecrets bound_service_account_namespaces=<namespace> policies=<namespace>`.
- Configure with `values.yaml`
- Log into the cluster and select the target namespace.
- Run `helm install mapsecrets .`
