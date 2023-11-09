# Example of KKP user cluster terraform variables
variable "api_base_url" {
  description = "KKP base URL"
  type        = string
  default     = "https://mgmt-prod.cp.3ascloud.de/api"
}

variable "api_token" {
  description = "KKP admin token, see https://docs.kubermatic.com/kubermatic/v2.21/architecture/concept/kkp-concepts/service-account/using-service-account/"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.api_token) > 0
    error_message = "The api_token value must be a set, see https://docs.kubermatic.com/kubermatic/v2.21/architecture/concept/kkp-concepts/service-account/using-service-account"
  }
}

variable "common_bash_file_path" {
  description = "Helper file for some bash functions"
  default     = "_common.sh"
}

# example project id = duwqon5jef
variable "project_id" {
  description = "KKP Project Id"
  type        = string
  default     = "TODO_PROJECT_ID"
}

variable "dc" {
  description = "Datacenter name at a Kubermatic Seed"
  type        = string
  default     = "fra-prod"
}

variable "cluster_name" {
  description = "User Cluster Name"
  type        = string
  default     = "test-tf-cluster"
}
variable "cluster_spec_folder" {
  description = "Folder what contains the cluster spec jsons"
  type        = string
  default     = "kubevirt_cluster_example"
}
variable "kubernetes_version" {
  description = "User Cluster Kubernetes Version"
  type        = string
  default     = "1.26.9"
}

variable "credential_preset_name" {
  description = "Preset to use while creating the user cluster"
  type        = string
  default     = "TODO-ADD-PRESET-NAME"
}

variable "cni_plugin" {
  description = "CNI Pluging name: cilium or canal"
  type        = string
  default     = "cilium"
}

variable "cni_version" {
  description = "Version of the CNI Plugin"
  type        = string
  default     = "1.13.8"
}
variable "kubevirt_machine" {
  description = "A selection of parameter for a kubevirt machine object"
  type = object({
    replicas     = number
    cpus         = number
    memory       = string
    disk_size    = string
    os_image_url = string
    primary_disk_storage_class = string
  })
  default = {
    replicas     = 5
    cpus         = 8
    memory       = "32768Mi"
    disk_size    = "150Gi"
    os_image_url = "http://TODO.your.image.url/vms/ubuntu-22.04.img"
    primary_disk_storage_class = "TODO_YOUR_STORAGE_CLASS"
  }
}