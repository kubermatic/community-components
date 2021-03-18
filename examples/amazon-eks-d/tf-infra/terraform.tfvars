cluster_name = "eksd-kubeone"

# Currently, machine-controller doesn’t support Amazon Linux 2, so we will
# use KubeOne Static Worker nodes. The static worker nodes are managed
# by KubeOne, Terraform, and kubeadm, and are defined by the
# static_workers_count variable below.
initial_machinedeployment_replicas = 0

# This variable doesn't have any effect, as initial_machinedeployment_replicas
# is set to 0. Instead, static worker nodes running Amazon Linux 2 will be used
# (defined by static_workers_count and os variables).
# This is required in order for validation to pass and will be fixed in
# the upcoming versions.
worker_os                          = "ubuntu"

# Number of worker nodes to be created and provisioned.
static_workers_count               = 3

# Currently, KubeOne supports EKS-D only on Amazon Linux 2.
# Support for other operating systems is planned for the future.
os                                 = "amazon_linux2"
ssh_username                       = "ec2-user"
ssh_public_key_file                = "../credentials/id_rsa.pub"
bastion_user                       = "ec2-user"