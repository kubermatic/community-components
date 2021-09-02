**COPY OF: https://github.com/kubermatic/managed-service/tree/main/mla/service-gateway**
---

# Multi-Cluster Service Gateway

This Helm chart contains a deployment of "Multi-Cluster Service Gateway", which can provide
access to k8s services running in a k8s cluster A via a local k8s services running in a k8s cluster B.
Between the clusters, the traffic is being forwarded in an encrypted OpenVPN tunnel.

## Concepts
- The cluster that consumes k8s services from a remote cluster runs a **Service Gateway Server**.
- The cluster that provides k8s services to a remote cluster runs a **Service Gateway Client**.
- The provider initiates the VPN connection to the consumer cluster.
- Consumers can then open connections to the k8s services provided by the provider.
- Multiple providers (clients) can connect to the same consumer (server). In that case the traffic will be load-balanced between them.
- Multiple Service Gateway Server replicas are not supported.
- There are no requirements on the pod subnet CIDR or k8s services CIDR - they can overlap in the provider and consumer cluster.
- The solution also works between different namespaces within a single cluster.

## Usage
Both Server and Client Gateways are implemented in a single Helm chart. Use the `serviceGateway.mode`
value to distinguish between the server and client mode.

In order to make a service available across clusters, define it in the [values.yaml](values.yaml) as in this example:

```yaml
  services:
    - name: nginx-ext
      port: 80
      internalPort: 12345
      clientService:
        name: nginx
        namespace: default
        port: 80
```

- `clientService` defines what k8s service on the client (provider) side is being provided to the remote side.
- `name` and `port` defines the service name and port that can be used in the consumer cluster to access the remote service.
- `internalPort` can be any port number, but must be unique across multiple remote services.

### Install Service Gateway Server
```bash
helm --namespace server upgrade --atomic --create-namespace --install service-gw-server . --set serviceGateway.mode=server
```

### Install Service Gateway Client
```bash
helm --namespace client upgrade --atomic --create-namespace --install service-gw-client . --set serviceGateway.mode=client
```

### Deploy TLS Certificates
Both Server and Client Gateway need TLS certificates for mutual authentication.

#### Use cert-manager for managing the certificates
By default (unless disabled in `serviceGateway.server.useCertManger`), cert-manager is used to take care
of issuing all necessary certificates into the cluster and namespace, where the Service Gateway Server
is running. That also includes a certificate for the client, that needs to be manually distributed
into the cluster and namespace, where the Service Gateway Client is running.

In order to do that, first retrieve the client certificate:
```bash
kubectl get secret service-gw-client-certificates -n server -o yaml > /tmp/client-certificates.yaml
```

Modify the certificate manifest (e.g. change the target namespace, remove unnecessary metadata) in the
`/tmp/client-certificates.yaml` file, and then deploy it into the cluster where the Service Gateway Client is running:
```bash
kubectl apply -f /tmp/client-certificates.yaml
```

Note that the client and server certificates will expire in 3 years. Make sure to manually re-distribute the
renewed client certificate using the same procedure before its expiration.

#### Manage certificates manually
As an alternative to using cert-manager, the certificates can be also provisioned manually into proper secrets
in the namespace where the Server / Client Gateway is running:

For the Server Gateway:
- secret `service-gw-server-certificates` with the server's private key and certificate and CA's certificate.

For the Client Gateway:
- secret `service-gw-client-certificates` with the client's private key and certificate and CA's certificate.

Take a look into the [examples/certs](examples/certs) folder for an example of these secrets.
These secrets can be used for testing, but **make sure you do not use them for production**.
