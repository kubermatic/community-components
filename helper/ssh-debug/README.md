## SSH Debug Client

For quickly ssh to nodes in an internal network you could deploy this manifest.
Create or add your key to the provided [`./secrect.ssh.key.yaml`](./secrect.ssh.key.yaml)  file and trigger the deployment:

```bash
# create ssh secret from id_rsa,id_rsa.pub under `.ssh`folder:
kubectl create secret generic --from-file ./.ssh/ ssh-key -n default --dry-run -o yaml > ./secrect.ssh.key.yaml

#deploy manifests
kubectl apply -f ./
```
Use now `kubectl exec -it` to login to container, and connect to the nodes ip's of the kvirt vmi's:
```bash
#at seed cluster
kubectl get vmi -A

kubectl exec -it -n default ssh-debug-xx-xxx bash
# e.g. for ubuntu worker node
ssh ubuntu@IP-OF-VMI
```