## Kubermatic add-on image

- Kubermatic Doc: https://docs.kubermatic.com/kubermatic/master/guides/addons/

**add new addon**
1. add or modify addons and tag in [`Dockerfile`](Dockerfile)
1. Create selectable config file 
1. Document the scope of the add-on in the README

**new release**
1. Update in [`Makefile`](Makefile) before execution, configure the variable or use overwrite the value by setting the environment variable from the outside
     * update `KUBERMATIC_VERSION` at a new KKP release 
     * For Addon Only updated `TAG_POST_FIX` 
    ```
    make docker-release
    ```
1. update image tag in `values.yaml` or `KubermaticConfiguration` object at your KKP setup files

For more information see: [KKP - Guides - Addon](https://docs.kubermatic.com/kubermatic/master/guides/addons/)
