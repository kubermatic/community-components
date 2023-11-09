
### for more options, see `variables.tf` file

#api_token =  "TODO ENTER-YOUR-ACCOUNT-TOKEN"

project_id   = "todo-project-id" #Your KKP Project ID
cluster_name = "kubevirt-terraform-example"
cluster_spec_folder    = "kubevirt_cluster_example"
dc                     = "kv-europe-west3-c"
credential_preset_name = "kubermatic-new-dc"
kubernetes_version     = "1.26.9"
machine_replica        = 1
machine_osp_name       = "osp-ubuntu"
kubevirt_machine_spec  = {
  cpus                       = 2
  memory                     = "4096Mi"
  disk_size                  = "25Gi"
  os_image_url               = "http://image-repo.kube-system.svc/images/ubuntu-22.04.img"
  primary_disk_storage_class = "px-csi-db"
}