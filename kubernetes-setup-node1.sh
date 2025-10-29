#!/bin/bash

# Kubernetes Master Node Setup Script for centos1 (CentOS Stream 9)
# Run this script with sudo privileges

set -e

echo "=========================================="
echo "Setting up Kubernetes Master Node"
echo "=========================================="

# Remove ANY existing Kubernetes repository files first
echo "Removing old Kubernetes repositories..."
rm -f /etc/yum.repos.d/kubernetes.repo
rm -f /etc/yum.repos.d/kubernetes*.repo

# Fix CentOS Stream 9 repository issues
echo "Fixing CentOS Stream 9 repositories..."
# Disable problematic repos temporarily
dnf config-manager --set-disabled baseos appstream extras 2>/dev/null || true

# Update repository URLs to use mirror.stream.centos.org
cat > /etc/yum.repos.d/centos.repo << 'EOF'
[baseos]
name=CentOS Stream $releasever - BaseOS
baseurl=http://mirror.stream.centos.org/$releasever-stream/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[appstream]
name=CentOS Stream $releasever - AppStream
baseurl=http://mirror.stream.centos.org/$releasever-stream/AppStream/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[extras-common]
name=CentOS Stream $releasever - Extras packages
baseurl=http://mirror.stream.centos.org/SIGs/$releasever-stream/extras/$basearch/extras-common/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

# Clean all DNF caches and rebuild metadata
echo "Cleaning DNF cache and rebuilding metadata..."
dnf clean all
rm -rf /var/cache/dnf
dnf makecache

# Update /etc/hosts
echo "Updating /etc/hosts..."
cat >> /etc/hosts << EOF
192.168.50.10 centos1
192.168.50.11 centos2
192.168.50.12 centos3
EOF

# Disable SELinux
echo "Disabling SELinux..."
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Disable swap
echo "Disabling swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Disable firewall
echo "Disabling firewall..."
systemctl stop firewalld
systemctl disable firewalld

# Install containerd (CentOS Stream 9 uses containerd instead of Docker)
echo "Installing containerd..."
dnf update -y
dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y containerd.io

# Configure containerd
echo "Configuring containerd..."
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

# Enable systemd cgroup driver
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Start and enable containerd
systemctl restart containerd
systemctl enable containerd

# Remove old Kubernetes repository configurations
echo "Cleaning up old Kubernetes repositories..."
rm -f /etc/yum.repos.d/kubernetes.repo
dnf clean all

# Add Kubernetes repository (pkgs.k8s.io)
echo "Adding Kubernetes repository..."
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

# Install required packages
echo "Installing iproute-tc and iptables..."
dnf install -y iproute-tc iptables

# Install Kubernetes components
echo "Installing Kubernetes components..."
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# Enable kubelet
systemctl enable kubelet

# Configure network settings
echo "Configuring network settings..."
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Load br_netfilter module
modprobe br_netfilter
modprobe overlay

# Apply sysctl settings
sysctl --system

# Initialize Kubernetes master
echo "Initializing Kubernetes master node..."
kubeadm init --apiserver-advertise-address=192.168.50.10 --pod-network-cidr=10.244.0.0/16 --cri-socket unix:///var/run/containerd/containerd.sock

# Setup kubeconfig for root user
echo "Setting up kubeconfig..."
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Setup kubeconfig for vagrant user
mkdir -p /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

# Install Flannel network plugin
echo "Installing Flannel network plugin..."
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Generate join command for worker nodes
echo "Generating join command for worker nodes..."
kubeadm token create --print-join-command > /vagrant/join-command.sh
chmod +x /vagrant/join-command.sh

echo ""
echo "=========================================="
echo "Master node setup complete!"
echo "=========================================="
echo ""
echo "Join command has been saved to /vagrant/join-command.sh"
echo ""
echo "To check cluster status, run:"
echo "  kubectl get nodes"
echo "  kubectl get pods --all-namespaces"
echo ""
echo "Now run kubernetes-setup-node2.sh on centos2"
echo "and kubernetes-setup-node3.sh on centos3"
echo "=========================================="