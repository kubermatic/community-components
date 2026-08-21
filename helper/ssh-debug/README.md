## SSH Debug Client

For quickly ssh to nodes in an internal network you could deploy this manifest.
Create or add your key to the provided [`./secrect.ssh.files.yaml`](./secrect.ssh.files.yaml)  file and trigger the deployment:

```bash
# create ssh secret from id_rsa,id_rsa.pub under `.ssh`folder:
kubectl create secret generic --from-file ./.ssh/ ssh-files --dry-run -o yaml > ./secrect.ssh.files.yaml

#deploy manifests
#for k1
kubectl apply -f ./deployment.ssh.k1.debug.yaml -f ./secrect.ssh.files.yaml

#alternative
kubectl apply -f ./deployment.ssh.debug.yaml -f ./secrect.ssh.files.yaml
```

Use now `kubectl exec -it` to login to container, and connect to the nodes ip's of the kvirt vmi's:
```bash
#at seed cluster
kubectl get vmi -A

kubectl exec -it -n default ssh-debug-xx-xxx bash
# e.g. for ubuntu worker node
ssh ubuntu@IP-OF-VMI
```

### Use NGROK Tunnel

We could NGROK to open an external tunnel to e.g. a secured network to get an SSH Tunnel into the cluster. To get required tokens go to the [NGROK Dashboard > Your Authtoken](https://dashboard.ngrok.com/get-started/your-authtoken) and then create an Edge Gateway [NGROK Dashboard > Edges > New Edge > TCP](https://dashboard.ngrok.com/cloud-edge/edges)

To setup a ngrok tunnel inside the containers, uncomment the lines at [`deployment.ssh.k1.debug.yaml`](./deployment.ssh.k1.debug.yaml):
```yaml
          #Optional: your ngrok command to join
          ngrok config add-authtoken xxxx-YOUR-TOKEN-xxxx
          ngrok tunnel --log stdout --label edge=xxxx-your-edge-label 22
```

For the logs, check:
```bash
kubectl logs deployments/ssh-debug-k1-admin -f
```
Now after the tunnel is up you could use the public IP and ssh into the private cluster network:
```bash
# e.g. your ngrok IP: 8.tcp.eu.ngrok.io:21197
ssh -t root@8.tcp.eu.ngrok.io -p 21197
```

**NOTE:** The tunnel could get used for other use cases like a https connection. See [Ngrok Docs](https://ngrok.com/docs)

