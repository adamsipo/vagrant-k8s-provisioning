#!/bin/bash
IP=$(hostname -I | cut -d" " -f 2)

# Optional

# echo "[TASK 12] Set firewall"
# sudo systemctl start firewalld  >/dev/null 2>&1
# sudo systemctl enable firewalld  >/dev/null 2>&1

# sudo firewall-cmd --add-rich-rule='rule protocol value="vrrp" accept' --permanent
# sudo firewall-cmd --zone=public --permanent --add-service=http >/dev/null 2>&1
# sudo firewall-cmd --zone=public --permanent --add-service=https >/dev/null 2>&1
# sudo firewall-cmd --zone=public --permanent --add-port=10443/tcp >/dev/null 2>&1
# sudo firewall-cmd --zone=public --permanent --add-port=8443/tcp >/dev/null 2>&1
# sudo firewall-cmd --zone=public --permanent --add-port=9000/tcp >/dev/null 2>&1
# sudo firewall-cmd --zone=public --permanent --add-port=6443/tcp >/dev/null 2>&1
# sudo firewall-cmd --zone=public --permanent --add-port=2379-2380/tcp >/dev/null 2>&1
# sudo firewall-cmd --zone=public --permanent --add-port=10250-10252/tcp >/dev/null 2>&1
# sudo firewall-cmd --zone=public --permanent --add-port=30000-32767/tcp >/dev/null 2>&1

# sudo firewall-cmd --zone=public --permanent --add-port=10443/tcp  >/dev/null 2>&1

# sudo firewall-cmd --add-masquerade --permanent  >/dev/null 2>&1
# sudo firewall-cmd --reload  >/dev/null 2>&1
# sudo firewall-cmd --list-all --zone=public  >/dev/null 2>&1

echo "[TASK 13] Pull required containers"
sudo kubeadm config images pull >/dev/null 2>&1

if [ "$(hostname)" == "master1.example.com" ]; then
  echo "[TASK 14] Initialize Kubernetes Cluster"
  sudo kubeadm init --control-plane-endpoint="k8s-vip:10443" --upload-certs --apiserver-advertise-address=$IP --pod-network-cidr=192.168.0.0/16 >/dev/null 2>&1

  echo "[TASK 15] Deploy Calico network"
  sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/manifests/calico.yaml >/dev/null 2>&1
  sudo curl -L https://github.com/projectcalico/calico/releases/download/v3.24.1/calicoctl-linux-amd64 -o calicoctl >/dev/null 2>&1
  sudo chmod +x ./calicoctl

  echo "[TASK 16] Generate and save worker join command to /joincluster.sh"
  sudo kubeadm token create --print-join-command >/joincluster.sh 2>/dev/null

  echo "[TASK 17] Create join command for control-plane"
  UPLOAD_CERT=$(kubeadm init phase upload-certs --upload-certs | grep -v "\[.*")
  PRINT_COMMAND=$(sudo kubeadm token create --certificate-key $UPLOAD_CERT --print-join-command)
  echo "$PRINT_COMMAND --apiserver-advertise-address=" >/controlplane.sh
else
  echo "Skip to --> [TASK 14] Join node to Kubernetes Cluster"
  sudo sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no master1.example.com:/controlplane.sh /controlplane.sh 2>/dev/null
  sed -i s/$/$(hostname -I | cut -d" " -f 2)/ /controlplane.sh >/dev/null 2>&1
  sudo bash /controlplane.sh >/dev/null 2>&1
fi

echo "[TASK 18] Set Autocomplete"
sudo yum -q install bash-completion -y 2>/dev/null
echo 'alias k=kubectl' >>~/.bashrc
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl >/dev/null

echo "[TASK 19] Set Config"
sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

sudo mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config
