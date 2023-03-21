#!/bin/bash

hostname=$(hostname)


case "$hostname" in
  master-1*)
    # Perform an action on the first hostname
    echo "[TASK 13] Initialize Kubernetes Cluster"
    sudo kubeadm init --control-plane-endpoint=$MASTER_LOAD_BALANCER_NAME:10443 --upload-certs --apiserver-advertise-address=$(hostname -I | cut -d" " -f 2) --pod-network-cidr=192.168.0.0/16
    #sudo kubeadm init --control-plane-endpoint="lb-master:10443" --upload-certs --apiserver-advertise-address=172.16.16.101 --pod-network-cidr=192.168.0.0/16
    
    echo "[TASK 14] Deploy Calico network"
    sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.25/manifests/calico.yaml>/dev/null 2>&1
    sudo curl -L https://github.com/projectcalico/calico/releases/download/v3.24.1/calicoctl-linux-amd64 -o calicoctl >/dev/null 2>&1
    sudo chmod +x ./calicoctl
    sudo mv ./calicoctl /usr/local/bin/calicoctl 

    echo "[TASK 15] Generate and save worker join command to joincluster.sh"
    sudo kubeadm token create --print-join-command > /joincluster.sh 2>/dev/null

    echo "[TASK 16] Create join command for control-plane"
    UPLOAD_CERT=$(kubeadm init phase upload-certs --upload-certs | sed -n '3p' |  tr -d '[:space:]')
    PRINT_COMMAND=$(sudo kubeadm token create --certificate-key $UPLOAD_CERT --print-join-command)
    echo "$PRINT_COMMAND --apiserver-advertise-address=" >/controlplane.sh

    echo "[TASK 17] Set Config"
    sudo mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    sudo mkdir -p /home/vagrant/.kube
    sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
    sudo chown vagrant:vagrant /home/vagrant/.kube/config
    ;;
  master-[0-9])
    # Get the number before "-master" in the hostname
    num=${hostname#master-}
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
      echo "Unknown hostname: $hostname"
      exit 1
    fi
    
    if [ "$num" -gt 1 ]; then
      echo "Skip to --> [TASK 13] Join master node to Kubernetes Cluster"
      sudo sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $MASTER_NODE_NAME-1:/controlplane.sh /controlplane.sh 2>/dev/null
      sed -i s/$/$(hostname -I | cut -d" " -f 2)/ /controlplane.sh
      sudo bash /controlplane.sh

      echo "[TASK 14] Set Config"
      sudo mkdir -p $HOME/.kube
      sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
      sudo chown $(id -u):$(id -g) $HOME/.kube/config

      sudo mkdir -p /home/vagrant/.kube
      sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
      sudo chown vagrant:vagrant /home/vagrant/.kube/config
    else
      echo "Unknown hostname: $hostname"
      exit 1
    fi
    ;;
  worker-*)
    echo "[TASK 13] Join worker node to Kubernetes Cluster"
    sudo yum install -y sshpass >/dev/null 2>&1
    sudo sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $MASTER_NODE_NAME-1:/joincluster.sh /joincluster.sh
    sudo bash /joincluster.sh >/dev/null 2>&1
    ;;
  *)
    echo "Unknown hostname: $hostname"
    exit 1
    ;;
esac

echo "[TASK 14] Set Autocomplete"
sudo yum -q install bash-completion -y >/dev/null 2>&1
echo 'alias k=kubectl' >>~/.bashrc
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl >/dev/null 2>&1