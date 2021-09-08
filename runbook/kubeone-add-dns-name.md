## Adding new IP address/DNS name of an exisiting KubeOne cluster ##

<br>

There can be scenarios where we will have to add/change IP address/DNS name to an exisiting kubeone cluster. If we try and change/add IP/DNS name on an exisiting cluster we will get into TLS certificate errors (when we try connecting to the cluster) as the new IP/DNS name is not available in the **SAN (Subject Alternative Name)** of the API server certificate. This run book will walk you through on how to add a IP address/DNS name to the TLS certificate used by the Kubernetes API server.

The process of updating the certificate SAN to include a IP address/DNS name could find use for a few different scenarios. A couple of situations  such as

- Adding a load balancer in front of the control plane.
- Using a new or different URL/hostname to access the API server.
- New DHCP leases/IP getting used by other hosts in a data centre.

As kubeone internally uses ``kudeadm`` to bootstrap the cluster, the same `kubeadm` will be used to update the API server’s certificate to include additional names in the list of SANs.

To do this, first we need the `kubeadm` configuration file. `kubeadm` writes its configuration into a ConfigMap named “kubeadm-config” found in the “kube-system” namespace.

To pull the kubeadm configuration from the cluster into an external file, run this command:


```
kubectl get configmap -n kube-system kubeadm-config -o jsonpath='{.data.ClusterConfiguration}' > kubeadm-config.yaml
```

_This creates a file named kubeadm-config.yaml, the contents of which may look something like this (the file from your cluster may have different values):_

![image](https://user-images.githubusercontent.com/29113813/132445235-2ab22fa0-712d-4a21-8321-6520a36804c4.png)

In this particular case, only one additional SAN is listed. To add another SAN, add an entry in certSANs list under the apiServer section. 
If you already had a kubeadm configuration file that you used when you bootstrapped the cluster, you may already have a certSANs list. If not, you’ll need to add it; if so, you’ll just add another entry to that list.

Here’s an example (showing only the apiServer section):

![image](https://user-images.githubusercontent.com/29113813/132445880-dbe2cd58-0874-40d8-adf9-04c8ef105e97.png)

This change to the `kubeadm` configuration file adds SANs for the entries listed under `certSANs`. This would be in addition to the standard list of SANs that are included (which would be the local hostname, some names for the default Kubernetes Service object, the default IP address for the Kubernetes Service object, and the primary IP address of the node).

Once you’ve updated the kubeadm configuration file (one pulled from the ConfigMap) you’re ready to update the certificate.

_**First, move the existing API server certificate and key (if kubeadm sees that they already exist in the designated location, it won’t create new ones**_

```
mv /etc/kubernetes/pki/apiserver.{crt,key} ~
```
Then, use kubeadm to just generate a new certificate:
```
kubeadm init phase certs apiserver --config kubeadm-config.yaml
```
This command will generate a new certificate and key for the API server, using the specified configuration file for guidance. Since the specified configuration file includes a certSANs list, then kubeadm will automatically add those SANs when creating the new certificate.

## Verifying the change

The way to verify the change is to use openssl on the control plane node to decode the certificate and show the list of SANs on the certificate:
```
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text
```
Look for the `X509v3 Subject Alternative Name` line, after which will be a list of all the DNS names and IP addresses that are included on the certificate as SANs. After following this procedure, you should see the newly-added names and IP addresses you specified in the modified kubeadm configuration file. If you don’t, then something went wrong along the way. Common mistakes in this process include forgetting to remove the previous certificate and key (kubeadm won’t create new ones if they already exist), or failing to include the --config kubeadm-config.yaml on the kubeadm init phase certs command.

## Restarting API server

The final step is restarting the API server to pick up the new certificate. The easiest way to do this is to kill the API server container using docker:

Run `docker ps | grep kube-apiserver | grep -v pause` to get the container ID for the container running the Kubernetes API server. (The container ID will be the very first field in the output.)

Run `docker kill <containerID>` to kill the container.

If your nodes are running containerd as the container runtime, the commands are a bit different:

Run `crictl pods | grep kube-apiserver | cut -d' ' -f1` to get the Pod ID for the Kubernetes API server Pod.

Run `crictl stop <pod-id>` to stop the Pod.

Run `crictl rmp <pod-id>` to remove the Pod.

The Kubelet will automatically restart the container, which will pick up the new certificate. As soon as the API server restarts, you will immediately be able to connect to it using one of the newly-added IP addresses/DNS names.

## Updating the In-Cluster Configuration

Assuming everything is working as expected, the final step is to update the kubeadm ConfigMap stored in the cluster. This is important so that when you use kubeadm to orchestrate a cluster upgrade later, the updated information will be present in the cluster.

```
kubectl edit -n kube-system configmap kubeadm-config 
```
Update SAN and cluster endpoint as needed.

_Note: This run book wont be useful if the objective is to replace an exisiting IP/DNS name to a new IP/name. For that additionally we need to edit all API end points which will be documented in a seperate runbook._

