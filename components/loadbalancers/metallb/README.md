# Metallb

## Use Case [[1]]
Kubernetes does not offer an implementation of network load-balancers (Services of type LoadBalancer) for bare metal clusters. The implementations of Network LB that Kubernetes does ship with are all glue code that calls out to various IaaS platforms (GCP, AWS, Azure…). If you’re not running on a supported IaaS platform (GCP, AWS, Azure…), LoadBalancers will remain in the “pending” state indefinitely when created.

Bare metal cluster operators are left with two lesser tools to bring user traffic into their clusters, “NodePort” and “externalIPs” services. Both of these options have significant downsides for production use, which makes bare metal clusters second class citizens in the Kubernetes ecosystem.

MetalLB aims to redress this imbalance by offering a Network LB implementation that integrates with standard network equipment, so that external services on bare metal clusters also “just work” as much as possible.

### Requirements

Requirements
MetalLB requires the following to function:

- A Kubernetes cluster, running Kubernetes 1.9.0 or later, that does not already have network load-balancing functionality.
- A [supported][3] network plugin. (Pick Weave Net of Flannel if you can)
- A cluster network configuration that can coexist with MetalLB.
- Some IP (v4 or v6) address range (like `192.168.0.0/30` or `192.168.0.0-192.168.0.3`) for MetalLB to hand out.
- Depending on the operating mode, you may need one or more routers capable of speaking BGP.

## OSI-2 Mode [[2]]

In layer 2 mode, one node assumes the responsibility of advertising a service to the local network. From the network’s perspective, it simply looks like that machine has multiple IP addresses assigned to its network interface.

Under the hood, MetalLB responds to ARP requests for IPv4 services, and NDP requests for IPv6.

The major advantage of the layer 2 mode is its universality: it will work on any ethernet network, with no special hardware required, not even fancy routers.

In layer 2 mode, all traffic for a service IP goes to one node. From there, kube-proxy spreads the traffic to all the service’s pods.

In that sense, layer 2 does not implement a load-balancer. Rather, it implements a failover mechanism so that a different node can take over should the current leader node fail for some reason.

If the leader node fails for some reason, failover is automatic: the old leader’s lease times out after 10 seconds, at which point another node becomes the leader and takes over ownership of the service IP.


### Limitations
Layer 2 mode has two main limitations you should be aware of: single-node bottlenecking, and potentially slow failover.

As explained above, in layer2 mode a single leader-elected node receives all traffic for a service IP. This means that your service’s ingress bandwidth is limited to the bandwidth of a single node. This is a fundamental limitation of using ARP and NDP to steer traffic.

In the current implementation, failover between nodes depends on cooperation from the clients. When a failover occurs, MetalLB sends a number of gratuitous layer 2 packets (a bit of a misnomer - it should really be called “unsolicited layer 2 packets”) to notify clients that the MAC address associated with the service IP has changed.

Most operating systems handle “gratuitous” packets correctly, and update their neighbor caches promptly. In that case, failover happens within a few seconds. However, some systems either don’t implement gratuitous handling at all, or have buggy implementations that delay the cache update.

All modern versions of major OSes (Windows, Mac, Linux) implement layer 2 failover correctly, so the only situation where issues may happen is with older or less common OSes.

To minimize the impact of planned failover on buggy clients, you should keep the old leader node up for a couple of minutes after flipping leadership, so that it can continue forwarding traffic for old clients until their caches refresh.

During an unplanned failover, the service IPs will be unreachable until the buggy clients refresh their cache entries.

### Howto
- Set secret in `11_metallb-secret.yaml`
- Choose the operation mode and IP range in `13_metallb-config.yaml`
- Deploy MetallLB and config: `kubectl apply -f *.yaml`

And you are done. To expose services just create load balancer services like in `test/example-service.yaml`

## Reading

- [Installation](https://metallb.universe.tf/installation/)
- [Configuration](https://metallb.universe.tf/configuration/)
- [Usage](https://metallb.universe.tf/usage/)
- [GitHub](https://github.com/danderson/metallb)
- [Helm Chart](https://github.com/danderson/metallb/tree/master/helm-chart)

[1]: https://metallb.universe.tf
[2]: https://metallb.universe.tf/concepts/layer2
[3]: https://metallb.universe.tf/installation/network-addons/
