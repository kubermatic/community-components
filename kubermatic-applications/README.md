# Applications

## Agro CD setup
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
