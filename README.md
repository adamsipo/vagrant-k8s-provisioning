# Vagrantfile Documentation

## Introduction

This Vagrantfile is used to create a Kubernetes cluster with a specified number of master and worker nodes. It uses the `centos/7` box and creates private networks for communication between the nodes. 

## Configuration

The following variables are used to configure the Vagrantfile:

| Variable | Description |
| --- | --- |
| `IP_RANGE` | The IP address range used for the private networks. |
| `VAGRANT_BOX` | The name of the Vagrant box to use. |
| `VAGRANT_BOX_VERSION` | The version of the Vagrant box to use. |
| `CPUS_MASTER_NODE` | The number of CPUs to allocate to each master node. |
| `CPUS_WORKER_NODE` | The number of CPUs to allocate to each worker node. |
| `MEMORY_MASTER_NODE` | The amount of memory to allocate to each master node (in MB). |
| `MEMORY_WORKER_NODE` | The amount of memory to allocate to each worker node (in MB). |
| `MASTER_NODES_COUNT` | The number of master nodes to create. |
| `WORKER_NODES_COUNT` | The number of worker nodes to create. |
| `MASTER_LOAD_BALANCER_NAME` | The name of the master load balancer. |
| `WORKER_LOAD_BALANCER_NAME` | The name of the worker load balancer. |
| `MASTER_LOAD_BALANCER_IP` | The IP address of the master load balancer. |
| `WORKER_LOAD_BALANCER_IP` | The IP address of the worker load balancer. |

## Master Nodes

The following table lists the details of the master nodes that will be created:

| Name | IP Address | CPUs | Memory |
| --- | --- | --- | --- |
| `1-master-<current-date>` | `172.16.16.101` | `2` | `2048 MB` |
| `2-master-<current-date>` | `172.16.16.102` | `2` | `2048 MB` |

The following ports will be forwarded to each master node:

| Node | Protocol | Host Port | Guest Port |
| --- | --- | --- | --- |
| `1-master-<current-date>` | TCP | `6443` | `6443` |
| `1-master-<current-date>` | TCP | `2379` | `2379` |
| `1-master-<current-date>` | TCP | `2380` | `2380` |
| `2-master-<current-date>` | TCP | `6443` | `6443` |
| `2-master-<current-date>` | TCP | `2379` | `2379` |
| `2-master-<current-date>` | TCP | `2380` | `2380` |

## Worker Nodes

The following table lists the details of the worker nodes that will be created:

| Name | IP Address | CPUs | Memory |
| --- | --- | --- | --- |
| `1-worker-<current-date>` | `172.16.16.201` | `1` | `1024 MB` |
| `2-worker-<current-date>` | `172.16.16.202` | `1` | `1024 MB` |

The following ports will be forwarded to each worker node:

| Node | Protocol | Host Port | Guest Port |
| --- | --- | --- | --- |
| `1-worker-<current-date>` | TCP | `30000
