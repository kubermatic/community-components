# User-Cluster Alerts

Typically, the user-clusters created by KKP will not have any alerts defined even wheen we enable user-cluster Monitoring components.

This folder contains useful alerts that we can deploy in user-cluster. You can choose alerts relevant to you and deploy them your user-clusters.

1. ArgoCD related alerts
1. Additional Node Exporter rules
1. Rules to detect stuck Machine Deployments
1. Rules to detect issues with Metallb pools
1. Minio Operator based deployment related rules
1. Misc rules to detect stuck / failed / OOMkilled pods and cronjobs.

## Deployment of Alerts
You can deploy these AlertsRules in various ways.

### Deploy manually from KKP Dashboard UI
You can use KKP dashboard UI for specific user-cluster to deploy the Alert Rules. 
* Navigate to the right user-cluster.
* Choose the **Moniotring, Logging & Alerting** tab.
* Click **Add Rule Group** button
* Select Type as **Metrics**
* Paste the content of the yaml provided here.

### Deploy using API
If you are already provisioning the user-clusters via Kubermatic REST API, you can simply place the relevant `alertrules-*.yaml` files along side the `cluster.json` file. The provisioning script will search for all `alertrules-*.yaml` files and will deploy them at given user-cluster.

### Deploy via GitOps
You can also deploy these rules directly as a `RuleGroup` CR under `kubermatic.k8c.io/v1` api. For this, please consult CRD for RuleGroup to preare the spec. Spec involves base64 encoded version of the files provided here as one of the value. The CR must be deployed under appropriate cluster-xxxx namespace in appropriate seed cluster.