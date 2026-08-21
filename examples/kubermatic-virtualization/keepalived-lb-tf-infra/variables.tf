#/*
#Copyright 2019 The KubeOne Authors.
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
#*/

#TODO CLEANUP VARS
variable "cluster_name" {
  description = "Name of the cluster"
  type        = string

  validation {
    condition = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$", var.cluster_name))
    error_message = "Value of cluster_name should be lowercase and can only contain alphanumeric characters and hyphens(-)."
  }
}

variable "apiserver_alternative_names" {
  description = "subject alternative names for the API Server signing cert."
  default = []
  type = list(string)
}

variable "ssh_username" {
  description = "SSH user, used only in output"
  default     = "root"
  type        = string
}


variable "bastion_host" {
  description = "ssh jumphost (bastion) hostname"
  default     = ""
  type        = string
}

variable "bastion_port" {
  description = "ssh jumphost (bastion) port"
  type        = number
  default     = 22
}

variable "bastion_username" {
  description = "ssh jumphost (bastion) username"
  default     = ""
  type        = string
}

variable "api_vip" {
  default     = ""
  description = "virtual IP address for Kubernetes API"
  type        = string
}
#
variable "vrrp_interface" {
  default     = "ens192"
  description = "network interface for API virtual IP"
  type        = string
}

variable "vrrp_router_id" {
  default     = 42
  description = "vrrp router id for API virtual IP. Must be unique in used subnet"
  type        = number
}

variable "control_plane_hosts" {
  type = list(string)
  description = "IPs / Hostname list of master nodes to use for the go-between"
}

variable "ssh_private_key_file" {
  description = "SSH private key file"
  type        = string
}