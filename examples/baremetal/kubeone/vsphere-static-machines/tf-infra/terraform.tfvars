cluster_name = "tobi-baremetal-sim"
dc_name = "dc-1"
compute_cluster_name = "cl-1"
datastore_name = "exsi-nas"
network_name = "Loodse Default"

ssh_public_key_file = "~/.ssh/id_rsa_loodse.pub"
ssh_username = "ubuntu"

load_balancer_template = "ubuntu-18.04-10.2020.ova"
load_balancer_disk_size = 10
control_plane_count = 3
control_plane_memory = 4096
control_plane_template = "ubuntu-18.04-10.2020.ova"

worker_template = "ubuntu-18.04-10.2020.ova"
worker_memory = 4096
worker_os = "ubuntu"
worker_count = 2  #manage by ./machines/*.yaml
folder_name = "kubermatic/tobi-baremetal-sim"
//resource_pool_name = "tobi-k1"