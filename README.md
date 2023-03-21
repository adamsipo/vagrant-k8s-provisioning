# Kubernetes Cluster Vagrant Setup

This Vagrantfile sets up a Kubernetes cluster with master and worker nodes using the CentOS 7 box. It has configurations for node counts, CPU, memory, and IP ranges.

## Prerequisites

- Vagrant
- VirtualBox

### Installing Vagrant

Follow the instructions for your operating system to install Vagrant:

#### Windows / macOS

Download the appropriate installer for your OS from the [Vagrant downloads page](https://www.vagrantup.com/downloads) and run the installer.

#### Linux

You can use the package manager of your Linux distribution to install Vagrant, or you can download the appropriate package from the [Vagrant downloads page](https://www.vagrantup.com/downloads) and install it using the package manager.

### Installing VirtualBox

Follow the instructions for your operating system to install VirtualBox:

#### Windows / macOS / Linux

Download the appropriate installer for your OS from the [VirtualBox downloads page](https://www.virtualbox.org/wiki/Downloads) and run the installer.

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

1. Place the Vagrantfile and the provisioning scripts (`env.sh`, `bootstrap.sh`, `lb_setup.sh`, `install-kubernetes.sh`) in
