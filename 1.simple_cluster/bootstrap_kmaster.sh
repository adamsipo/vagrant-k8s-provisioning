#!/bin/bash
IP=$( hostname -I | cut -d" " -f 2)

echo "[TASK 1] Set firewall"
sudo systemctl start firewalld  >/dev/null 2>&1
sudo systemctl enable firewalld  >/dev/null 2>&1
sudo firewall-cmd --zone=public --add-port=6443/tcp --permanent  >/dev/null 2>&1
sudo firewall-cmd --zone=public --add-port=2379-2380/tcp --permanent  >/dev/null 2>&1
sudo firewall-cmd --zone=public --add-port=10250/tcp --permanent  >/dev/null 2>&1
sudo firewall-cmd --zone=public --add-port=10251/tcp --permanent  >/dev/null 2>&1
sudo firewall-cmd --zone=public --add-port=10252/tcp --permanent  >/dev/null 2>&1
sudo firewall-cmd --zone=public --add-port=30000-32767/tcp --permanent  >/dev/null 2>&1

sudo firewall-cmd --add-masquerade --permanent  >/dev/null 2>&1
sudo firewall-cmd --reload  >/dev/null 2>&1
sudo firewall-cmd --list-all --zone=public  >/dev/null 2>&1

echo "[TASK 2] Pull required containers"
sudo kubeadm config images pull >/dev/null 2>&1

echo "[TASK 3] Initialize Kubernetes Cluster"
sudo kubeadm init --apiserver-advertise-address=$IP --pod-network-cidr=192.168.0.0/16 >> /root/kubeinit.log 2>/dev/null

echo "[TASK 4] Deploy Calico network"
sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/manifests/calico.yaml >/dev/null 2>&1

echo "[TASK 5] Generate and save cluster join command to /joincluster.sh"
sudo kubeadm token create --print-join-command > /joincluster.sh 2>/dev/null

echo "[TASK 6] Set Autocomplete"
sudo yum -q install bash-completion -y
echo 'alias k=kubectl' >>~/.bashrc
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

echo "[TASK 7] Set Config"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

sudo mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config