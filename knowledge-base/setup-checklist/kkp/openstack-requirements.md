# Additional Openstack Kubermatic Requirements


## Openstack Cluster Administrator Account

The Openstack cluster account that will be used should have the necessary permissions to access/create the following resources (the account will be used by Kubone plus terraform to create the needed infrastructure components and the kubernetes openstack-cloud provider):

- Nova compute VMs

- Neutron - networks,external network, subnets, routers, security-groups and floating-ip allocation

- Cinder Block storage - this will be used to provision PVCs inside the kubernetes cluster

- Instance flavor types that matches the CPU,RAM and storage requirements for the intended kubermatic installation. See [kubermatic node requirement](https://docs.kubermatic.io/requirements/cluster_requirements/#master-cluster)

- Glance - OS Image repository (Ubuntu 16.04+, Centos 7 or Container Linux)

  *N.B - Kubeone currently requires Ubuntu OS for the control plane node, this condition is not applicable to the worker nodes (either Ubuntu, Centos or Container Linux as base OS can be used)*

Below provides the needed environment variables for the Openstack RC file that should sourced before starting the deployment:

```
OS_AUTH_URL=...
OS_IDENTITY_API_VERSION=3
OS_USERNAME=...
OS_PASSWORD=...
OS_REGION_NAME=...
OS_INTERFACE=public
OS_ENDPOINT_TYPE=public
OS_USER_DOMAIN_NAME=...
OS_PROJECT_ID=...
```

The permissions listed above can also be used for the purpose of creating openstack based user clusters, kubermatic makes use of the machine-controller project to create the needed worker nodes of the user cluster. For more information on this please check the [openstack machine-controller](https://github.com/kubermatic/machine-controller/blob/master/examples/openstack-machinedeployment.yaml) documentation.

## Openstack Floating IPs

Floating IPs are the public routable IP addresses that will be used by resources within the Openstack cluster, some will be used by the load balancers (kubernetes load balancer service type) and kubernetes nodes (masters and worker-nodes). The site firewall should have appropriate rules that will allow communication from the internet to these IP addresses. 

Please check the documentation for further explanation on the [ports](https://docs.kubermatic.io/requirements/cluster_requirements/#check-required-ports) that needs to be accessible

## Openstack Load Balancer

The Openstack component that is responsible for this is the neutron LBaaSv2 or Octavia. LBaaSv2 still works but it is in the process of been depreciated so it is strongly advised that Octavia is used as it is a major upgrade from the LBaaSv2, also support is now directed solely to Octavia in the Openstack community.

Link to the depreciation discussion: https://wiki.openstack.org/wiki/Neutron/LBaaS/Deprecation


