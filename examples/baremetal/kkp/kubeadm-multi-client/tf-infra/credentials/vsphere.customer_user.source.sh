
#### vsphere
export VSPHERE_USER='customer_user@vsphere.local'
export VSPHERE_PASSWORD='xxxx'
export VSPHERE_SERVER='vcenter.example.io'
export VSPHERE_ALLOW_UNVERIFIED_SSL=true

#### govc
export GOVC_USERNAME=${VSPHERE_USER}
export GOVC_PASSWORD=${VSPHERE_PASSWORD}
export GOVC_URL="https://${VSPHERE_SERVER}/sdk"
export GOVC_INSECURE=${VSPHERE_ALLOW_UNVERIFIED_SSL}
export GOVC_DATACENTER='dc-1'
export GOVC_DATASTORE='exsi-nas'
export GOVC_RESOURCE_POOL="tobi-k1"
export GOVC_NETWORK="Loodse Default"
#### packer
export PKR_VAR_vcenter_server="\"$VSPHERE_SERVER\""
export PKR_VAR_vcenter_user="\"$VSPHERE_USER\""
export PKR_VAR_vcenter_password="\"$VSPHERE_PASSWORD\""