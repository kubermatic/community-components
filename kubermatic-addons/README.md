## Kubermatic add-on image

- Kubermatic Doc: https://docs.kubermatic.io/advanced/addons/

**add new addon**
1. add or modify addons and tag in [`Dockerfile`](Dockerfile) and [`Dockerfile.openshift`](Dockerfile.openshift)
1. Create selectable config file 
1. Document the scope of the add-on in the README

**new release**
1. update `KUBERMATIC_VERSION` variable in [`Makefile`](Makefile) or use ovewrite the value by setting the environment variable from the outside 
    ```
    make docker-release
    ```
1. update image tag in `values.yaml` or kubermatic config CRD
