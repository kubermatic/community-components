#### KKP TEMPLATE environment
#export KKP_API="https://example.kubermatic.com/api/v2"
#export KKP_PROJECT="PROJECT_ID"
## see https://docs.kubermatic.com/kubermatic/master/references/rest-api/#/project/createClusterV2
#export KKP_CLUSTER_PAYLOAD="cluster.json"
## see https://docs.kubermatic.com/kubermatic/master/references/rest-api/#/addon/createAddonV2
#export KKP_CLUSTER_ADDON="addon-*.json"
## Service Account Token created at the KPP UI > Project > Service Account
#export KKP_TOKEN=$(cat ~/Downloads/token)
##or
##export KKP_TOKEN=TOKEN_VALUE