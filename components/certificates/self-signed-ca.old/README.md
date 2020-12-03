
# Setup Kubermatic with self-signed CAs

## easyrsa - create own CA (if needed)

**easyrsa** can manually generate certificates for your ingress.

1.  Download, unpack, and initialize the patched version of easyrsa3.
    ```bash
    curl -LO https://storage.googleapis.com/kubernetes-release/easy-rsa/easy-rsa.tar.gz
    tar xzf easy-rsa.tar.gz
    cd easy-rsa-master/easyrsa3
    ./easyrsa init-pki
    ```
        
1.  Generate a new certificate authority (CA). `--batch` sets automatic mode;
    `--req-cn` specifies the Common Name (CN) for the CA's new root certificate.
    ```bash
    ./easyrsa --batch "--req-cn=YOURDOMAIN.loodse.training`" build-ca nopass
    ```
            
1.  Generate server certificate and key.
    - The argument `--days` is used to set the number of days
    after which the certificate expires.
    - `--subject-alt-name=` set the main `kubermatic` and wildcard `*.kubermatic` domain for the certificate

    ```bash
    ./easyrsa --subject-alt-name='DNS:*.kubermatic.YOURDOMAIN.loodse.training,DNS:kubermatic.YOURDOMAIN.loodse.training' --days=10000 build-server-full kubermatic.YOURDOMAIN.loodse.training nopass
    ```    
        
## Configure Kubermatic

### Replace NGINX Ingress with custom CA

Ensure the helm charts `cert-manager` and `certs` are not installed anymore. If so purge them:
```
export TILLER_NAMESPACE=kubermatic
helm delete --purge cert-manager
helm delete --purge certs
``` 

1. Add new server certificate to the ingress, see [`./create-ingress-secret-cert.sh`](./create-ingress-secret-cert.sh)
```bash
certname=kubermatic.YOURDOMAIN.loodse.training
KEY_FILE=$(dirname "$0")/custom-pki/pki/private/${certname}.key
CERT_FILE=$(dirname "$0")/custom-pki/pki/issued/${certname}.crt
CA_CERT_FILE=$(dirname "$0")/custom-pki/pki/ca.crt

kubectl -n default create secret tls kubermatic-tls-certificates --key ${KEY_FILE} --cert ${CERT_FILE}

cp $CA_CERT_FILE $(dirname "$0")/root-cas/
chmod 644 $CA_CERT_FILE $(dirname "$0")/root-cas/ca.crt
```

1. To test the connection add tha `ca.cert` to your local system as trusted root CA
  - e.g. Ubuntu: https://askubuntu.com/questions/73287/how-do-i-install-a-root-certificate
  
  Note: Browsers cert stores are mostly managed independently, so you may need to import them as well

### Add custom CA to Kubermatic components

We need to ensure that every component in the cluster what talks to to the ingress get the custom root CA propagated:
- `oauth`
- `iap`
- `kubermatic`
- `monitoring` (for blackbox exporter)

To distribute the certificate, we can use the [Pod Presets](https://kubernetes.io/docs/tasks/inject-data-application/podpreset). Therefore we have to options how to use them:

1. Option: Mount the root CA and every public CA's as an configmap to every pod, see [`./preset-ca-configmap.yaml`](./preset-ca-configmap.yaml)
   1. Ensure that all public trusted CAs are placed under the folder `<kubermatic-installer-script-dir>/root-ca`. The easiest way to get a clean version of the certificats, you could start a local docker container, add the ca-certificate package and copy the certs of `la /etc/ssl/certs/*` to the mounted `<kubermatic-installer-script-dir>/root-ca` dir:
       ```bash
       cd kubermatic-installer-script
       docker run -u 0 -it -v $(pwd)/root-cas:/tmp/certs alpine ash
       ### execute in container
       apk add ca-certificates
       cp -L /etc/ssl/certs/*.pem /tmp/certs/
       
       ### ensure file permissions matching to your host filesystem
       ### if user id of the docker host is 1000 (check in separate shell: id -u)
       chown 1000:1000 -R /tmp/certs/
       chmod 644 /tmp/certs/*
    
       ## if there are `.pem` files with special characters, rename them, e.g. `=` is not allowed value for a config map 
       mv /tmp/certs/ca-cert-NetLock_Arany_=Class_Gold=_Főtanúsítvány.pem /tmp/certs/ca-cert-NetLock_Arany.pem
       ``` 
   1. Note: that you need to update the certificates from time to time, to ensure they are valid. 
   
2. Option: Add the root CA to the VM image what is used for the nodes and mount the host certificate to the container, see [`./preset-host-cas.yaml`](./preset-host-cas.yaml)

### Run the update script

Therefore we need modify the installation progress (see [`./kubermatic-deploy.sh`](./kubermatic-deploy.sh) and add the presets to every namespace where the adjusted CA is needed. 
```bash
# Injects custom CA certificate to dedicated deployments. Note: to activate the PodPresets in existing installations, you would need to recreate the existing pods. For this delete all existing pods with `DELETE_PODS=true`
function injectCustomCA() {
  local root_ca_dir=$(dirname "$0")/root-cas
  local name=$1
  local namespace=$2
  local path="$CHART_FOLDER/$3"
  local timeout=${4:-300}

  echodate "Injecting Root CAs into helm chart $1"
  kubectl create configmap root-cas --from-file $root_ca_dir/ --dry-run -o yaml > $path/templates/root-cas.yaml
  cp $(dirname "$0")/preset-ca-configmap.yaml $path/templates/ca-preset.yaml
  # cp $(dirname "$0")/preset-host-cas.yaml $path/templates/ca-preset.yaml
}

```

We also need to restart the pods, so the presets can work as mutating webhook:
```bash
function deploy() {
  # .....
  if [ "${DELETE_PODS:-}" = "true" ] && [[ ${inital_revision} != "" ]]; then
    echodate "==> ensure pod get restarted"
    kubectl delete pod --all -n $namespace
  fi
  unset TEST_NAME
}
```
