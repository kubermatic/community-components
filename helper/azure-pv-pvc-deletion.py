# Get the list of all PVs in the cluster
import subprocess
import json

list_of_pv = subprocess.run('kubectl get pv -o jsonpath="{range .items[*]}{.metadata.name}{\'\\n\'}{end}"', shell=True, capture_output=True, text=True)
list_of_pv.check_returncode()  # Check if the command execution was successful

# Split the PV names into a list
list_of_pv = list_of_pv.stdout.strip().split("\n")

# Loop through each PV and patch the reclaim policy
for pv in list_of_pv:

    # Trim leading and trailing spaces from the PV name
    pv = pv.strip()

    # Patch the PV with the new reclaim policy
    patch_command = f'kubectl patch pv {pv} -p \'{{"spec":{{"persistentVolumeReclaimPolicy":"Delete"}}}}\''
    subprocess.run(patch_command, shell=True)

    # Print the status of the patched PV
    print(f"Patched PV: {pv}")
    get_command = f'kubectl get pv {pv} -o jsonpath="{{.spec.persistentVolumeReclaimPolicy}}"'
    pv_status = subprocess.run(get_command, shell=True, capture_output=True, text=True)
    pv_status.check_returncode()  # Check if the command execution was successful
    pv_status = pv_status.stdout.strip()
    print(pv_status)
    print("")

# Delete all PVs
for pv in list_of_pv:
    # Trim leading and trailing spaces from the PV name
    pv = pv.strip()
    # Delete all PVs
    pv_delete_command = f'kubectl delete pv {pv} --grace-period=0 --force --wait=false'
    subprocess.run(pv_delete_command, shell=True)
    print(f"Deleted PV: {pv}")
    pv_delete_after_command = f"kubectl patch pv {pv} -p '{{\"metadata\": {json.dumps({'finalizers': None})}}}'"
    subprocess.run(pv_delete_after_command, shell=True)

# Get the list of all PVCs in the cluster
pvc_list_command = "kubectl get pvc --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{\"\\n\"}{end}'"
pvc_list_output = subprocess.check_output(pvc_list_command, shell=True, text=True).strip()
pvc_list = pvc_list_output.split('\n')
print(pvc_list)

# Delete all PVCs
for pvc in pvc_list:
    # Split PVC and namespace name
    namespace, pvc_name = pvc.split('/')
    print(f"PVC: {pvc_name} and namespace: {namespace}")
    # Delete all PVC
    patch_command = f"kubectl delete pvc {pvc_name} -n {namespace} --grace-period=0 --force --wait=false"
    subprocess.run(patch_command, shell=True)
    # Patch PVC to remove finalizers
    pvc_delete_after_command = f"kubectl patch pvc {pvc_name} -n {namespace} -p '{{\"metadata\": {json.dumps({'finalizers': None})}}}'"
    subprocess.run(pvc_delete_after_command, shell=True)
    print(f"Deleted PVC: {pvc}")
