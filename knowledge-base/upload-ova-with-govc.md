# Upload `.ova` image with `govc`

Define govc env:
```
export GOVC_USERNAME=${VSPHERE_USER}
export GOVC_PASSWORD=${VSPHERE_PASSWORD}
export GOVC_URL="https://${VSPHERE_SERVER}/sdk"
export GOVC_INSECURE=${VSPHERE_ALLOW_UNVERIFIED_SSL}
export GOVC_DATACENTER='dc-1'
export GOVC_DATASTORE='exsi-nas'
export GOVC_RESOURCE_POOL="tobi-k1"
export GOVC_NETWORK="Loodse Default"
```

export spec & upload
```
govc import.spec ~/Downloads/ubuntu-tobi.ova | python3 -m json.tool > ubuntu.ova.json
```
configure network
```
vim ubuntu.ova.json
```
```json
    "NetworkMapping": [
        {
            "Name": "VM Network",
            "Network": "" <<< DEFINE
        }
```
upload to vsphere
```
govc import.ova --options ubuntu.ova.json ~/Downloads/ubuntu-tobi.ova
```

set disk UUID flag (needed for machine controller):
```
govc vm.change -e="disk.enableUUID=1" -vm='/PATH/TO/VM'
```

More information see [Kubermatic Docs > Requirements > vSphere](https://docs.kubermatic.com/kubermatic/v2.16/requirements/cloud_provider/vsphere/)
