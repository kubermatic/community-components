
# Setup Kubermatic with self-signed CAs

## easyrsa - create own CA (if needed)

**easyrsa** can manually generate certificates for your ingress.

1.  Download, unpack, and initialize the patched version of easyrsa3.
    ```sh
    curl -LO https://storage.googleapis.com/kubernetes-release/easy-rsa/easy-rsa.tar.gz
    tar xzf easy-rsa.tar.gz
    cd easy-rsa-master/easyrsa3
    ./easyrsa init-pki
    ```
        
1.  Generate a new certificate authority (CA). `--batch` sets automatic mode;
    `--req-cn` specifies the Common Name (CN) for the CA's new root certificate.
    ```sh
    DOMAIN=YOURDOMAIN.loodse.training
    ./easyrsa --batch "--req-cn=$DOMAIN" build-ca nopass
    ```
    now a new private keypair has been generated:
    ```sh
    ./easy-rsa-master/easyrsa3/pki/private/ca.key
    ./easy-rsa-master/easyrsa3/pki/ca.crt
    ```

    
        
## Configure Kubermatic

See [Using a Custom CA](https://docs.kubermatic.com/kubermatic/master/tutorials_howtos/kkp_configuration/using_custom_cert_manager/)

### Update the cluster issuer of `cert-manager` in `values.yaml`:

Configure your custom ca as follows (for me Details see [cert-manager.io - configuration > CA](https://cert-manager.io/docs/configuration/ca/)):
```yaml
dex:
  ingress:
    # configure your base domain, under which the Kubermatic dashboard shall be available
    host: example.kubermatic.com

  # .....

  # the cert-manager Issuer (or ClusterIssuer) responsible for managing the certificates
  certIssuer:
    name: ca-prod
    kind: ClusterIssuer
```

### Apply Cluster Issuer [`certmanager.issuer.yaml`](./certmanager.issuer.yaml):

```
kubectl apply -f certmanager.issuer.yaml
```
### Apply config changes of Kubermatic

#### (for OIDC auth) add `caBundle`

Create an CA Bundle with the created `ca.crt` file and may all others, see [How do I make my own bundle file from CRT files?](https://ssl4less.eu/faq/technical-questions/how-do-i-make-my-own-bundle-file-from-crt-files.html):

```shell script
base64 -w 0 ./easy-rsa-master/easyrsa3/pki/ca.crt
## copy content in clipoard 
```
add it to the `KubermaticConfiguration` object as base64 encoded `caBundle`:
```yaml

apiVersion: operator.kubermatic.io/v1alpha1
kind: KubermaticConfiguration
metadata:
  name: kubermatic
  namespace: kubermatic
spec:
  # ....
  auth:
    caBundle: |
      -----BEGIN CERTIFICATE-----
      <certificate 1 here>
      -----END CERTIFICATE-----
    clientID: kubermatic
    issuerClientID: kubermaticIssuer
    # When using letsencrypt-prod replace with "false"
    skipTokenIssuerTLSVerify: true
    tokenIssuer: https://example.kubermatic.com/dex
```

#### Update Kubermatic and check
Run normal Installation script again and ensure:

1. Check issuer is ready
```
kubectl get clusterissuers.cert-manager.io 
NAME                  READY   AGE
ca-prod               True    1m
letsencrypt-prod      True    12h
letsencrypt-staging   True    12h
```
1. Certs have been created freshly (no old certs should be present)
```
kubectl get certificate -A
NAMESPACE    NAME         READY   SECRET           AGE
kubermatic   kubermatic   True    kubermatic-tls   1m
oauth        dex          True    dex-tls          1m
```
**IMPORTANT:** if certs are old or not ready, please redeploy the affected components `oauth` and `kubermatic`
1. Check no crashing pods at ns `kubermatic` and `oauth`
```shell script
kubectl get pods -n kubermatic
kubectl get pods -n oauth
``` 
