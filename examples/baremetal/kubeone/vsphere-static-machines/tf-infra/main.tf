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

provider "vsphere" {
  /*
  See https://www.terraform.io/docs/providers/vsphere/index.html#argument-reference
  for config options reference
  */
}

locals {
  resource_pool_id = var.resource_pool_name == "" ? data.vsphere_compute_cluster.cluster.resource_pool_id : data.vsphere_resource_pool.pool[0].id

  rendered_lb_config = templatefile("./etc_gobetween.tpl", {
    lb_targets = vsphere_virtual_machine.control_plane.*.default_ip_address,
  })
}

data "vsphere_datacenter" "dc" {
  name = var.dc_name
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.compute_cluster_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  count         = var.resource_pool_name == "" ? 0 : 1
  name          = var.resource_pool_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "cp_template" {
  name          = var.control_plane_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_folder" "folder" {
  path          =  var.folder_name
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "control_plane" {
  depends_on = [
    vsphere_folder.folder
  ]
  count            = var.control_plane_count
  name             = "${var.cluster_name}-cp-${count.index + 1}"
  resource_pool_id = local.resource_pool_id
  folder           = var.folder_name
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 2
  memory           = var.control_plane_memory
  guest_id         = data.vsphere_virtual_machine.cp_template.guest_id
  scsi_type        = data.vsphere_virtual_machine.cp_template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.cp_template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = var.control_plane_disk_size
    thin_provisioned = data.vsphere_virtual_machine.cp_template.disks[0].thin_provisioned
    eagerly_scrub    = data.vsphere_virtual_machine.cp_template.disks[0].eagerly_scrub
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.cp_template.id
  }

  vapp {
    properties = {
      hostname    = "${var.cluster_name}-cp-${count.index + 1}"
      public-keys = file(var.ssh_public_key_file)
    }
  }

  extra_config = {
    "disk.enableUUID" = "TRUE"
  }

  lifecycle {
    ignore_changes = [
      vapp[0].properties,
      tags,
    ]
  }
}

data "vsphere_virtual_machine" "lb_template" {
  name          = var.load_balancer_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "lb" {
  depends_on = [
    vsphere_folder.folder,
    vsphere_virtual_machine.control_plane
  ]
  count            = 1
  name             = "${var.cluster_name}-lb-${count.index + 1}"
  resource_pool_id = local.resource_pool_id
  folder           = var.folder_name
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 1
  memory           = 1024
  guest_id         = data.vsphere_virtual_machine.lb_template.guest_id
  scsi_type        = data.vsphere_virtual_machine.lb_template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.lb_template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = var.load_balancer_disk_size
    thin_provisioned = data.vsphere_virtual_machine.lb_template.disks[0].thin_provisioned
    eagerly_scrub    = data.vsphere_virtual_machine.lb_template.disks[0].eagerly_scrub
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.lb_template.id
  }

  vapp {
    properties = {
      hostname    = "${var.cluster_name}-lb-${count.index + 1}"
      public-keys = file(var.ssh_public_key_file)
    }
  }

  lifecycle {
    ignore_changes = [
      vapp[0].properties,
      tags,
    ]
  }

  connection {
    type = "ssh"
    host = self.default_ip_address
    user = var.ssh_username
  }

  provisioner "remote-exec" {
    script = "gobetween.sh"
  }
}

resource "null_resource" "lb_config" {
  depends_on = [
    vsphere_virtual_machine.control_plane
  ]
  triggers = {
    cluster_instance_ids = join(",", vsphere_virtual_machine.control_plane.*.id)
    config               = local.rendered_lb_config
  }

  connection {
    user = var.ssh_username
    host = vsphere_virtual_machine.lb[0].default_ip_address
  }

  provisioner "file" {
    content     = local.rendered_lb_config
    destination = "/tmp/gobetween.toml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/gobetween.toml /etc/gobetween.toml",
      "sudo systemctl restart gobetween",
    ]
  }
}


##### STATIC WORKERS
data "vsphere_virtual_machine" "worker_template" {
  name          = var.worker_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "static_workers" {
  depends_on = [
    vsphere_folder.folder
  ]
  count            = var.worker_count
  name             = "${var.cluster_name}-worker-${count.index + 1}"
  resource_pool_id = local.resource_pool_id
  folder           = var.folder_name
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = var.worker_cpu
  memory           = var.worker_memory
  guest_id         = data.vsphere_virtual_machine.worker_template.guest_id
  scsi_type        = data.vsphere_virtual_machine.worker_template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.worker_template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = var.worker_disk
    thin_provisioned = data.vsphere_virtual_machine.worker_template.disks[0].thin_provisioned
    eagerly_scrub    = data.vsphere_virtual_machine.worker_template.disks[0].eagerly_scrub
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.worker_template.id
  }

  vapp {
    properties = {
      hostname    = "${var.cluster_name}-worker-${count.index + 1}"
      public-keys = file(var.ssh_public_key_file)
    }
  }

  extra_config = {
    "disk.enableUUID" = "TRUE"
  }

  lifecycle {
    ignore_changes = [
      vapp[0].properties,
      tags,
    ]
  }
}