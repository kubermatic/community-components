### for more options, see `variables.tf` file

#api_token =  "TODO ENTER-YOUR-ACCOUNT-TOKEN"

project_id   = "todo-project-id" #Your KKP Project ID

cluster_name           = "vsphere-terraform-example"
cluster_spec_folder    = "vsphere_cluster_example"
dc                     = "vsphere"
credential_preset_name = "kubermatic-new-dc"
kubernetes_version     = "1.26.9"

cloud_provider         = "vsphere"
machine_replica        = 1
machine_osp_name       = "osp-ubuntu"
vsphere_machine_spec   = {
  cpus        = 2
  memory      = 8192
  disk_size   = 20
  template_vm = "kkp-ubuntu-22.04"
}