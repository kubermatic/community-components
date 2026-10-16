# Applications

## Swytch Operator setup

[Swytch](https://getswytch.com) provides Redis-compatible caches as injected sidecars or shared servers.
The [application definition](swytch-operator-app.yaml) references the public OCI chart maintained in
[swytchdb/swytch-helm](https://github.com/swytchdb/swytch-helm). Version 1.5.2 installs operator and Swytch images 1.5.2.

### Requirements and installation

- Use a user cluster running Kubernetes **1.33 or newer**, and a KKP version supporting OCI Helm applications.
- Allow access to GHCR for chart downloads and image pulls.
- Install **one operator per user cluster**. Installation creates cluster-wide RBAC, a CRD, and an admission webhook.
- The chart generates its webhook certificates; cert-manager is not required.

Register the definition on the KKP master cluster using an explicit administrative context:

```sh
kubectl --context <kkp-master-context> apply -f kubermatic-applications/swytch-operator-app.yaml
```

Then select **Swytch Operator**, version **1.5.2**, in the user cluster's Applications UI. Use the default target
namespace `swytch-system`; deployment waits for readiness with a five-minute timeout. Registering this community
definition does not add Swytch to KKP's bundled default catalog or automatically install it into user clusters.

After installation, follow the [Kubernetes quickstart](https://docs.getswytch.com/start/kubernetes/#2-create-a-namespace-and-credential)
from the credential creation step to create a `Swytch` resource and an application. The operator installation alone
does not create a cache. Keep credentials in Kubernetes Secrets in the workload namespace, outside this definition.

### Helm comparison compatibility

KKP versions affected by [this Helm comparison bug](https://github.com/kubermatic/kubermatic/pull/16731) may unnecessarily 
upgrade unchanged Swytch installations. Check the PR for the fix and affected versions.

### Upgrades and certificate renewal

Manage the application version and Helm values through its **ApplicationInstallation** or the KKP UI. Direct Helm
changes can diverge from the desired configuration managed by KKP. Publishing a new chart does not automatically
upgrade existing installations.

Before changing an application's version, apply any required CRD updates to the **user cluster**. Helm installs
CRDs initially but does not upgrade them. For example, after setting `CHART_VERSION` to the intended published version:

```sh
helm show crds oci://ghcr.io/swytchdb/charts/swytch-operator --version "$CHART_VERSION" \
  | kubectl --context <user-cluster-context> apply -f -
```

Then select the corresponding application version and check readiness. Review the
[upgrade documentation](https://docs.getswytch.com/kubernetes/operations/) for workload rollout requirements;
upgrading the operator alone does not necessarily replace existing injected sidecars.

The serving certificate defaults to a one-year lifetime. Before expiry, increment the string value
`webhook.certificateRevision` in the ApplicationInstallation's Helm values (for example, from `"1"` to `"2"`).
This renews the serving certificate with the existing CA and rolls the operator Deployment. Chart publication
and unchanged reconciliations do not renew certificates automatically.

## Echo Server setup
Sample values yaml for exposing Echo server
```yaml
    ingress:
        enabled: true
        hosts:
        - host: echo.xxxx.lab.kubermatic.io
          paths:
          - /
        ingressClassName: 'nginx'
        annotations:
            cert-manager.io/cluster-issuer: letsencrypt-prod
            kubernetes.io/tls-acme: 'true'
        tls: 
        - secretName: echoserver-tls
          hosts:
            - echo.xxxx.lab.kubermatic.io
```

## Eclipse CHE setup
> Pre-requisite:  Nginx ingress controller, cert-manager and dex/oauth setup should available on the cluster.
> Add the redirect-uri "https://eclipse-che.xxxx.lab.kubermatic.io/oauth/callback" of Eclipse CHE under DEX "kubermaticIssuer" Client
> While adding application, provide the namespace value as "default" for Eclipse CHE operator installation as per the design. Internally it takes care of creation of "eclipse-che" namespace and resources within it.

Sample values yaml for exposing Eclipse CHE 
```yaml
networking:
  auth:
    identityProviderURL: "https://xxxxx.lab.kubermatic.io/dex"
    oAuthClientName: "kubermaticIssuer"
    oAuthSecret: "xxxxxxxxxxxxxxxxxxxxxxxxxxx"
  domain: eclipse-che.xxxxx.lab.kubermatic.io
```

## Harbor setup
> Pre-requisite:  Nginx ingress controller and cert-manager setup should available on the cluster.

Sample values yaml for exposing Harbor 
```yaml
expose:
  ingress:
    hosts:
      core: harbor.xxxx.lab.kubermatic.io
      notary: notary.xxxx.lab.kubermatic.io
    className: "nginx"
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
      kubernetes.io/tls-acme: 'true'
externalURL: https://harbor.xxxx.lab.kubermatic.io
updateStrategy:
  type: Recreate
harborAdminPassword: xxxxxx
```

## Canal setup
> If the user cluster setup is without CNI (none), in that case the canal setup can be done as an application under `kube-system` namepsace

Sample values yaml for exposing Canal 
```yaml
# Provide the network interface to be use
canalIface: "wt0"
# Adjust the MTU size
vethMTU: "1280"
cluster:
  network:
    # Required. Value to be provided from Cluster.Network which is set Pods CIDR IPv4
    podCIDRBlocks: "172.25.0.0/16"
```

## [Sysdig Secure](https://sysdig.com/products/secure/) Integration

1. Setup a demo account at: https://sysdig.com/start-free/
1. After you login to the UI: https://eu1.app.sysdig.com/secure/#/data-sources/agents?setupModalEnv=Kubernetes&installContentDisplayType=tabular
1. The generated access key you could then add to the Sysdig Agent via the following values

```
    global:
      sysdig:
        # get from sysdig portal: https://eu1.app.sysdig.com/secure/#/data-sources/agents?setupModalEnv=Kubernetes&installContentDisplayType=tabular
        accessKey: xxxxx___TODO-ADD-KEY___xxxx
        region: eu1
      clusterConfig:
        # give a name for sysdig portal
        name: xxxxx___TODO-ADD_CLUSTER_NAME___xxxx
      kspm:
        deploy: true
    nodeAnalyzer:
      secure:
        vulnerabilityManagement:
          newEngineOnly: true
      nodeAnalyzer:
        benchmarkRunner:
          deploy: false
```

---

## DEPRECATED

### Agro CD setup
Sample values yaml for exposing AgroCD

```yaml
server:
  certificate:
    enabled: true
    domain: argocd.xxxx.lab.kubermatic.io
    issuer:
      group: cert-manager.io
      kind: ClusterIssuer
      name: letsencrypt-prod
    secretName: argocd-tls
  ingress:
    enabled: true
    https: true
    hosts:
    - argocd.xxxx.lab.kubermatic.io
    ingressClassName: 'nginx'
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
      kubernetes.io/tls-acme: 'true'
      nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    tls: 
    - secretName: argocd-tls
      hosts:
        - argocd.xxxx.lab.kubermatic.io
```
