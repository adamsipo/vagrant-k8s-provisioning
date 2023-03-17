#!/bin/bash

hostname=$(hostname)
num=${hostname%-master*}

case "$hostname" in
  1-master*)
    echo "Doing something for 1-master"
    echo "Doing something for master-1"
    # Perform an action on the first hostname
    echo "[TASK 12] Initialize Kubernetes Cluster"
    sudo kubeadm init --control-plane-endpoint="$MASTER_LOAD_BALANCER_NAME:10443" --upload-certs --apiserver-advertise-address=$ip --pod-network-cidr=192.168.0.0/16

    # sudo kubeadm init --control-plane-endpoint="172.16.16.210:10443" --upload-certs --apiserver-advertise-address="172.16.16.101" --pod-network-cidr=192.168.0.0/16

    echo "[TASK 13] Deploy Calico network"
    sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.25/manifests/calico.yaml>/dev/null 2>&1
    sudo curl -L https://github.com/projectcalico/calico/releases/download/v3.24.1/calicoctl-linux-amd64 -o calicoctl >/dev/null 2>&1
    sudo chmod +x ./calicoctl
    sudo mv ./calicoctl /usr/local/bin/calicoctl 

    echo "[TASK 14] Generate and save worker join command to /joincluster.sh"
    sudo kubeadm token create --print-join-command >/joincluster.sh 2>/dev/null

    echo "[TASK 15] Create join command for control-plane"
    UPLOAD_CERT=$(kubeadm init phase upload-certs --upload-certs | grep -v "\[.*")
    PRINT_COMMAND=$(sudo kubeadm token create --certificate-key $UPLOAD_CERT --print-join-command)
    echo "$PRINT_COMMAND --apiserver-advertise-address=" >/controlplane.sh
    ;;
  [0-9]-master*)
    # Get the number before "-master" in the hostname
    num=${hostname%-master*}
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
      echo "Unknown hostname: $hostname"
      exit 1
    fi
    
    if [ "$num" -gt 1 ]; then
      echo "Doing something for $num-master"
      echo "Doing something for master-$num"
      echo "Skip to --> [TASK 12] Join node to Kubernetes Cluster"
      sudo sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no master1.example.com:/controlplane.sh /controlplane.sh 2>/dev/null
      sed -i s/$/$(hostname -I | cut -d" " -f 2)/ /controlplane.sh
      sudo bash /controlplane.sh >/dev/null 2>&1
    else
      echo "Unknown hostname: $hostname"
      exit 1
    fi
    ;;
  worker-*)
    echo "Doing something for worker node"
    echo "Doing something for worker node"
    echo "[TASK 2] Join node to Kubernetes Cluster"
    sudo yum install -y sshpass >/dev/null 2>&1
    sudo sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no master1.example.com:/joincluster.sh /joincluster.sh 2>/dev/null
    sudo bash /joincluster.sh >/dev/null 2>&1
    ;;
  *)
    echo "Unknown hostname: $hostname"
    exit 1
    ;;
esac

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
