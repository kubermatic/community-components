# Scale Down

Manifests and scripts in this directory help with running a cron job that scales
down worker nodes during non work hours and weekends.

## Development

These scripts were written as part of the MELLODDY project. Before being used in a different context one would probably need to edit the file somewhat. For example, change the `labels` used to filter `deployment` objects before deciding if a scale down operation is safe to proceed or not.

## Installation

Place the files on the pharma console VM.

```
scp scale-down scale-down.yaml kubeone@<PHARMA_CONSLE>
```

Login to the console VM and run the following commands.

### Create the configmap

```
# export KUBECONFIG.
kubectl create ns cron-scaler
kubectl create configmap scale-down --from-file=./scale-down.sh -n cron-scaler
```

### Apply the manifest

```
kubectl apply -f scale-down.yaml
```

## About the scaler

It runs hourly between 4pm to 6am UTC everyday. That is from 6pm to 8am CEST
(March-October) and from 5pm to 7am CET (October-March).

The pods created from the cron job will only run on control plane nodes.

### Stopping downscaling

The worker nodes will **NOT** be scaled down if any `deployment` object across any namespace has at least one of the following labels:

- `app.kubernetes.io/name: substra-backend-server`
- `app.kubernetes.io/part-of: substra-backend`

Remove the above labels from all deployments for the future down scaling operations to become active.

Additionally, if any `machinedeployment` object has the following label, it will not be scaled down:

- `cluster-cleanup: false`

But any other `machinedeployment` without this label **WILL BE** scaled down to `0` replicas.

To scale down all worker nodes, make sure no `machinedeployment` object has the above label set.

### Scaling up

To scale up, get the current `machinedeployment` objects. For example:

```
$ kubectl get md -n kube-system
NAME                              REPLICAS   AVAILABLE-REPLICAS   PROVIDER   OS       KUBELET   AGE
flextest-pharma-test-eu-west-1b   0                               aws        ubuntu   1.16.1    28h
flextest-pharma-test-eu-west-1c   0                               aws        ubuntu   1.16.1    28h
```

And run:

```
kubectl scale md -n kube-system md flextest-pharma-test-eu-west-1b --replicas=1
```

This will create one new worker node.

### Manually scaling down

To manually scale down a `machinedeployment`, run the following for example:

```
kubectl scale md -n kube-system md flextest-pharma-test-eu-west-1b --replicas=0
```

### Disabling the scaler

To disable the scaler completely, run:

```
kubectl label md -n kube-system flextest-pharma-test-eu-west-1b cluster-cleanup=false
```

This will stop any scaling down operations for that `machinedeployment` object. Run the command for each `machinedeployment` object as required.

### Enabling the scaler

To enable the scaler again run:

```
kubectl label md -n kube-system flextest-pharma-test-eu-west-1b cluster-cleanup=true
```

This will resume scaling down operations for that `machinedeployment` object. Run the command for each `machinedeployment` object as required.
