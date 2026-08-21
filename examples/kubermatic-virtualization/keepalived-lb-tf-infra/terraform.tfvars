cluster_name         = "kubev-cluster"
api_vip              = "10.0.2.35"
apiserver_alternative_names = ["kubev.demo.kubermatic.io"]
ssh_username         = "root"
ssh_private_key_file = "../../../git-submodules/secrets/ssh/id_rsa"

vrrp_interface = "ens4" #internal communication device
vrrp_router_id = 36 #uniqe per subnet

control_plane_hosts = [
  "10.0.2.37",
  "10.0.2.44",
  "10.0.2.43"
]