### packer-ubuntu-vsphere template

use packer to build a customized ubuntu 18.04 image on vsphere

- vcenter 6.7
- packer 1.6.1
- ubuntu ova: https://cloud-images.ubuntu.com/releases/18.04/release/ubuntu-18.04-server-cloudimg-amd64.ova
  - ova was linked in [kubermatic requirements doc](https://docs.kubermatic.com/kubermatic/v2.14/requirements/cloud_provider/_vsphere/#vm-images)
- vsphere-clone builder is used to clone and modify a vanilla ubuntu cloudimg template
- machine-id and cloud-init get cleaned up at the end of the build to avoid breaking dhcp/networking for vms

### usage:

- copy [./.envrc.template](./.envrc.template) to `.envrc` and add vsphere credentials
- use direnv to sourve `.envrc`, source it directly or create your own wrapper script
- all variables are defined in [./variables.pkr.hcl](./variables.pkr.hcl)
- all variables can be overriden in [./override.vars.hcl](./override.vars.hcl)
- `make build`
