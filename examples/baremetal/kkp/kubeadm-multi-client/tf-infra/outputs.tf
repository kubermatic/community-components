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

output "kubeone_worker_hosts" {
  description = "Control plane endpoints to SSH to"

  value = {
    static_worker = {
      private_address = []
      hostnames = vsphere_virtual_machine.static_workers[*].vapp[0].properties.hostname
      public_address = vsphere_virtual_machine.static_workers.*.default_ip_address
      ssh_agent_socket = var.ssh_agent_socket
      ssh_port = var.ssh_port
      ssh_private_key_file = var.ssh_private_key_file
      ssh_user = var.ssh_username
    }
  }
}

