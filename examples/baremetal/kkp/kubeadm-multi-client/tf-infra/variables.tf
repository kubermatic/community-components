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

variable "cluster_name" {
  description = "Name of the cluster"
}

variable "ssh_public_key_file" {
  description = "SSH public key file"
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_port" {
  description = "SSH port to be used to provision instances"
  default     = 22
}

variable "ssh_username" {
  description = "SSH user, used only in output"
  default     = "root"
}

variable "ssh_private_key_file" {
  description = "SSH private key file used to access instances"
  default     = ""
}

variable "ssh_agent_socket" {
  description = "SSH Agent socket, default to grab from $SSH_AUTH_SOCK"
  default     = "env:SSH_AUTH_SOCK"
}

# provider specific settings

variable "dc_name" {
  default     = "dc-1"
  description = "datacenter name"
}

variable "datastore_name" {
  default     = "datastore1"
  description = "datastore name"
}

variable "datastore_cluster_name" {
  default     = ""
  description = "datastore cluster name"
}

variable "resource_pool_name" {
  default     = ""
  description = "cluster resource pool name"
}

variable "folder_name" {
  default     = "kubeone"
  description = "folder name"
}

variable "network_name" {
  default     = "public"
  description = "network name"
}

variable "compute_cluster_name" {
  default     = "cl-1"
  description = "internal vSphere cluster name"
}

###############  WORKER SETTINGS

variable "worker_os" {
  description = "OS to run on worker machines"

  # valid choices are:
  # * ubuntu
  # * centos
  # * coreos
  default = "ubuntu"
}

variable "worker_memory" {
  default     = 2048
  description = "memory size of each worker node in MB"
}

variable "worker_disk" {
  default     = 20
  description = "disk size of each worker node in GB"
}

variable "worker_cpu" {
  default = 2
  description = "CPU size of workers"
}

variable "worker_count" {
  default     = 2
  description = "number of workers"
}

variable "worker_template" {
  default     = "ubuntu-18.04"
  description = "template name"
}