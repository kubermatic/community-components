# Example of KKP user cluster terraform module usage (cluster)

terraform {
  required_providers {
    restapi = {
      source  = "Mastercard/restapi"
      version = "1.18.2"
    }
  }
}

provider "restapi" {
  # Configuration options
  uri                  = var.api_base_url
  debug                = true
  write_returns_object = true
  headers              = {
    accept        = "application/json"
    Content-Type  = "application/json"
    authorization = "Bearer ${var.api_token}"
  }
}

locals {
  cluster_spec = templatefile(
    "${path.module}/${var.cluster_spec_folder}/cluster.json",
    {
      "dc" : var.dc,
      "cluster_name" : var.cluster_name,
      "kubernetes_version" : var.kubernetes_version,
      "credential" : var.credential_preset_name,
      "cni_plugin" : var.cni_plugin,
      "cni_version" : var.cni_version
    }
  )
  machine_spec = templatefile(
    "${path.module}/${var.cluster_spec_folder}/machinedeployment.json",
    {
      "machine_name" : "${var.cluster_name}-node",
      "kubernetes_version" : var.kubernetes_version,
      "replicas" : var.kubevirt_machine.replicas,
      "cpus" : var.kubevirt_machine.cpus,
      "memory" : var.kubevirt_machine.memory,
      "disk_size" : var.kubevirt_machine.disk_size,
      "primaryDiskOSImage" : var.kubevirt_machine.os_image_url,
      "primaryDiskStorageClass" : var.kubevirt_machine.primary_disk_storage_class
    }
  )
  addon_spec = file("${path.module}/${var.cluster_spec_folder}/addon.json")
}

resource "restapi_object" "cluster_apply" {
  path          = "/v2/projects/${var.project_id}/clusters"
  update_method = "PATCH"
  data          = "{ \"cluster\": ${local.cluster_spec} }"
  update_data   = local.cluster_spec
}

locals {
  cluster_info        = jsondecode(restapi_object.cluster_apply.api_response)
  kubeconfig_endpoint = "${var.api_base_url}/v2/projects/${var.project_id}/clusters/${local.cluster_info.id}/kubeconfig"
}

## trigger to get excuted on change
data "local_file" "common_script" {
  filename = var.common_bash_file_path
}

resource "null_resource" "wait_cluster_creation" {
  depends_on = [restapi_object.cluster_apply, data.local_file.common_script]
  triggers   = {
    script_hash = md5(data.local_file.common_script.content)
  }
  provisioner "local-exec" {
    command     = "source _common.sh; waitForClusterHealth ${local.cluster_info.id}"
    environment = {
      KKP_PROJECT = var.project_id
      KKP_TOKEN   = var.api_token
      KKP_API     = "${var.api_base_url}/v2"
    }
  }
}

resource "restapi_object" "machinedeployment_create" {
  path          = "/v2/projects/${var.project_id}/clusters/${local.cluster_info.id}/machinedeployments"
  update_method = "PATCH"
  data          = local.machine_spec
  depends_on    = [
    restapi_object.cluster_apply,
    null_resource.wait_cluster_creation
  ]
}

resource "restapi_object" "addon_create" {
  path          = "/v2/projects/${var.project_id}/clusters/${local.cluster_info.id}/addons"
  update_method = "PATCH"
  data          = local.addon_spec
  depends_on    = [
    restapi_object.machinedeployment_create,
    null_resource.wait_cluster_creation
  ]
}
resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "wget --tries=10 --retry-on-http-error=404 --waitretry=60 ${local.kubeconfig_endpoint} --header 'Authorization: Bearer ${var.api_token}' -O kubeconfig-${local.cluster_info.id}"
  }

  depends_on = [
    restapi_object.cluster_apply,
    restapi_object.machinedeployment_create,
    null_resource.wait_cluster_creation
  ]
}

output "k8s_id" {
  description = "K8S ID"
  value       = local.cluster_info.id
}

output "k8s_url" {
  description = "K8S URL"
  value       = local.cluster_info.status.url
}

output "k8s_name" {
  description = "K8S Name"
  value       = local.cluster_info.name
}

output "k8s_kubeconfig" {
  depends_on  = [null_resource.kubeconfig]
  description = "K8S kubeconfig"
  value       = "kubeconfig-${local.cluster_info.id}"
}
