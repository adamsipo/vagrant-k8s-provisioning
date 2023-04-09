# Kubernetes Cluster Vagrant Setup

This Vagrantfile sets up a Kubernetes cluster with master and worker nodes using the CentOS 7 box. It has configurations for node counts, CPU, memory, and IP ranges.

## Prerequisites

- Install [Vagrant](https://www.vagrantup.com/downloads.html)
- Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

## Installation

### Vagrant

1. Download and install Vagrant from the [official website](https://www.vagrantup.com/downloads.html).
2. Follow the installation instructions for your operating system.

### VirtualBox

1. Download and install VirtualBox from the [official website](https://www.virtualbox.org/wiki/Downloads).
2. Follow the installation instructions for your operating system.

## Configuration

| Variable                   | Description                     | Default Value       |
|----------------------------|---------------------------------|---------------------|
| IP_RANGE                   | IP Range for nodes              | "172.16.16."        |
| VAGRANT_BOX                | Vagrant box image               | "centos/7"          |
| VAGRANT_BOX_VERSION        | Vagrant box version             | "2004.01"           |
| CPUS_MASTER_NODE           | CPUs for master nodes           | 2                   |
| CPUS_WORKER_NODE           | CPUs for worker nodes           | 1                   |
| MEMORY_MASTER_NODE         | Memory for master nodes (MB)    | 2048                |
| MEMORY_WORKER_NODE         | Memory for worker nodes (MB)    | 1024                |
| MASTER_NODES_COUNT         | Number of master nodes          | 3                   |
| WORKER_NODES_COUNT         | Number of worker nodes          | 2                   |
| CLUSTER_NAME               | Kubernetes cluster name         | "k8s-1"             |
| MASTER_NODE_NAME           | Master node name prefix         | "master"            |
| WORKER_NODE_NAME           | Worker node name prefix         | "worker"            |
| MASTER_LOAD_BALANCER_NAME  | Master load balancer name       | "lb-master"         |
| WORKER_LOAD_BALANCER_NAME  | Worker load balancer name       | "lb-worker"         |
| MASTER_LOAD_BALANCER_IP    | Master load balancer IP         | "172.16.16.210"     |
| WORKER_LOAD_BALANCER_IP    | Worker load balancer IP         | "172.16.16.220"     |

## Master Nodes IPs

The master nodes are created with IP addresses starting from `172.16.16.101` and incrementing by 1 for each node.

## Worker Nodes IPs

The worker nodes are created with IP addresses starting from `172.16.16.201` and incrementing by 1 for each node.

## Provisioning

The Vagrantfile provisions the nodes with the following shell scripts:

- `env.sh`: Sets environment variables for the nodes
- `bootstrap.sh`: Bootstraps the nodes
- `lb_setup.sh`: Sets up the load balancers for master and worker nodes
- `install-kubernetes.sh`: Installs and configures Kubernetes

## How to Run

1. Save the provided Vagrantfile to a new directory on your local machine.
2. Open a terminal or command prompt and navigate to the directory containing the Vagrantfile.
3. Run the following command to start the virtual machines and provision the Kubernetes cluster:

    ```vagrant up```

4. Wait for the provisioning process to complete. This may take some time, depending on your computer


PYTHONUNBUFFERED=1 ANSIBLE_FORCE_COLOR=true ANSIBLE_HOST_KEY_CHECKING=false ANSIBLE_SSH_ARGS='-o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -o ControlMaster=auto -o ControlPersist=60s' ansible-playbook --connection=ssh --timeout=30 --limit="master-1-k8s-3" --inventory-file=/home/adamlab/github/course/vagrant-k8s-provisioning/.vagrant/provisioners/ansible/inventory --extra-vars=\{\"node_type\":\"master\",\"ANSIBLE_STDOUT_CALLBACK\":\"oneline\",\"master_load_balancer_ip\":\"172.16.16.210\",\"worker_load_balancer_ip\":\"172.16.16.220\",\"ip_master_list\":\"172.16.16.101\ master-1\ master-1\",\"ip_worker_list\":\"172.16.16.201\ worker-1\ worker-1\",\"master_load_balancer_name\":\"lb-master\",\"worker_load_balancer_name\":\"lb-worker\",\"master_node_name\":\"master\",\"worker_node_name\":\"worker\"\} -vv ansible_provision/playbooks/main.yaml

PYTHONUNBUFFERED=1 ANSIBLE_FORCE_COLOR=true ANSIBLE_HOST_KEY_CHECKING=false ANSIBLE_SSH_ARGS='-o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -o ControlMaster=auto -o ControlPersist=60s' ansible-playbook --connection=ssh --timeout=30 --limit="worker-1-k8s-3" --inventory-file=/home/adamlab/github/course/vagrant-k8s-provisioning/.vagrant/provisioners/ansible/inventory --extra-vars=\{\"node_type\":\"worker\",\"ANSIBLE_STDOUT_CALLBACK\":\"oneline\",\"master_load_balancer_ip\":\"172.16.16.210\",\"worker_load_balancer_ip\":\"172.16.16.220\",\"ip_master_list\":\"172.16.16.101\ master-1\ master-1\",\"ip_worker_list\":\"172.16.16.201\ worker-1\ worker-1\",\"master_load_balancer_name\":\"lb-master\",\"worker_load_balancer_name\":\"lb-worker\",\"master_node_name\":\"master\",\"worker_node_name\":\"worker\"\} -vv ansible_provision/playbooks/main.yaml