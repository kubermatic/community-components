# How to migrate MinIO storage
https://docs.kubermatic.com/kubermatic/v2.23/installation/upgrading/upgrade-from-2.22-to-2.23/#minio-upgrade

## boot new deployment

Get the deployment, svc, and pvc yaml files
```bash
kubectl -n minio get deployments.apps minio -o yaml > deployment.yaml
kubectl -n minio get svc minio -o yaml > svc.yaml
kubectl -n minio get pvc minio-data -o yaml > pvc.yaml
```
Change the name of the deployment, pod spec and pvc to minio-new
But don't change the namespace!

apply them:
```bash
kubectl -n minio apply -f deployment.yaml
kubectl -n minio apply -f svc.yaml
kubectl -n minio apply -f pvc.yaml
```

## Start debug container on cluster
e.g. busybox, then install mc cli

```bash
kubectl run busybox --image busybox -it --rm -- sh
```

```bash
curl https://dl.min.io/client/mc/release/linux-amd64/mc \
  --create-dirs \
  -o $HOME/minio-binaries/mc

chmod +x $HOME/minio-binaries/mc
export PATH=$PATH:$HOME/minio-binaries/

mc --help
```

## Setup alias

```bash
mc alias set ALIAS http://minio:9000 <access-key> <access-secret>
mc alias set ALIAS-NEW http://minio-new:9000 <access-key> <access-secret>
```

## Transfer config according to MinIO docs

```bash
mc admin config export ALIAS > config.txt
mc admin config import ALIAS-NEW < config.txt
mc admin service restart ALIAS-NEW
mc admin cluster bucket export ALIAS-NEW
mc admin cluster bucket import ALIAS-NEW ALIAS-NEW-bucket-metadata.zip
```


## Copy data
```bash
mc mirror --preserve --watch ALIAS ALIAS-NEW
```
This will take a while and never stop, since it waits for new data to be copied. Cancel it with ctrl+c.

Make sure that the data is copied correctly.
```
mc du ALIAS
mc du ALIAS-NEW
```
Both needs to be the same.


## Scale down both deployments
```bash
kubectl -n minio scale deployment minio --replicas=0
kubectl -n minio scale deployment minio-new --replicas=0
```

## delete old pvc
```bash
kubectl -n minio delete pvc minio-data
```

## Delete old, Rename new pvc

Use https://github.com/stackitcloud/rename-pvc

```bash
kubectl -n minio delete pvc minio-data
kubectl -n minio rename-pvc minio-data-new minio-data
```

## Change release of deployment
```bash
kubectl -n minio edit deployment minio
```

## Scale up old deployment
```bash
kubectl -n minio scale deployment minio --replicas=1
```

## Delete new deployment
```bash
kubectl -n minio delete deployment minio-new
kubectl -n minio delete svc minio-new
```
