# Cluster management for KKP with Cluster CRDs

Basically in this example we show, how to manage cluster by using something like `kubectl -f cluster.yaml` to have declarative management of Cluster.

***IMPORTANT NOTE:***

**Currently, it's required to use the `kubectl` command against the responsible seed cluster, what does** ***NOT SUPPORT MULTI TENANT*** **access. In newer KKP version, we try to solve these restrictions!**

For a more git-ops declarative way with multi-tenant, check the [KKP Rest-API](https://docs.kubermatic.com/kubermatic/main/references/rest-api-reference/) and your [terraform-kkp-cluster-provider](../terraform-kkp-cluster-provider/README.md).

## Cluster CRD
At KKP you could manage your clusters with a `cluster` object. But this cluster object lives in the seed, where you need access. Additional to the `cluster` object, you will need also a `machinedeployment` to create nodes. This can be done via the `kubermatic.io/initial-machinedeployment-request` annotation or as a separate step after the cluster is created.

More information about the specs, you find at:
* [KKP Docs > Kubermatic CRD Reference](https://docs.kubermatic.com/kubermatic/main/references/crds/)
  * [`Cluster`](https://docs.kubermatic.com/kubermatic/main/references/crds/#cluster)
* [MachineController > MachineDeployment Examples](https://github.com/kubermatic/machine-controller/tree/main/examples)

### Example Apply a Cluster

*TODO add diagramm picture*

**Note: Expect the values of [`./cluster/*.yaml`](./cluster) files have been adjusted**
```bash
# connect to target seed
export KUBECONFIG=seed-cluster-kubeconfig

# add credentials as secret to kubermatic namespace
kubectl apply -f cluster/00_secret.credentials.example.yaml

# create cluster with initial machine deployment
kubectl apply -f cluster/10_cluster.spec.vsphere.example.yaml

#... check status of cluster creation
kubectl get cluster xxx-crd-cluster-id

# extract kubeconfig secret from cluster namespace
kubectl get cluster xxx-crd-cluster-id -o yaml | grep namespaceName
kubectl get secrets/admin-kubeconfig -n cluster-xxx-crd-cluster-id --template={{.data.kubeconfig}} | base64 -d > cluster/cluster-xxx-crd-cluster-id-kubeconfig

# now connect and check if you get access
export KUBECONFIG=cluster/cluster-xxx-crd-cluster-id-kubeconfig
kubectl get pods -A
# after some provisioning time you should also see machines
kubectl get md,ms,ma,node -A

# As example for machine management add an extra node 
# (or if non intial machines get applied, manage nodes only via the machinedeployment.yaml, and remove the 'kubermatic.io/initial-machinedeployment-request' annotation)
kubectl apply -f cluster/20_machinedeployment.spec.vsphere.example.yaml 
# now you should additional machine-deployments created
kubectl get md,ms,ma,node -A
```
If you want to delete the cluster, it's enough to delete it via the ID:
```bash
export KUBECONFIG=seed-cluster-kubeconfig
kubectl delete cluster xxx-crd-cluster-id

### will also work
kubectl delete -f cluster/10_cluster.spec.vsphere.example.yaml
```

### Workflow to create `cluster.yaml`
1. Create Cluster via UI
2. Extract Cluster values and remove the metadata:
```bash
export KUBECONFIG=seed-cluster-kubeconfig
mkdir -p my-cluster/.original
kubectl get cluster xxxxxxx -o yaml > my-cluster/.original/mycluster.spec.original.yaml
kubectl get cluster xxxxxxx -o yaml | kubectl-neat > my-cluster/mycluster.spec.yaml
```
3. Check the diff between the two yamls and compare it with given example diffs
```bash
#changes of the example
diff cluster/10_cluster.spec.vsphere.example.yaml cluster/.original/cluster.spec.original.yaml

#diff between your new and the example spec
diff cluster/10_cluster.spec.vsphere.example.yaml my-cluster/mycluster.spec.yaml 
```
4. Ensure Parameters are matching. Somehow you need to ensure matching values of:
   * Project ID ``: Secrets, Labels, MachineDeployments
   * Cloud Provider Credentials and Specs
     * vsphere: folder path


## Clustertemplate Management

Another option is to manage the [`ClusterTempalte`](https://docs.kubermatic.com/kubermatic/v2.23/references/crds/#clustertemplate) object. Therefore, a non initialized template get created and separate instance object creates a copy of it. **BUT** any change to the clustertempalte will **NOT** get applied to the instance.
```bash
# connect to target seed
export KUBECONFIG=seed-cluster-kubeconfig

# add credential preset as secret to kubermatic namespace
kubectl apply -f cluster/00_secret.credentials.example.yaml

# create the template
kubectl apply -f clustertemplate/clustertemplate.vsphere-cluster-mla.yaml 

# create cluster as a "copy" of the template
kubectl apply -f clustertemplate/clustertemplateinstance.vsphere.example.yaml 

# check the creates instances
kubectl get clustertemplate,clustertemplateinstance,cluster
```
