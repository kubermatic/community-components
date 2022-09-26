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
    hosts:
      - host: argocd.xxxx.lab.kubermatic.io
    ingressClassName: 'nginx'
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
      kubernetes.io/tls-acme: 'true'
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
> Add the redirect-uri "https://eclipse-che.xxxx.lab.kubermatic.io/oauth/callback" of Eclipse CHE under DEX "KubermaticIssuer" Client
> While adding application, provide the namespace value as "default" for Eclipse CHE operator installation as per the design. Internally it takes care of creation of "eclipse-che" namespace and resources within it.

Sample values yaml for exposing Eclipse CHE 
```yaml
k8s:
  ingressDomain: eclipse-che.xxxx.lab.kubermatic.io
auth:
  identityProviderURL: "https://xxxx.lab.kubermatic.io/dex"
  oAuthClientName: "KubermaticIssuer"
  oAuthSecret: "XXXXXXXXXXXXXXXXXXXXXX"
```

## Flux2 setup

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