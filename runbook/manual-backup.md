# Runbook - Create Manual Backup

## Master / Seed setup (based one KubeOne)

For some cases like upgrades, KKP operators want to create manual backups and store it for safety reason at e.g. your local system.

1. Check if KubeOne has a backup deployed, in our case the [KubeOne Restic Addon](https://docs.kubermatic.com/kubeone/master/examples/addons_backup/):

```bash
 kubectl get cronjobs.batch 
NAME                     SCHEDULE     SUSPEND   ACTIVE   LAST SCHEDULE   AGE
etcd-backup-cq4ktccp6g   @every 20m   False     0        8m41s           30d
etcd-backup-hpfp6lzp9n   @every 20m   False     0        4m30s           45d
etcd-backup-k4ptxg58jl   @every 20m   False     0        8m1s            81d
etcd-backup-r5q866mcsx   @every 20m   False     0        14m             38d
etcd-backup-vq55m6kk8l   @every 20m   False     0        42s             24d
etcd-s3-backup           @every 30m   False     0        16m             3d7h
```
The target job for the master/seed etcd backup is `etcd-s3-backup`.

2. Create a manual triggered updated
```bash
kubectl -n kube-system create job --from cronjob/etcd-s3-backup manual-master-backup
```

3. Now check your target location and create a local copy:
```bash
kubectl get cronjobs.batch etcd-s3-backup -o yaml | grep -C 2 RESTIC_REPO
```
In our case it's the local minio deployed by KKP:
```yaml
        apiVersion: v1
        fieldPath: spec.nodeName
  - name: RESTIC_REPOSITORY
    value: s3:http://minio.minio.svc.cluster.local:9000/kubermatic-master-backups
  - name: RESTIC_PASSWORD
```
4. Connect to the Minio service by port-forward to access the Storage by localhost:
```bash
kubectl port-forward -n minio minio-54dcf47d46-6ztjz 9000:9000
```
check connection:
```bash
curl localhost:9000
```
```
<?xml version="1.0" encoding="UTF-8"?>
<Error><Code>AccessDenied</Code><Message>Access Denied.</Message><Resource>/</Resource><RequestId>1685A6A552786ABC</RequestId><HostId>68860d39-5abd-4b0d-8c75-218bc787cdd7</HostId></Error>
```
Now you can connect also through your browser if you visit: http://localhost:9000
To find the credentials:
- Ideally take a look at your `values.yaml` - `minio.credentials.accessKey`, `minio.credentials.secretKey`
- Alternative check secret `kubectl get secrets s3-credentials -o yaml` and decode the base64 encoded values `echo <value> | base64 -d`

5. Create a local copy with [`mc` client](https://docs.min.io/docs/minio-client-complete-guide.html):
```bash
# start your local mc shell
docker run -it --network host --entrypoint bash -v $(pwd):/data minio/mc

# configure minio location
mc alias set minio http://localhost:9000 <<ACCESS_KEY>> <<SECRET_KEY>> --api S3v4

# list buckets
mc ls minio
[2021-02-18 18:16:57 UTC]     0B kubermatic-etcd-backups/
[2021-06-01 22:48:18 UTC]     0B kubermatic-master-backups/
```
Sync now the bucket `kubermatic-master-backups` bucket to your local drive. Your starting local folder has been already mounted into the container by `-v $(pwd):/data minio/mc`:

```bash
mkdir /data/backup-master
mc mirror minio/kubermatic-master-backups /data/backup-master

# change the permission to your local user:  id -u
chown -R 1000:1000 /data/*
```
The copy of restic based backup under your folder `./backup-master` can now get used by the kubeone restore procedure if needed, see [KubeOne Manual Cluster Recovery](https://docs.kubermatic.com/kubeone/master/guides/manual_cluster_recovery/) 

**Alternatives to get the Snapshot etcd backup**:
- k cp
- docker
- file mount at master
