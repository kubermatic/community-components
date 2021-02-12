# Additional Requirements for Bare Metal Setups

## Access to BareMetal Infrastructure

1. Access by SSH via VPN or JumpHost to the dedicated bare metal host
2. The provided ssh user needs to have sudo rights to set up kubernetes
3. List of bare-metal hosts for the Kubernetes cluster provisioning at your target environment

**NOTE:** Dynamic provisioning is currently in Development. Alternative approaches are to use a virtualized [kubevirt](https://github.com/kubermatic/machine-controller/blob/master/docs/cloud-provider.md#kubevirt) based setup at Kubermatic KKP. 

## Kubernetes Cluster / Network separation

The separation and multitenancy of KubeOne clusters is highly dependent on the provided network and user management of the bare metal Infrastructure. Due to the individuality of such setups it's recommended to create a dedicated concept per installation together with Kubermatic engineering team. Please provide at least one separate network CIDR and technical user for the management components and each expected tenant.

As an alternative, for protecting the dedicated kubernetes cluster could be improved by applying so called "Host Protection Network Policies" by default trough Calico, see [https://docs.projectcalico.org/security/protect-hosts](https://docs.projectcalico.org/security/protect-hosts)

In-cluster multitenancy is manageable by dedicated RBAC configuration, see [Kubernetes Documentation > API Access Control > Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) what is enabled by default with every KubeOne Cluster. For applying a core set of RBAC configuration, the KubeOne addon could manage the settings, see [KubeOne Documentation > Advanced > Addons](https://docs.kubermatic.com/kubeone/master/advanced/addons/).

## Routable virtual IPs (for metalLB)

To set up Kubermatic behind [MetalLB](https://metallb.universe.tf/), we need a few routable, not DHCP managed IP addresses. This could be sliced into one CIDR. The virtual IPs should be routed to the target network, but not used for machines. 

### user workload
Depending on the concept how application workload get exposed, IP's need to get reserved for exposing the workload at the user cluster side. As recommendation at least one virtual IP need is needed for e.g. an MetalLB user cluster load balancing addon + NGINX ingress. 

Note: during the provisioning of the user cluster, the IP must be entered for the MetalLB addon and the user must ensure that there will be no IP conflict.

## Storage Classes
In bare-metal environment mostly no default Kubernetes storage classes, is available and needs to be chosen during the setup. The following options could be fitting depending on the use case and quality criteria:
- Use of a default [Kubernetes - Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/). 
- Storage Appliance vendors provide CSI conforment storage, e.g.:
  - [NetApp Trident](https://netapp-trident.readthedocs.io/)
  - [PSO - PureStorage Orchestrator](https://github.com/purestorage/pso-csi)
- Software defined storage solutions:
  - [OpenEBS](https://docs.openebs.io/)
  - [Rook](https://rook.io/docs)

The environment specific storage class can be easily added as addon, see [KubeOne Documentation > Advanced > Addons](https://docs.kubermatic.com/kubeone/master/advanced/addons/).