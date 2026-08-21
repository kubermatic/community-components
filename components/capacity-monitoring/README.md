# On-premises capacity monitoring/management

## Background

This document describes approaches to capacity monitoring and management using on-premises platforms supported by KKP.

The goal is to integrate monitoring of underlying infrastructure with MLA stack of KKP, so that platform administrators can have the information about the usage patterns and predict incoming issues.

Kubermatic Kubernetes Platform is not managing the underlying infrastructure and as such, the integration makes heavy used of external components which may or may not work correctly on particular environments. The document describes the general approaches and possibilities, which might have to be adapted to specific needs.

## General setup

Monitoring and management of environment's capacity with KKP's MLA stack can be approached from two angles: 

1. Monitoring the performance of the environment via metrics.
   Set of Prometheus exporters can be used to gather basic metrics regarding the eprformance of the environment, which then can be used for further analysis and alerting.
2. Monitoring the activities of machine-controllers, which are often first components showing problems with environment's capacity.
   Machine-controllers metrics are covered by the Prometheus rules included in KKP, but in case of some providers, it is also possible to monitor the logs of the controller using loki, searching for patterns identifying failures due to provider's capacity.

In case of either of these approaches, specifics regarding enabling the metrics and alerts in the MLA stack can be found in [the documentation regarding seed cluster MLA](https://docs.kubermatic.com/kubermatic/v2.20/tutorials_howtos/monitoring_logging_alerting/master_seed/customization/).

## Metrics-based monitoring

The setup requires administrators to install specific metrics exporters for the environment that the user-clusters are running on. The exporters should be installed together with the seed clusters and require access to APIs of the providers used with the seed cluster. Proposed exporters and additional rules are built in a way that's coherent across the environments - alerts and metrics are correctly labeled to distinguish the environments.

Capacity monitoring is based on synthetic `resource:infrastructure_saturation:ratio` metric, which exists for different resource types, signified by `service` labels:
* `service: infrastructure:datastore` - information about datastores/local stores,
* `service: infrastructure:cpu` - information about (v)CPUs,
* `service: infrastructure:memory` - information about memory (RAM) usage.

`resource:infrastructure_saturation:ratio` is a metric of numerical value - 0.0 means 0% saturation (e.g. no resources used), 1.0 is 100%. Note that it is possible for the metric to go over 1.0 due to infrastructure overprovisioning, especially in case of vCPUs.

Due to acyclical and irregular nature of resources' usage, further predictions are based on average values over 7 days (moving window) for each of the metrics.

Alerts covering the events of overcomitting resources have been defined as follows:

* `InfrastructureSaturationOutOfBounds` - current usage is higher than a specified threshold.
* `PrognosedInfrastructureLimitReachedIn14days` - predicted usage in 14 days reaches 100% (vCPU metrics are excluded from this alert)

### vSphere

Suggested exporter: [vmware-exporter](https://github.com/pryorda/vmware_exporter)

Installation method: [helm chart](../vmware-exporter/Chart.yaml)

Suggested rulesets: [included](prometheus-rules/vmware.yaml)

### Nutanix

Suggested exporter: [nutanix-exporter](https://github.com/claranet/nutanix-exporter)

Installation method: [helm chart](../nutanix-exporter/Chart.yaml)

Suggested rulesets: TBD

### Openstack

Suggested exporter: [openstack-exporter](https://github.com/openstack-exporter/openstack-exporter)

Installation method: [helm chart](https://github.com/openstack-exporter/helm-charts)

Suggested rulesets: [included](prometheus-rules/openstack.yaml)

### KubeVirt

TBD

## Logging based monitoring

TBD
