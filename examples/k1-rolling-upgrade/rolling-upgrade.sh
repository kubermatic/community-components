#!/usr/bin/env bash

set -e
set -o pipefail

CLOUD_PROVIDER="openstack"

CLUSTER_NAME="${1}"

if [ -z "${CLUSTER_NAME}" ]; then
    echo "Error: Cluster name is required"
    exit 1
fi

# Setup
GIT_ROOT="$(git rev-parse --show-toplevel)"

export KUBECONFIG="${GIT_ROOT}/kubeconfig"
TERRAFORM_DIR="${GIT_ROOT}/examples/terraform/${CLOUD_PROVIDER}"
CONFIG_DIR="${GIT_ROOT}/examples/terraform/${CLOUD_PROVIDER}/${CLUSTER_NAME}"

# Get current control plane count
current_cp_count=$(kubectl get nodes --selector=node-role.kubernetes.io/control-plane | grep "control-plane" | grep -c "Ready")

# Validate we have enough nodes for etcd quorum
if [ "${current_cp_count}" -lt 3 ]; then
    echo "Error: Need at least 3 control plane nodes, found ${current_cp_count}"
    exit 1
fi

echo "Current control plane count: ${current_cp_count}"
echo "Will rotate all ${current_cp_count} control plane nodes one by one"

wait_for_node() {
    local node_name=$1
    local max_retries=20
    local retry=0

    echo "Waiting for node ${node_name} to be ready..."

    while [ $retry -lt $max_retries ]; do
        if kubectl get nodes | grep "${node_name}" | grep -q "Ready"; then
            echo "Node ${node_name} is ready"
            return 0
        fi
        echo "Waiting for node ${node_name} to be ready... (${retry}/${max_retries})"
        sleep 5
        ((retry++))
    done

    echo "Timeout waiting for node ${node_name} to be ready"
    return 1
}

verify_etcd_health() {
    local max_retries=10
    local retry=0
    local any_etcd_pod

    echo "Verifying etcd cluster health..."

    any_etcd_pod=$(kubectl -n kube-system get pods -l component=etcd -o jsonpath='{.items[0].metadata.name}')
    if [ -z "${any_etcd_pod}" ]; then
        echo "No etcd pods found!"
        return 1
    fi

    while [ $retry -lt $max_retries ]; do
        if kubectl -n kube-system exec "${any_etcd_pod}" -- \
            etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt \
            --cert /etc/kubernetes/pki/etcd/server.crt \
            --key /etc/kubernetes/pki/etcd/server.key \
            endpoint health --cluster | grep -q "is healthy"; then

            echo "Etcd cluster is healthy"
            return 0
        fi

        echo "Waiting for etcd cluster to be healthy... (${retry}/${max_retries})"
        sleep 15
        ((retry++))
    done

    echo "Etcd cluster health check failed"
    return 1
}

remove_etcd_member() {
    local node_name=$1
    local any_etcd_pod

    any_etcd_pod=$(kubectl -n kube-system get pods -l component=etcd -o jsonpath='{.items[0].metadata.name}')
    if [ -z "${any_etcd_pod}" ]; then
        echo "No etcd pods found!"
        return 1
    fi

    member_id=$(kubectl -n kube-system exec "${any_etcd_pod}" -- etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key member list | grep "${node_name}" | awk -F ',' '{print $1}')
    echo "Removing etcd member ${member_id}"

    if [ -z "${member_id}" ]; then
        echo "Etcd member ${node_name} not found"
        return 0
    fi

    if ! kubectl -n kube-system exec "${any_etcd_pod}" -- etcdctl member remove "${member_id}" \
        --cacert /etc/kubernetes/pki/etcd/ca.crt \
        --cert /etc/kubernetes/pki/etcd/server.crt \
        --key /etc/kubernetes/pki/etcd/server.key; then

        echo "Failed to remove etcd member ${node_name}"
        return 1
    fi

    echo "Removed etcd member ${node_name}"
}

