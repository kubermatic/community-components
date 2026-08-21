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

terraform {
  backend "local" {
    path = "../../git-submodules/secrets/kubev-offline-ref/keepalived-lb-infra.tfstate"
  }
}

resource "null_resource" "keepalived_setup" {
  count = length(var.control_plane_hosts)
  triggers = {
    cluster_instance_ids = join(",", var.control_plane_hosts)
    virt_api_ip          = var.api_vip
  }

  connection {
    type        = "ssh"
    user        = var.ssh_username
    host        = var.control_plane_hosts[count.index]
    private_key = file(var.ssh_private_key_file)
    # bastion_host = var.bastion_host
    # bastion_port = var.bastion_port
    # bastion_user = var.bastion_username
  }
  provisioner "remote-exec" {
    script = "keepalived.sh"
  }
}

resource "random_string" "keepalived_auth_pass" {
  length  = 8
  special = false
}

resource "null_resource" "keepalived_config" {
  count = length(var.control_plane_hosts)

  triggers = {
    cluster_instance_ids = join(",", var.control_plane_hosts)
    virt_api_ip          = var.api_vip
  }
  depends_on = [
    null_resource.keepalived_setup
  ]
  connection {
    type        = "ssh"
    user        = var.ssh_username
    host        = var.control_plane_hosts[count.index]
    private_key = file(var.ssh_private_key_file)
    # bastion_host = var.bastion_host
    # bastion_port = var.bastion_port
    # bastion_user = var.bastion_username

  }

  provisioner "file" {
    content = templatefile("./etc_keepalived_keepalived_conf.tpl", {
      STATE         = count.index == 0 ? "MASTER" : "BACKUP",
      APISERVER_VIP = var.api_vip,
      INTERFACE     = var.vrrp_interface,
      ROUTER_ID     = var.vrrp_router_id,
      PRIORITY      = count.index == 0 ? "101" : "100",
      AUTH_PASS     = random_string.keepalived_auth_pass.result
    })
    destination = "/tmp/keepalived.conf"
  }

  provisioner "file" {
    content = templatefile("./etc_keepalived_check_apiserver_sh.tpl", {
      APISERVER_VIP = var.api_vip
    })
    destination = "/tmp/check_apiserver.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/keepalived",
      "sudo mv /tmp/keepalived.conf /etc/keepalived/keepalived.conf",
      "sudo mv /tmp/check_apiserver.sh /etc/keepalived/check_apiserver.sh",
      "sudo chmod +x /etc/keepalived/check_apiserver.sh",
      "sudo systemctl restart keepalived",
    ]
  }
}
