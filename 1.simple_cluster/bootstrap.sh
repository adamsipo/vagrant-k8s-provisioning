#!/bin/bash

## !IMPORTANT ##
#
## This script is tested only in the "bento/centos-7" Vagrant box
## If you use a different version of Centos test this again
#

echo "[TASK 1] Install packages and turn on firewall"
sudo yum -q install epel-release -y >/dev/null 2>&1
sudo yum -q install ufw -y >/dev/null 2>&1
sudo ufw --force enable >/dev/null 2>&1

echo "[TASK 2] Disable and turn off SWAP"
# disable swap
sudo swapoff -a >/dev/null 2>&1

# remove swap partition settings in /etc/fstab files
sudo sed -i '/swap/d' /etc/fstab >/dev/null 2>&1

echo "[TASK 3] Enable and Load Kernel modules"
sudo cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf >/dev/null 2>&1
overlay
br_netfilter
EOF

sudo modprobe overlay >/dev/null 2>&1
sudo modprobe br_netfilter >/dev/null 2>&1

echo "[TASK 4] Add Kernel settings"
sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf >/dev/null 2>&1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system >/dev/null 2>&1

echo "[TASK 5] Install containerd runtime and set containerd"
sudo yum install -y yum-utils >/dev/null 2>&1
sudo yum-config-manager -y --enable extras >/dev/null 2>&1
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >/dev/null 2>&1
sudo yum install -y containerd.io >/dev/null 2>&1
sudo yum install -y docker-ce docker-ce-cli docker-compose-plugin >/dev/null

sudo mkdir -p /etc/containerd
sudo containerd config default > /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= true/SystemdCgroup \= false/g' /etc/containerd/config.toml >/dev/null 2>&1
sudo systemctl restart containerd >/dev/null 2>&1
sudo systemctl enable containerd >/dev/null 2>&1


echo "[TASK 6] Add apt repo for kubernetes"
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo >/dev/null 2>&1
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

echo "[TASK 7] Install Kubernetes components (kubeadm, kubelet and kubectl)"
sudo yum install -y -q kubeadm-1.25.0-0.x86_64 kubelet-1.25.0-0.x86_64 kubectl-1.25.0-0.x86_64 >/dev/null 2>&1

echo "[TASK 8] Enable ssh password authentication"
sudo sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config >/dev/null 2>&1
sudo echo 'PermitRootLogin yes' | sudo tee -a /etc/ssh/sshd_config >/dev/null 2>&1
sudo systemctl reload sshd >/dev/null 2>&1

echo "[TASK 9] Set root password"
sudo echo -e "kubeadmin\nkubeadmin" | passwd root >/dev/null 2>&1
sudo echo "export TERM=xterm" >> /etc/bash.bashrc >/dev/null 2>&1

echo "[TASK 10] Update /etc/hosts file"
sudo cat | sudo tee -a /etc/hosts >/dev/null 2>&1 <<EOF
172.16.24.100   kmaster.example.com     kmaster
172.16.24.101   kworker1.example.com    kworker1
172.16.24.102   kworker2.example.com    kworker2
EOF

