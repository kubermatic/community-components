# Kubermatic Setup Requirements

## Documentation
To respect the latest requirements and instructions, follow the installation as described at:

https://docs.kubermatic.com/kubermatic/master/installation/

Any further environment specific details, will get described later in this document. 

## Infrastructure Requirements - Summary

To ensure the quality of service, Kubermatic Kubernetes Platform (KKP) relies on the basic availability and setup of the dependent infrastructure as defined at [KKP Documentation > Requirements](https://docs.kubermatic.com/kubermatic/master/requirements). 

For the installation of KPP ensure that the mentioned requirements are 
fulfilled. Besides of the mentioned minimal requirements, it's recommend that the provided infrastructure ensures the following criteria for the managing master/seed cluster as well as for the user clusters:
- High Availability setup of the public or/and private cloud infrastructure:
  - The target network for master and user clusters follows the recommended Kubernetes networking concept: [Kubernetes Cluster Networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
  - The infrastructure is compatible with the recommended architecture of HA Kubernetes cluster as defined at [kubernetes.io > Set up High-Availability Kubernetes Masters](https://kubernetes.io/docs/tasks/administer-cluster/highly-available-master/)
  - Multiple availability zones are accessible, routed and compatible with Kubernetes as described in the multi-zone best practices: [Kubernetes - Running in multiple zones](https://kubernetes.io/docs/setup/best-practices/multiple-zones/)
- A storage layer needs to get provided, which is compatible with Kubernetes and provides a storage class, see [Kubernetes - Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/), and respect the customer expected requirements on data reliability and backup.     
- A Kubernetes compatible load balancing solution is available at the target cloud environment(s), see [Kubernetes - Services, Load Balancing, and Networking](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer)
- An adjustable public or private DNS service is usable.

## Access to Installer
The installation is done by deploying a set of Helm charts or Kubermatic Operator. For downloading CE/EE Version you can visit since 2.14: https://github.com/kubermatic/kubermatic/releases

For the EE version an additional image pull secret is required. Your Kubermatic contact person will provide this for the installation.

## Config Repo
* To ensure the configuration is stored properly versioned, we would recommend to setup a proper git repository, where Kubermatic engineers, and the customer has access.
* To store the secrets, we would recommend some secret key store like [Vault](https://www.vaultproject.io/).
    * An alternative could be the usage of [git-crypt](https://github.com/AGWA/git-crypt)

## Access to Target Environment

To install KKP at customer environment, we need access from external to (direct or by a bastion host):
- Linux env with SSH
- Target cloud provider APIs
- LoadBalancer (API Servers, Ingress, etc.), Master / Worker Nodes network for testing and potential debugging
- Access to potential used DNS servers and firewall settings
- Tooling:
  a) Use out tooling container `quay.io/kubermatic-labs/kubeone-tooling`, see [helper/kubeone-tool-container](../../../helper/kubeone-tool-container)
  b) or install helper tools: [kubeone](https://github.com/kubermatic/kubeone), git, kubectl, helm, terraform
    - optional: yq, jq, [fubectl](https://github.com/kubermatic/fubectl)

## Load Balancer
Kubermatic exposes an NGINX server and user clusters API servers. If no external load balancer is provided for the PoC, we recommend [MetalLB](https://metallb.universe.tf/). This requires a set of usable IP addresses in the Kubermatic network that are not managed by DHCP (at least 2 for Kubermatic itself). The role of this LB is different from gobetween, which is only used to access the master clusters API server.

For other LoadBalancer we strongly recommend LoadBalancer what can interact dynamically with Kubernetes to provide updates for service type `LoadBalancer` or Ingress objects. For more detail see [Kubernetes - Services, Load Balancing, and Networking](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer). 

## DHCP / Network
* DHCP for worker nodes is recommended
* (if MetalLB is used) fixed IPs for Load Balancer need to be reserved in the target network DHCP settings. 
* Direct Node-to-Node communication is needed based on generic Kubernetes requirements: [Kubernetes - Cluster Networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/)

## DNS
Kubermatic requires DNS entries for NGINX and user clusters API servers. These have to be created after the LoadBalancers, see [EE Installation - DNS Records](https://docs.kubermatic.com/kubermatic/master/installation/install_kubermatic_ee/#dns-records) and [EE Seed Cluster - DNS Records](https://docs.kubermatic.com/kubermatic/master/installation/add_seed_cluster_ee/#update-dns).

The NGINX server provides access to the Kubermatic UI and the logging and monitoring services (Prometheus, Kibana, etc.). It requires a DNS name like kubermatic.example.com and *.kubermatic.example.com (e.g. for prometheus.kubermatic.example.com).
Optional: if no wildcard DNS can be provided, dedicated DNS entries per exposed Service need to get entered (~5 services).

To access a user cluster via API, a wildcard DNS entry per seed cluster (in your case the master cluster is the only seed) has to be provided. E.g., *.cluster-1.kubermatic.example.com. User clusters would be accessible via [cluster-id].cluster-1.kubermatic.example.com.
Optional: An alternative expose strategy `LoadBalancer` can be chosen. There for every control plane get his own LoadBalancer with an external IP, see [Expose Strategy](https://docs.kubermatic.com/kubermatic/master/concepts/expose-strategy/expose_strategy/).

#### Example of  DNS Entries for KKP Services

**Root DNS-Zone: `*.kubermatic.example.com`**

<table>
  <tr>
   <td><strong>Service</strong>
   </td>
   <td><strong>DNS</strong>
   </td>
   <td><strong>IP</strong>
   </td>
  </tr>
  <tr>
   <td>KKP UI
   </td>
   <td>kubermatic.example.com
   </td>
   <td>Ingress IP: dynamic or static (virtual IP)
   </td>
  </tr>
  <tr>
   <td>Monitoring - Prometheus
   </td>
   <td>prometheus.kubermatic.example.com
   </td>
   <td>Ingress IP: dynamic or static (virtual IP)
   </td>
  </tr>
  <tr>
   <td>Monitoring - Grafana
   </td>
   <td>grafana.kubermatic.example.com
   </td>
   <td>Ingress IP: dynamic or static (virtual IP)
   </td>
  </tr>
  <tr>
   <td>Monitoring - Alertmanager
   </td>
   <td>alertmanager.kubermatic.example.com
   </td>
   <td>Ingress IP: dynamic or static (virtual IP)
   </td>
  </tr>
  <tr>
   <td>Logging - Kibana (depricated)
   </td>
   <td>kibana.kubermatic.example.com
   </td>
   <td>(if used - loki default)<br/>
Ingress IP: dynamic or static (virtual IP)
   </td>
  </tr>
  <tr>
   <td>Seed cluster - Kubernetes API Expose Service
   </td>
   <td>Expose Strategy - <b>NodePort</b>: *.seed.kubermatic.example.com
<p/>
<p/>
Expose Strategy - <b>LoadBalancer</b>: NONE <br/>
(will be done by independent IPs per cluster see - <a href="https://docs.kubermatic.com/kubermatic/master/concepts/expose-strategy/expose_strategy/">expose strategy LoadBalancer</a>).
   </td>
   <td>NodePort Proxy: dynamic or static (virtual IP)
<p/>
<p/>
<b>Or</b> one virtual IP per user cluster in a CIDR
   </td>
  </tr>
</table>

## Certificates
Certificates are required for the Kubermatic UI, as well as logging and monitoring services. As automatic creation via cert-manager is not an option, please create in advance. According the DNS example, this has to be valid for kubermatic.example.com, prometheus.kubermatic.example.com, grafana.kubermatic.example.com, alertmanager.kubermatic.example.com and kibana.kubermatic.example.com. Our Helm charts require a single certificate file to be valid for these names (wildcard is fine).

Please provide also a CA bundle with all intermediate certificates.

Using a letsencrypt certificate would be preferable over your own CA as this would not require to trust your CA in pods that talk to DEX. Can be requested via DNS based validation.

## Authentication
We use DEX for authentication. Pick a supported connector from [Dex Connectors](https://github.com/dexidp/dex#connectors) and make the necessary preparations. Static users or your Github Org / Gitlab instance might be an option as well.
Alternatively KKP supports ID provider like Keycloak as well, see [OIDC Provider Configuration](https://docs.kubermatic.com/kubermatic/master/advanced/oidc_config/).

## Proxy / Internet-Access

For provisioning the master/seed/user clusters with there components, KKP needs access to a few resources, see [Proxy Whitelisting](https://docs.kubermatic.com/kubermatic/master/advanced/proxy_whitelisting/). Please ensure that you have internet access at your provided platform or any proxy, what allows to download the mentioned artifacts.

Alternative approach what requires a few more configuration is the [Offline Mode](https://docs.kubermatic.com/kubermatic/master/advanced/offline_mode/).

## Provisioning of seed cluster
We recommend to set up your seed cluster based on KubeOne. Please check the prerequisites therefore as well [KubeOne Prerequisites](https://docs.kubermatic.com/kubeone/master/prerequisites/).

## Storage Classes
As reference for compatible Kubernetes storage classes, see [Kubernetes - Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/). For KKP two different storage classes are needed and provided by the target infrastructure:  

### Kubermatic storage class `kubermatic-fast`

The configuration of storage class `kubermatic-fast` is needed to cater for the creation of persistent volume claims (PVCs) for some of the components of Kubermatic. The following components need a persistent storage class assigned:

* User cluster ETCD statefulset
* Prometheus and Alertmanager (monitoring)
* Elasticsearch (logging)

It’s highly recommended to use SSD-based volumes, as etcd is very sensitive to slow disk I/O. If your cluster already provides a default SSD-based storage class, you can simply copy and re-create it as `kubermatic-fast.`. 

### Cluster Backup Storage Class `kubermatic-backup`
Kubermatic performs regular backups of user clusters by snapshotting the etcd of each cluster. By default these backups are stored in any S3 compatible storage location. At on-prem setups (or non available S3 storage possibility), KKP will use an in-cluster S3 location provided by a PVC. The in-cluster storage is provided by [Minio S3 gateway](https://docs.min.io/docs/minio-gateway-for-s3.html).

It's recommended to configure a class explicitly for Minio. Minio does not need `kubermatic-fast` because it does not require SSD speeds. A larger HDD is preferred. The availability and data protection of the backup is dependent on the chosen storage location and setting.

## Performance Requirements

Besides the already above mentioned performance requirements, any additional performance of the system is highly dependent on the provided infrastructure performance. Therefore, Kubermatic KKP and KubeOne get checked on every release to be fully compliant with the [Certified Kubernetes Conformance Program](https://github.com/cncf/k8s-conformance#certified-kubernetes-conformance-program). To ensure the performance criteria also at the target infrastructure, the conformance test can be executed. Potential performance bottlenecks will be analysed and need to be addressed individually together with the responsible infrastructure provider.   