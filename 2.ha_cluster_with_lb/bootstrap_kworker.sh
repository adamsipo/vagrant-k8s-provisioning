#!/bin/bash

# Optional

# echo "[TASK 1] Set firewall"
# sudo firewall-cmd --add-rich-rule='rule protocol value="vrrp" accept' --permanent
# sudo systemctl start firewalld  >/dev/null 2>&1
# sudo systemctl enable firewalld  >/dev/null 2>&1
# sudo firewall-cmd --zone=public --add-port=10250/tcp --permanent >/dev/null 2>&1
# sudo firewall-cmd --zone=public --add-port=10250/tcp --permanent >/dev/null 2>&1
# sudo firewall-cmd --zone=public --add-port=30000-32767/tcp --permanent >/dev/null 2>&1

# sudo firewall-cmd --add-masquerade --permanent >/dev/null 2>&1
# sudo firewall-cmd --reload >/dev/null 2>&1
# sudo firewall-cmd --list-all --zone=public >/dev/null 2>&1

echo "[TASK 2] Join node to Kubernetes Cluster"
sudo yum install -y sshpass >/dev/null 2>&1
sudo sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no master1.example.com:/joincluster.sh /joincluster.sh 2>/dev/null
sudo bash /joincluster.sh >/dev/null 2>&1