# Add a stand-in node to maintain quorum
echo "Adding stand-in control plane node..."
terraform -chdir="${TERRAFORM_DIR}" apply -auto-approve \
    -var-file="${CONFIG_DIR}/terraform.tfvars" \
    -state="${CONFIG_DIR}/terraform.tfstate" \
    -var "control_plane_vm_count=$((current_cp_count + 1))"

# Generate terraform output
terraform -chdir="${TERRAFORM_DIR}" output -state="${CONFIG_DIR}/terraform.tfstate" -json > "${CONFIG_DIR}/tf.json"

# Apply KubeOne to add the stand-in node
kubeone apply -y \
    -m "${CONFIG_DIR}/kubeone.yaml" \
    -t "${CONFIG_DIR}/tf.json"

# Wait for stand-in node to be ready
stand_in_node_name="${CLUSTER_NAME}-cp-$((current_cp_count))"
if ! wait_for_node "${stand_in_node_name}"; then
    echo "Failed to add stand-in node ${stand_in_node_name}"
    exit 1
fi

# Verify etcd health
if ! verify_etcd_health; then
    echo "Etcd health check failed after adding stand-in node"
    exit 1
fi

for ((i=0; i<current_cp_count; i++)); do
    echo ""
    echo "================================================================"
    echo "Starting rotation ${i+1} of ${current_cp_count}"
    echo "================================================================"
    echo ""

    # Remove oldest node
    old_node_name="${CLUSTER_NAME}-cp-${i}"

    echo "Draining node ${old_node_name}..."
    kubectl drain "${old_node_name}" --ignore-daemonsets --delete-emptydir-data --timeout=5m || true

    echo "Deleting node ${old_node_name}..."
    kubectl delete node "${old_node_name}" --ignore-not-found=true || true

    # We have to perform this step manually. The next KubeOne apply will add the rotated node back.
    remove_etcd_member "${old_node_name}"
    sleep 10

    # Perform in-place replacement of the node in terraform
    terraform -chdir="${TERRAFORM_DIR}" apply -auto-approve \
        -var-file="${CONFIG_DIR}/terraform.tfvars" \
        -state="${CONFIG_DIR}/terraform.tfstate" \
        -replace="openstack_compute_instance_v2.control_plane[$i]" \
        -var "control_plane_vm_count=$((current_cp_count + 1))" \
        -target="openstack_compute_instance_v2.control_plane[$i]" \
        -target="openstack_lb_member_v2.kube_apiserver"

    # Generate terraform output
    terraform -chdir="${TERRAFORM_DIR}" output -state="${CONFIG_DIR}/terraform.tfstate" -json > "${CONFIG_DIR}/tf.json"

    # Apply KubeOne to sync the cluster state
    kubeone apply -y \
        -m "${CONFIG_DIR}/kubeone.yaml" \
        -t "${CONFIG_DIR}/tf.json"

    # Verify etcd health
    if ! verify_etcd_health; then
        echo "Etcd health check failed after removing old node"
        exit 1
    fi

    sleep 10
done

# Remove the stand-in node
echo "Removing stand-in control plane node..."
terraform -chdir="${TERRAFORM_DIR}" apply -auto-approve \
    -var-file="${CONFIG_DIR}/terraform.tfvars" \
    -state="${CONFIG_DIR}/terraform.tfstate" \
    -var "control_plane_vm_count=${current_cp_count}"

# Generate final terraform output
terraform -chdir="${TERRAFORM_DIR}" output -state="${CONFIG_DIR}/terraform.tfstate" -json > "${CONFIG_DIR}/tf.json"

# Final KubeOne apply
kubeone apply -y \
    -m "${CONFIG_DIR}/kubeone.yaml" \
    -t "${CONFIG_DIR}/tf.json"

echo ""
echo "================================================================"
echo "All control plane nodes have been successfully rotated!"
echo "Final etcd cluster status:"
verify_etcd_health
echo "================================================================"