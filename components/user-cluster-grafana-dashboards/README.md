# Custom dashboards for User-Cluster MLA Grafan

You can pre-provision any dashboard in the user-clusters by adding them as a `ConfigMap` in `mla` namespace of the appropriate seed. The ConfigMap name must start with prefix  `grafana-dashboards-` e.g grafana-dashboards-minio.

In this directory, we have given 2 dashboards to see nginx-ingress-controller's performance and minio performance.

We also recommend you to deploy these via ArgoCD / or any other gitops tool directly in the seed cluster.