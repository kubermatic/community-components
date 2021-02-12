# Kubeone Setup Requirements

## Documentation
To respect the latest requirements and instructions, follow the installation as described at:

https://docs.kubermatic.com/kubeone/master/

Any further environment specific details, will get described later in this document. 

## Infrastructure Requirements - Summary

To ensure the quality of service, Kubermatic Kubeone relies on the basic availability and setup of the dependent infrastructure as defined at [KubeOne Documentation > Infrastructure >Requirements](https://docs.kubermatic.com/kubeone/master/infrastructure/requirements/). 

For the installation of KubeOne ensure that the mentioned requirements are 
fulfilled. Besides of the mentioned minimal requirements, it's recommend that the provided infrastructure ensures the following criteria for the managing Kubernetes clusters:
- High Availability setup of the public or/and private cloud infrastructure:
  - The target network for the clusters follows the recommended Kubernetes networking concept: [Kubernetes Cluster Networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
  - The infrastructure is compatible with the recommended architecture of HA Kubernetes cluster as defined at [kubernetes.io > Set up High-Availability Kubernetes Masters](https://kubernetes.io/docs/tasks/administer-cluster/highly-available-master/)
  - Multiple availability zones are accessible, routed and compatible with Kubernetes as described in the multi-zone best practices: [Kubernetes - Running in multiple zones](https://kubernetes.io/docs/setup/best-practices/multiple-zones/)
- A storage layer needs to get provided, which is compatible with Kubernetes and provides a storage class, see [Kubernetes - Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/), and respect the customer expected requirements on data reliability and backup.     
- A Kubernetes compatible load balancing solution is available at the target cloud environment(s), see [Kubernetes - Services, Load Balancing, and Networking](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer)

The following document, will describe the needs for a successful productive system in more detail. 

## Access to `kubeone` binary
The installation is done by using the kubeone binary, please visit for downloading: [KubeOne Documentation > Getting KubeOne](https://docs.kubermatic.com/kubeone/master/getting_kubeone)

## Config Repo
* To ensure the configuration is stored properly versioned, we would recommend to setup a proper git repository, where Kubermatic engineers, and the customer has access.
* To store the secrets, we would recommend some secret key store like [Vault](https://www.vaultproject.io/).
    * An alternative could be the usage of [git-crypt](https://github.com/AGWA/git-crypt)

## Access to Target Environment

To install KubeOne at customer environment, we need access from external to (direct or by a bastion host):
- Linux env with SSH, see [KubeOne Documentation > Prerequisites > Configure SSH](https://docs.kubermatic.com/kubeone/master/prerequisites/ssh/)
- Target cloud provider APIs
- LoadBalancer (API Servers, Ingress, etc.), Master / Worker Nodes network for testing and potential debugging
- Access to potential used DNS servers and firewall settings
- Tooling:
  a) Use out tooling container `quay.io/kubermatic-labs/kubeone-tooling`, see [helper/kubeone-tool-container](../../../helper/kubeone-tool-container)
  b) or install helper tools: [kubeone](https://github.com/kubermatic/kubeone), git, kubectl, helm, terraform
  - optional: yq, jq, [fubectl](https://github.com/kubermatic/fubectl)

## Load Balancer
KubeOne can expose an NGINX server for the cluster workload. If no external load balancer is provided by the dedicated cloud provider for the setup, we recommend [MetalLB](https://metallb.universe.tf). This requires a set of usable IP addresses in the Kubermatic network that are not managed by DHCP (1 for every external endpoint). The role of this LB is to expose the cluster workload, which is different from the Kubernetes API LB. 

The Kubernetes API LB will be consumed as well from the target cloud environment or by some on-premise alternatives, see [KubeOne Documentation > Advanced > Example LoadBalancer](https://docs.kubermatic.com/kubeone/master/advanced/example_loadbalancer/). More Details will later be explained in the environment specific section.

If needed or wished to use other load balancer solutions we strongly recommend load balancers what can interact dynamically with Kubernetes to provide updates for service type `LoadBalancer` or Ingress objects. For more detail see [Kubernetes - Services, Load Balancing, and Networking](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer). 

## DHCP / Network
* DHCP for worker nodes is required (for provisioning nodes by [Kubermatic machine-controller](https://github.com/kubermatic/machine-controller))
* (if MetalLB is used) fixed IPs for Load Balancer need to be reserved in the target network DHCP settings. 
* Direct Node-to-Node communication is needed based on generic Kubernetes requirements: [Kubernetes - Cluster Networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/)

## DNS
Exposing Kubernetes 2
workload by DNS, requires e.g. a wildcard entry for the chosen Ingress solution.These have to be created after the LoadBalancers get his public IP assigned. In example the NGINX server provides access to the Kubernetes workload by `*.app.example.com`, what need to get configured externally. Optional: if no wildcard DNS can be provided, dedicated DNS entries per exposed Service need to get entered (1 per application service).

As automation the Kubernetes SIGs [external-dns](https://github.com/kubernetes-sigs/external-dns) project could also automation the DNS entry creation. This is recommended if dynamic changes of DNS will be needed. 

## Authentication
By default, authentication at a KubeOne cluster is provided by classic Kubernetes `kubeconfig` file after the successfully provisioned cluster. For more details see [Kubernetes Docs > Authentication](https://kubernetes.io/docs/reference/access-authn-authz/authentication/).

If wished kubeone also support OIDC based configuration, to example to utilize Dex to implement an AD based authentication. As a starting point see [Kubermatic Blog > Setting up OIDC Authentication](https://www.kubermatic.com/blog/kubeone-oidc-authentication-audit-logging/)

## Proxy / Internet-Access

For provisioning the clusters with all needed components, KubeOne needs access to a few resources. If you running kubeone behind the proxy see:
- [Proxy Support](https://docs.kubermatic.com/kubeone/master/advanced/proxy/)
- [Proxy Whitelisting - KubeOne](https://docs.kubermatic.com/kubermatic/master/advanced/proxy_whitelisting/#kubeone-seed-cluster-setup). 

## Storage Classes
As reference for compatible Kubernetes storage classes, see [Kubernetes - Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/). The environment specific storage class can be easily added as addon, see [KubeOne Documentation > Advanced > Addons](https://docs.kubermatic.com/kubeone/master/advanced/addons/).

## Performance Requirements

Besides, the already above mentioned performance requirements, any additional performance of the system is highly dependent on the provided infrastructure performance. Therefore, KubeOne get checked on every release to be fully compliant with the [Certified Kubernetes Conformance Program](https://github.com/cncf/k8s-conformance#certified-kubernetes-conformance-program). To ensure the performance criteria is also at the target infrastructure available, the conformance test can be executed. Potential performance bottlenecks will be analysed and need to be addressed individually together with the responsible infrastructure provider.   