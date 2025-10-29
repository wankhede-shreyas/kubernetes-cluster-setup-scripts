#!/bin/bash

# Kubernetes Cluster Shutdown Script (Run from Host Machine)
# This script gracefully shuts down the Kubernetes cluster and Vagrant VMs
# Usage: ./shutdown-cluster-from-host.sh

set -e

echo "=========================================="
echo "Kubernetes Cluster Shutdown (from Host)"
echo "=========================================="
echo ""

# Check if Vagrant is installed
if ! command -v vagrant &> /dev/null; then
    echo "ERROR: Vagrant is not installed or not in PATH"
    exit 1
fi

# Check if Vagrantfile exists
if [ ! -f "Vagrantfile" ]; then
    echo "ERROR: Vagrantfile not found in current directory"
    echo "Please run this script from the directory containing your Vagrantfile"
    exit 1
fi

echo "Step 1: Checking VM status..."
echo "-----------------------------------"
vagrant status
echo ""

# Check if VMs are running
VM_STATUS=$(vagrant status | grep -E "centos[1-3]" | grep "running" | wc -l)
if [ "$VM_STATUS" -eq 0 ]; then
    echo "⚠ No VMs are currently running"
    echo "Nothing to shutdown"
    exit 0
fi

echo "Step 2: Checking cluster status..."
echo "-----------------------------------"
vagrant ssh centos1 -c "kubectl get nodes 2>/dev/null" || echo "⚠ Could not connect to cluster (might already be down)"
echo ""

echo "Step 3: Draining worker nodes..."
echo "-----------------------------------"
for node in centos2 centos3; do
    echo "Draining $node..."
    vagrant ssh centos1 -c "kubectl drain $node --ignore-daemonsets --delete-emptydir-data --force --grace-period=30 --timeout=2m 2>/dev/null" || echo "⚠ Could not drain $node (might already be drained or unavailable)"
done
echo ""

echo "Step 4: Stopping kubelet on worker nodes..."
echo "-----------------------------------"
for node in centos2 centos3; do
    echo "Stopping kubelet on $node..."
    vagrant ssh $node -c "sudo systemctl stop kubelet 2>/dev/null" || echo "⚠ Could not stop kubelet on $node"
done
echo ""

echo "Step 5: Stopping containerd on worker nodes..."
echo "-----------------------------------"
for node in centos2 centos3; do
    echo "Stopping containerd on $node..."
    vagrant ssh $node -c "sudo systemctl stop containerd 2>/dev/null" || echo "⚠ Could not stop containerd on $node"
done
echo ""

echo "Step 6: Stopping kubelet on master node..."
echo "-----------------------------------"
vagrant ssh centos1 -c "sudo systemctl stop kubelet 2>/dev/null" || echo "⚠ Could not stop kubelet on master"
echo ""

echo "Step 7: Stopping containerd on master node..."
echo "-----------------------------------"
vagrant ssh centos1 -c "sudo systemctl stop containerd 2>/dev/null" || echo "⚠ Could not stop containerd on master"
echo ""

echo "Step 8: Shutting down Vagrant VMs..."
echo "-----------------------------------"
echo "Halting all VMs (this may take a minute)..."
vagrant halt
echo "✓ All VMs halted"
echo ""

echo "=========================================="
echo "Cluster Shutdown Complete!"
echo "=========================================="
echo ""
echo "✓ Kubernetes services stopped"
echo "✓ Vagrant VMs halted"
echo ""
echo "To start the cluster again:"
echo "  ./start-cluster-from-host.sh"
echo ""
echo "To completely destroy VMs (WARNING: deletes everything):"
echo "  vagrant destroy -f"
echo ""
echo "To check VM status:"
echo "  vagrant status"
echo "=========================================="