# Additional Requirements for Bare Metal Setups

## Access to BareMetal Infrastructure

1. Access by SSH via VPN or JumpHost to the dedicated bare metal host
2. The provided ssh user needs to have sudo rights to setup kubernetes
3. List of IP addresses, to provision the target environment 

**NOTE:** Dynamic provisioning is currently in Development. Alternative approaches are to use a virtualized [kubevirt](https://github.com/kubermatic/machine-controller/blob/master/docs/cloud-provider.md#kubevirt) based setup at Kubermatic KKP. 

## User Cluster / Network separation

The separation and multitenancy of KKP and there created user clusters is highly dependent on the provided network and user management of the bare metal Infrastructure. Due to the individuality of such setups it's recommended to create a dedicated concept per installation together with Kubermatic engineering team. Please provide at least one separate network CIDR and technical vSphere user for the management components and each expected tenant.

As an alternative, for protecting the dedicated kubernetes cluster could be improved by applying so called "Host Protection Network Policies" by default trough Calico, see [https://docs.projectcalico.org/security/protect-hosts](https://docs.projectcalico.org/security/protect-hosts)

## (if no DHCP) Machine CIDRs
Depending on the target network setup, we need ranges for:

- 3 master nodes of seed cluster
- n worker nodes of seed cluster
- n worker node for each user cluster

To provide "cloud native" experience to the end user of KKP, we recommend the usage of an DHCP.

## Routable virtual IPs (for metalLB)

To set up Kubermatic behind [MetalLB](https://metallb.universe.tf/), we need a few routable address ranges. This could be sliced into one CIDR. The CIDR should be routed to the target network, but not used for machines. 

### master/seed cluster
CIDR for

- Ingress: 1 IP
- Node-Port-Proxy: 1 IP (if expose strategy NodePort), multiple IPs at expose strategy LoadBalancer (for each cluster one IP) 

### user cluster
Depending on the concept how application workload get exposed, IP's need to get reserved for exposing the workload at the user cluster side. As recommendation at least one virtual IP need is needed for e.g. an MetalLB user cluster load balancing addon + NGINX ingress. 

Note: during the provisioning of the user cluster, the IP must be entered for the MetalLB addon and the user must ensure that there will be no IP conflict.

## Integration into KKP

### Option I - Workers only in on-premise Datacenter(s)

* Worker Node IP Range need to reach seed cluster user control plan endpoints, see [Expose Strategy](https://docs.kubermatic.com/kubermatic/master/concepts/expose-strategy/expose_strategy)
* KKP will create then a secure VPN tunnel between worker and control plan, so no way back connection need to be opened
* Existing seed nodeport-proxy endpoint need to get reached by the provisioned nodes
* During the provisioning the setup execution host needs to access the target nodes by ssh and execute the kubeadm based node setup
* Application traffic get exposed at bare-metal workers by the chosen ingress / load balancing solution

        
### Option II - Additional Regional Seed + Workers at on-premise Datacenter(s)

* Seed Cluster Kubernetes API endpoint at the dedicated on-premise seed cluster (provisioned by e.g. KubeOne) need to be reachable
    * Kubernetes API Load Balancer `https` endpoint
* Worker Node IP Range needs to talk to additional `node-port` load balancer endpoint at the on-premise seed cluster
    * Additional DNS entry for dedicated datacenter seed(s) is needed e.g. `*.regaion-1-seed.kubermatic.example.com`
    * Workers <-> Seed communication is in the data center network only
* User Cluster users need to reach the on-premise datacenter seed cluster load balancer `node-port`
    * IP/DNS of node-port LoadBalancer by `https`
* Application traffic get exposed at on-premise workers by the chosen ingress / load balancing solution
* Host for Seed provisioning (KubeOne setup) needs to reach by the base network (e.g. a bastion host) by SSH