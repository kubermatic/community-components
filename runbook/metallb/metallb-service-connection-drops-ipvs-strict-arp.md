# Connection Drops of Service Type LoadBalancer provided by MetalLB
Date of creation: 2021-07-05

## Situation
* ARP resolving at the internal tenant network 
  * requester got an ARP reply and cached it for some timeout, what get extend by a received package of the IP/MAC-Address   
* At Networks behind Firewall this caching/extending of ARP resolution didn't happen, because ARP Spoofing protection set a hard timeout. So the Firewall will enforce to send ARP request periodically after the timeout is reached
  * Together with multiple NODEs responding their IP by the ARP request, an IP change get triggered by chance (the first received ARP response wins). This behaviour could trigger the IP change and result into the seen connection drop at long opening websocket. After the client reconnect all works, as every Kubernetes Node serve the service by design. 
* To analyse it debug shows multiple macs (more see [MetalLB Troubleshooting](https://metallb.universe.tf/configuration/troubleshooting/#arping)) for the same IP:
  `arping -I ens192 10.53.18.1 -c 5 -b`
  ```
  ARPING -------------------
  ARPING 10.53.18.1 from 10.53.19.31 ens192
  Unicast reply from 10.53.18.1 [00:50:56:AC:EF:B6]  0.771ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:36:A4]  0.945ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:34:C9]  0.997ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:4B:04]  1.209ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:DC:88]  1.414ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:CE:15]  1.471ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:67:14]  1.642ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:10:A0]  1.696ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:06:49]  1.830ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:2F:80]  1.877ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:74:78]  1.918ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:D6:51]  1.975ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:DC:88]  2.137ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:96:59]  2.269ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:96:59]  0.712ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:EF:B6]  0.841ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:4B:04]  0.863ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:CE:15]  0.878ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:67:14]  0.892ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:34:C9]  0.907ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:74:78]  0.921ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:10:A0]  0.935ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:DC:88]  0.950ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:2F:80]  0.963ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:06:49]  0.977ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:D6:51]  0.989ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:36:A4]  1.003ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:DC:88]  1.053ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:96:59]  0.832ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:EF:B6]  0.999ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:4B:04]  1.014ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:D6:51]  1.017ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:CE:15]  1.021ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:34:C9]  1.082ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:10:A0]  1.090ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:06:49]  1.093ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:2F:80]  1.096ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:67:14]  1.124ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:DC:88]  1.135ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:74:78]  1.138ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:DC:88]  1.164ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:36:A4]  1.226ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:EF:B6]  0.665ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:36:A4]  0.704ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:4B:04]  0.708ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:DC:88]  0.738ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:74:78]  0.753ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:2F:80]  0.756ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:10:A0]  0.759ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:CE:15]  0.881ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:06:49]  0.889ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:96:59]  0.892ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:D6:51]  0.896ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:34:C9]  0.900ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:67:14]  0.903ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:DC:88]  0.943ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:36:A4]  0.989ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:EF:B6]  1.032ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:4B:04]  1.037ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:DC:88]  1.041ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:34:C9]  1.046ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:96:59]  1.049ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:10:A0]  1.051ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:74:78]  1.054ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:67:14]  1.057ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:CE:15]  1.059ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:D6:51]  1.062ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:06:49]  1.065ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:2F:80]  1.068ms
  Unicast reply from 10.53.18.1 [00:50:56:AC:DC:88]  1.070ms
  Sent 5 probes (5 broadcast(s))
  Received 70 response(s)
  ```
  
## Resolution (so far):
* The ARP handling is a setting of the kubeproxy of Kubernetes. Kubeproxy has to modes - `iptables` and `IPVS`. As kubeproxy behaviour is at every mode different at the used `IPVS` an additional flag `strictARP` need to be set at the `KubeProxyConfiguration` config object.
* After the change every ARP request result in only one MAC of one node, constantly without rely on the "keep it stable as long as the client has traffic" behaviour.
* The testing script [`arp-status-script.sh`](./helper/arp-status-script.sh) proves that the resolved MAC is still stable after now ~24 hours.
* For more helper script see [`helper`](./helper)

After the change to the strict ARP mode, the MAC is stable resolvable:
```
ARPING -------------------
ARPING 10.53.18.1 from 10.53.19.31 ens192
Unicast reply from 10.53.18.1 [00:50:56:AC:DC:88]  1.045ms
Unicast reply from 10.53.18.1 [00:50:56:AC:DC:88]  0.934ms
Unicast reply from 10.53.18.1 [00:50:56:AC:DC:88]  0.947ms
Unicast reply from 10.53.18.1 [00:50:56:AC:DC:88]  0.872ms
Unicast reply from 10.53.18.1 [00:50:56:AC:DC:88]  3.755ms
Sent 5 probes (5 broadcast(s))
Received 5 response(s)
```

## TODOs:
- test manual patch configmap at Kubermatic test cluster (done) - see `Manual Fix`
  - execute test setup again at customer, to see if this solves the problem
  - Result: seams to be stable and now disconnects
- **quick fix: (done)** 
- open issue at KKP and talk about "default" setting of strict mode: https://github.com/kubermatic/kubermatic/issues/7309
- open issue at Kubeone: https://github.com/kubermatic/kubeone/issues/1409

### Manual KKP Fix:
1. set cluster to `pause: true`, skip reconciling
2. In user cluster edit config map: `kubectl edit cm -n kube-system kube-proxy`, see [metallb kubeproxy IPVS settings](https://metallb.universe.tf/installation/#preparation) 
```yaml
    mode: ipvs
    ipvs:
      strictARP: true
```
3. restart DS: `kubectl rollout restart -n kube-system ds kube-proxy`

### KKP Custom Addon Fix:
KKP override values by a custom addon see [kubermatic-addons/custom-addon/kube-proxy-ipvs-patch](../../kubermatic-addons/archive/kube-proxy-ipvs-patch) for the kubeproxy at the customer environments.
- Create custom Addon image, see [kubermatic-addons](../../kubermatic-addons)
- Use custom addon image reference in your Kubermatic Configuration
- Update the KubermaticConfiguration - remove orig addon + add custom addon. The latest defaul values can be found at the [kubermatic github repo `docs/zz_generated.kubermaticConfiguration.yaml`](https://github.com/kubermatic/kubermatic/blob/master/docs/zz_generated.kubermaticConfiguration.yaml)
```yaml
apiVersion: operator.kubermatic.io/v1alpha1
kind: KubermaticConfiguration
metadata:
  name: kubermatic
  namespace: kubermatic
spec:
  # ...
  userCluster:
    # Addons controls the optional additions installed into each user cluster.
    addons:
      # Kubernetes controls the addons for Kubernetes-based clusters.
      kubernetes:
        # DefaultManifests is a list of addon manifests to install into all clusters.
        # Mutually exclusive with "default".
        defaultManifests: |-
          apiVersion: v1
          kind: List
          items:
          ### some more addons
          
          ##### >>> removed as long as https://github.com/kubermatic/kubermatic/issues/7309 is not in place
          #- apiVersion: kubermatic.k8s.io/v1
          #  kind: Addon
          #  metadata:
          #    name: kube-proxy
          #    labels:
          #      addons.kubermatic.io/ensure: true
         
          ### some more addons
         
          ########### >>> add Custom ADDONS
          - apiVersion: kubermatic.k8s.io/v1
            kind: Addon
            metadata:
              name: kube-proxy-ipvs-patch
              labels:
                addons.kubermatic.io/ensure: true
        dockerRepository: YOUR-REPO
        dockerTagSuffix: VERISON-OF-ADDON 
```
- Apply the change KubermaticConfiguration and test user clusters are still working

**ATTENTION:** ON EVERY VERSION upgrade the operator needs to ensure that addon image and the used custom addon manifest is still match with the maintainers version, see latest for master: [github.com/kubermatic/kubermatic `/addons/kube-proxy`](https://github.com/kubermatic/kubermatic/tree/master/addons/kube-proxy)

### KubeOne fix:
Add to the kubeone addons an overwrite for the kubeproxy config file - after the cluster is created:
1. Extract current config map: `kubectl get cm -n kube-system kube-proxy -o yaml | kexp > addons/temp.kubeproxy.config.fix` (kexp just removes not needed status fields, see [fubectl](https://github.com/kubermatic/fubectl))
2. Change the values
```yaml
mode: ipvs
ipvs:
  strictARP: true
```
3.Apply the change and restart kubeproxy daemonset:
```
kubectl rollout restart -n kube-system ds kube-proxy
```

## How to find the resolving Node with MetalLB Service Type LoadBalancer
Find your service at the user cluster:
```
kubectl get svc -A | grep -i loadbalancer
```

Detect the ARP entry responding MAC:
- Connect to a worker node by `ssh` or `konsole` and ensure you are `root`
- Get the mac `arping -I ens192 10.53.18.1 -c 1 -b`
  ```
  ARPING 10.53.18.1 from 10.53.19.31 ens192
  Unicast reply from 10.53.18.1 [00:50:56:AC:DC:88]  1.733ms
  Sent 1 probes (1 broadcast(s))
  Received 1 response(s)
  ```
  ==> Normally only one MAC should come back, if not check the IPVs settings of the `kubeproxy` config map, see [metallb kubeproxy IPVS settings](https://metallb.universe.tf/installation/#preparation)
- Find out the IP interfaces what's listen to the MAC
  ```
  arp -a | grep -i 00:50:56:AC:DC:88
  ```
  ```
  node-pool-85bf6f64f4-ggbmm (10.53.18.1) at 00:50:56:ac:dc:88 [ether] on ens192
  node-pool-85bf6f64f4-86ddb.kub.bgh.manufacturing.wacker.corp (10.53.19.34) at 00:50:56:ac:dc:88 [ether] on ens192
  ```
- find out what node uses this IP:
  ```
  kubectl get node -o wide | grep 10.53.19.34
  ```
  ```
node-pool-85bf6f64f4-86ddb   Ready    <none>   12d   v1.20.5   10.53.19.34   10.53.19.34   Ubuntu 20.04.2 LTS   5.4.0-66-generic   docker://19.3.15
  ```