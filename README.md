# Kubernetes 3-Node Cluster Setup with Vagrant

This repository contains scripts and configuration files to set up a 3-node Kubernetes cluster using Vagrant and CentOS Stream 9.

## 📋 Prerequisites

- [Vagrant](https://www.vagrantup.com/downloads) (2.2.0 or higher)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) (6.1 or higher)
- At least 12 GB of RAM available (4 GB per VM)
- At least 6 CPU cores available (2 cores per VM)

## 🏗️ Architecture

The cluster consists of:

- **centos1** (192.168.50.10) - Kubernetes Master Node
- **centos2** (192.168.50.11) - Kubernetes Worker Node
- **centos3** (192.168.50.12) - Kubernetes Worker Node

All nodes have:
- 4 GB RAM
- 2 CPU cores
- CentOS Stream 9
- Containerd as container runtime
- Kubernetes v1.28
- Flannel CNI for pod networking

## 📁 Repository Structure

```
.
├── Vagrantfile                    # Vagrant configuration for 3 VMs
├── kubernetes-setup-node1.sh      # Master node setup script
├── kubernetes-setup-node2.sh      # Worker node 2 setup script
├── kubernetes-setup-node3.sh      # Worker node 3 setup script
└── README.md                      # This file
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd <repo-directory>
```

### 2. Start the VMs

```bash
vagrant up
```

This will create and start all three VMs. The provisioning may take 10-15 minutes depending on your internet connection.

### 3. Setup the Kubernetes Cluster

#### Option A: Using Vagrant SSH

```bash
# Setup master node (centos1)
vagrant ssh centos1
sudo /vagrant/kubernetes-setup-node1.sh
exit

# Setup worker node 2 (centos2)
vagrant ssh centos2
sudo /vagrant/kubernetes-setup-node2.sh
exit

# Setup worker node 3 (centos3)
vagrant ssh centos3
sudo /vagrant/kubernetes-setup-node3.sh
exit
```

#### Option B: Manual SSH

```bash
# Setup master node
ssh -p 2200 vagrant@localhost  # password: vagrant
sudo /vagrant/kubernetes-setup-node1.sh
exit

# Setup worker nodes
ssh -p 2201 vagrant@localhost
sudo /vagrant/kubernetes-setup-node2.sh
exit

ssh -p 2202 vagrant@localhost
sudo /vagrant/kubernetes-setup-node3.sh
exit
```

### 4. Verify the Cluster

```bash
vagrant ssh centos1
kubectl get nodes
kubectl get pods --all-namespaces
```

You should see all three nodes in "Ready" status.

## 🔧 What the Scripts Do

### kubernetes-setup-node1.sh (Master Node)
- Fixes CentOS Stream 9 repository configuration
- Installs and configures containerd
- Installs Kubernetes components (kubelet, kubeadm, kubectl)
- Initializes the Kubernetes control plane
- Installs Flannel CNI network plugin
- Generates join token for worker nodes
- Saves join command to `/vagrant/join-command.sh`

### kubernetes-setup-node2.sh & kubernetes-setup-node3.sh (Worker Nodes)
- Fixes CentOS Stream 9 repository configuration
- Installs and configures containerd
- Installs Kubernetes components
- Resets any previous Kubernetes configuration
- Joins the cluster using the token from master node

## 🌐 Accessing the Cluster

### From Host Machine

Add these entries to your hosts file:

**Linux/Mac:** `/etc/hosts`
**Windows:** `C:\Windows\System32\drivers\etc\hosts`

```
192.168.50.10 centos1
192.168.50.11 centos2
192.168.50.12 centos3
```

### SSH Access

```bash
# Master node
vagrant ssh centos1
# or
ssh -p 2200 vagrant@localhost

# Worker node 2
vagrant ssh centos2
# or
ssh -p 2201 vagrant@localhost

# Worker node 3
vagrant ssh centos3
# or
ssh -p 2202 vagrant@localhost
```

Default password: `vagrant`

## 🧪 Testing the Cluster

### Basic Health Check

```bash
# SSH into master node
vagrant ssh centos1

# Check nodes
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system
```

### Deploy Test Application

```bash
# Create nginx deployment
kubectl create deployment nginx --image=nginx

# Expose as service
kubectl expose deployment nginx --port=80 --type=NodePort

# Check status
kubectl get deployments
kubectl get services
kubectl get pods

# Scale deployment
kubectl scale deployment nginx --replicas=3
kubectl get pods -o wide
```

### Clean Up Test Resources

```bash
kubectl delete deployment nginx
kubectl delete service nginx
```

## 🛠️ Troubleshooting

### Cluster Not Starting

If nodes show "NotReady" status:

```bash
# Check kubelet logs
sudo journalctl -u kubelet -f

# Check containerd
sudo systemctl status containerd

# Restart kubelet
sudo systemctl restart kubelet
```

### Repository Errors

If you encounter repository errors:

```bash
sudo dnf clean all
sudo rm -rf /var/cache/dnf
sudo dnf makecache
```

### Reset a Node

To completely reset a node:

```bash
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/*
sudo rm -rf /var/lib/kubelet/*
sudo rm -rf /var/lib/etcd/*
sudo rm -rf $HOME/.kube
```

Then re-run the setup script.

### Worker Node Won't Join

If worker nodes can't find the join command:

```bash
# On master node, regenerate join command
sudo kubeadm token create --print-join-command

# Copy the output and run on worker node with:
sudo [join-command] --cri-socket unix:///var/run/containerd/containerd.sock
```

## 🔄 Managing the Cluster

### Stop VMs

```bash
vagrant halt
```

### Restart VMs

```bash
vagrant up
```

### Destroy VMs

```bash
vagrant destroy -f
```

### SSH into Specific Node

```bash
vagrant ssh centos1  # or centos2, centos3
```

### Check VM Status

```bash
vagrant status
```

## 📊 Resource Requirements

| Resource | Per VM | Total (3 VMs) |
|----------|--------|---------------|
| RAM      | 4 GB   | 12 GB         |
| CPU      | 2 cores| 6 cores       |
| Disk     | ~10 GB | ~30 GB        |

## 🔐 Security Notes

- SELinux is disabled for Kubernetes compatibility
- Firewall is disabled for simplicity (not recommended for production)
- Default credentials are used (change for production)
- This setup is for **development/testing only**

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [CentOS Stream](https://www.centos.org/centos-stream/)
- [Containerd Documentation](https://containerd.io/)

## 🤝 Contributing

Feel free to submit issues or pull requests if you find bugs or have improvements!

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## ✨ Credits

Created for setting up local Kubernetes development environments.

---

**Happy Clustering! 🎉**
