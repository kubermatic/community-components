# How to get latest backups

## Set restic envs
export AWS_DEFAULT_REGION="eu-central-1"
export RESTIC_REPOSITORY="s3:http://127.0.0.1:9000/kubermatic-master-backups"
export AWS_ACCESS_KEY_ID="<look at minio section in values.yaml>"
export AWS_SECRET_ACCESS_KEY="<look at minio section in values.yaml>"
export RESTIC_PASSWORD="vjTkgmX6inho"


## Port forward minio
kubectl -n minio port-forward deployment/minio 9000:9000

## Locate latest snapshot
restic snapshots -r s3:http://127.0.0.1:9000/kubermatic-master-backups --verbose

## Unlock repo if needed
restic unlock -r s3:http://127.0.0.1:9000/kubermatic-master-backups --remove-all

## Restore latest snapshot
restic -r s3:http://127.0.0.1:9000/kubermatic-master-backups restore f2d639e3 --target ./kubermatic-master-backups/snapshot-f2d639e3 -v
