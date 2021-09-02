# NOTE: temporary solution for reaching thanos by vSOC
**COPY of https://github.com/kubermatic/managed-service/blob/main/mla/thanos/seed-ingress**

---

# Seed Cluster Thanos Ingress

This is an ingress definition that exposes Thanos in KKP Seed cluster for accessing it from remote Grafana instances.

It aims to be just a temporary solution until large-scale remote_write solution is provided for VSOC.

It adds a basic-auth auth by username/password stored in the `thanos-basic-auth` secret. The secret can be created as follows:

```bash
$ htpasswd -c auth username
New password: <password>
New password:
Re-type new password:
Adding password for user username
```
```bash
cat ./auth
```
Copy the hashed value into your `values.yaml` under:
```yaml
serviceGateway:
  ingress:
    thanos:
      # e.g. 'your-username:$apr1$UAnMN0vF$wHJ552Fgf3MKbu3RVvadK0'
      auth_secrect: '---PASTED-STRING-----'
```

It's important the key is generated and rendered into the ingress config named `auth` (actually - that the [`thanos-ingress.secret.yaml`](./templates/thanos-ingress.secret.yaml) has a key `data.auth`), otherwise the ingress-controller returns a 503.
```