# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Define machines and their IPs
  machines = {
    "centos1" => "192.168.50.10",
    "centos2" => "192.168.50.11",
    "centos3" => "192.168.50.12"
  }

  machines.each do |name, ip|
    config.vm.define name do |machine|
      machine.vm.box = "centos/7"
      
      # Private network for machine-to-machine communication
      machine.vm.network "private_network", ip: ip
      
      # Forwarded ports (optional - for host access via localhost)
      machine.vm.network "forwarded_port", guest: 80, host: (8000 + machines.keys.index(name))
      machine.vm.network "forwarded_port", guest: 6443, host: (6440 + machines.keys.index(name))
      
      machine.vm.hostname = name
      
      # Provision script to add hosts entries and install dependencies
      machine.vm.provision "shell", inline: <<-SHELL
        # Update /etc/hosts with all machines
        cat >> /etc/hosts << EOF
192.168.50.10 centos1
192.168.50.11 centos2
192.168.50.12 centos3
EOF

        # Disable SELinux
        setenforce 0
        sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config

        # Disable swap
        swapoff -a
        sed -i '/ swap / s/^/#/' /etc/fstab

        # Install Docker
        yum update -y
        yum install -y docker

        # Start and enable Docker
        systemctl start docker
        systemctl enable docker

        # Add vagrant user to docker group
        usermod -aG docker vagrant

        # Configure Kubernetes repository
        cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

        # Install Kubernetes components
        yum install -y kubelet kubeadm kubectl

        # Enable kubelet service
        systemctl enable kubelet

        # Configure network settings for Kubernetes
        cat >> /etc/sysctl.conf << EOF
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
        sysctl -p
      SHELL

      # Initialize master node (centos1)
      if name == "centos1"
        machine.vm.provision "shell", inline: <<-SHELL
          # Initialize Kubernetes master
          kubeadm init --apiserver-advertise-address=192.168.50.10 --pod-network-cidr=10.244.0.0/16

          # Copy kubeconfig for vagrant user
          mkdir -p /home/vagrant/.kube
          cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
          chown vagrant:vagrant /home/vagrant/.kube/config

          # Install Flannel network plugin
          sudo -u vagrant kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

          # Generate join token and save to shared location
          kubeadm token create --print-join-command > /tmp/join_command.sh
          chmod +x /tmp/join_command.sh
        SHELL
      end

      # Join worker nodes (centos2, centos3)
      if name != "centos1"
        machine.vm.provision "shell", inline: <<-SHELL
          # Wait for master to be ready and retrieve join command
          until [ -f /tmp/join_command.sh ]; do
            sleep 5
          done

          # Join the cluster
          bash /tmp/join_command.sh
        SHELL
      end

      # VM configuration - 4GB RAM and 2 CPU cores
      machine.vm.provider "virtualbox" do |vb|
        vb.memory = "4096"
        vb.cpus = 2
      end
    end
  end

  # Display cluster information
  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    echo "============================================"
    echo "Kubernetes Cluster Setup Complete!"
    echo "============================================"
    echo ""
    echo "To access the cluster from your host:"
    echo "1. Add these entries to your /etc/hosts (or C:\\Windows\\System32\\drivers\\etc\\hosts):"
    echo ""
    echo "192.168.50.10 centos1"
    echo "192.168.50.11 centos2"
    echo "192.168.50.12 centos3"
    echo ""
    echo "2. Access the master node:"
    echo "   vagrant ssh centos1"
    echo ""
    echo "3. Verify cluster status:"
    echo "   kubectl get nodes"
    echo "   kubectl get pods --all-namespaces"
  SHELL
end