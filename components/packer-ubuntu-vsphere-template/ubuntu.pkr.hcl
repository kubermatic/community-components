# Copyright 2020 The Kubermatic Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

source "vsphere-clone" "ubuntu" {
  vcenter_server      = var.vcenter_server
  username            = var.vcenter_user
  password            = var.vcenter_password
  insecure_connection = var.vcenter_insecure

  template            = var.vcenter_template
  datacenter          = var.vcenter_datacenter
  cluster             = var.vcenter_cluster
  datastore           = var.vcenter_datastore
  network             = var.vcenter_network
  convert_to_template = false

  vm_name             = var.output_vm_name
  folder              = var.output_vm_folder

  communicator        = "ssh"
  ssh_username        = "ubuntu"
}

build {
  sources = [
    "source.vsphere-clone.ubuntu"
  ]

  provisioner "shell" {
    inline = [
      "ls /"
    ]
  }

  # DON'T DELETE!
  # if cloud init is not cleaned, the machines will not dhcp properly
  # if machine-id is not truncated, all machines will grab on to the exact same dhcp lease
  provisioner "shell" {
    inline = [
      "sudo cloud-init clean",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo rm /var/lib/dbus/machine-id",
      "sudo ln -s /etc/machine-id /var/lib/dbus/machine-id"
    ]
  }
}
