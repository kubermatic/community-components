/*
Copyright 2019 The KubeOne Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
# locals {
#   hostnames = var.hostnames == null ? formatlist("${var.cluster_name}-cp-%d", [1, 2, 3]) : var.hostnames
# }

output "kubev_api" {
  description = "kube-apiserver LB endpoint"

  value = {
    endpoint                    = var.api_vip
    apiserver_alternative_names = var.apiserver_alternative_names
  }
}


output "kubev_hosts" {
  description = "Control plane endpoints to SSH to"

  value = {
    control_plane = {
      cluster_name    = var.cluster_name
      private_address = var.control_plane_hosts
      # hostnames       = local.hostnames
      #      public_address       = var.control_plane_external_ips
      #      ssh_agent_socket     = var.ssh_agent_socket
      #      ssh_port             = var.ssh_port
      ssh_user     = var.ssh_username
      bastion      = var.bastion_host
      bastion_port = var.bastion_port
      bastion_user = var.bastion_username
      # untaint      = true
      # uncomment to following to set those kubelet parameters. More into at:
      # https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/
      # kubelet            = {
      #   system_reserved = "cpu=200m,memory=200Mi"
      #   kube_reserved   = "cpu=200m,memory=300Mi"
      #   eviction_hard   = ""
      #   max_pods        = 220
      # }
      # labels               = var.control_plane_labels
    }
  }
}
