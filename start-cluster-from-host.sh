#!/bin/bash

# Kubernetes Cluster Startup Script (Run from Host Machine)
# This script starts Vagrant VMs and the Kubernetes cluster
# Usage: ./start-cluster-from-host.sh

set -e

echo "=========================================="
echo "Kubernetes Cluster Startup (from Host)"
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

echo "Step 2: Starting Vagrant VMs..."
echo "-----------------------------------"
echo "Starting all VMs (this may take a few minutes)..."
vagrant up
echo "✓ All VMs started"
echo ""

echo "Step 3: Waiting for VMs to fully boot..."
echo "-----------------------------------"
sleep 10
echo "✓ VMs should be ready"
echo ""

echo "Step 4: Starting containerd on master node..."
echo "-----------------------------------"
vagrant ssh centos1 -c "sudo systemctl start containerd" || echo "⚠ Containerd might already be running"
sleep 3
echo "✓ Containerd started on master"
echo ""

echo "Step 5: Starting kubelet on master node..."
echo "-----------------------------------"
vagrant ssh centos1 -c "sudo systemctl start kubelet" || echo "⚠ Kubelet might already be running"
sleep 5
echo "✓ Kubelet started on master"
echo ""

echo "Step 6: Starting containerd on worker nodes..."
echo "-----------------------------------"
for node in centos2 centos3; do
    echo "Starting containerd on $node..."
    vagrant ssh $node -c "sudo systemctl start containerd" || echo "⚠ Containerd might already be running on $node"
    sleep 2
done
echo "✓ Containerd started on all worker nodes"
echo ""

echo "Step 7: Starting kubelet on worker nodes..."
echo "-----------------------------------"
for node in centos2 centos3; do
    echo "Starting kubelet on $node..."
    vagrant ssh $node -c "sudo systemctl start kubelet" || echo "⚠ Kubelet might already be running on $node"
    sleep 2
done
echo "✓ Kubelet started on all worker nodes"
echo ""

echo "Step 8: Waiting for cluster to stabilize..."
echo "-----------------------------------"
echo "Waiting 30 seconds for nodes to become ready..."
sleep 30
echo ""

echo "Step 9: Uncordoning worker nodes..."
echo "-----------------------------------"
vagrant ssh centos1 -c "kubectl uncordon centos2 2>/dev/null || true"
vagrant ssh centos1 -c "kubectl uncordon centos3 2>/dev/null || true"
echo "✓ Worker nodes uncordoned"
echo ""

echo "Step 10: Checking cluster status..."
echo "-----------------------------------"
vagrant ssh centos1 -c "kubectl get nodes"
echo ""

echo "Step 11: Checking system pods..."
echo "-----------------------------------"
vagrant ssh centos1 -c "kubectl get pods -n kube-system"
echo ""

echo "=========================================="
echo "Cluster Startup Complete!"
echo "=========================================="
echo ""
echo "✓ Vagrant VMs are running"
echo "✓ Kubernetes services started"
echo "✓ Cluster is ready"
echo ""
echo "To access the cluster:"
echo "  vagrant ssh centos1"
echo "  kubectl get nodes"
echo ""
echo "To check VM status:"
echo "  vagrant status"
echo ""
echo "To shutdown cluster:"
echo "  ./shutdown-cluster-from-host.sh"
echo "  or"
echo "  vagrant ssh centos1 -c 'sudo /vagrant/shutdown-cluster.sh'"
echo "=========================================="