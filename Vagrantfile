# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["VAGRANT_NO_PARALLEL"] = "yes"

IP_RANGE = "172.16.16."

VAGRANT_BOX = "centos/7"
VAGRANT_BOX_VERSION = "2004.01"

CPUS_MASTER_NODE = 2
CPUS_WORKER_NODE = 1

MEMORY_MASTER_NODE = 2048
MEMORY_WORKER_NODE = 1024

MASTER_NODES_COUNT = 3
WORKER_NODES_COUNT = 2

CLUSTER_NAME = "k8s-1"

MASTER_NODE_NAME = "master"
WORKER_NODE_NAME = "worker"

MASTER_LOAD_BALANCER_NAME = "lb-master"
WORKER_LOAD_BALANCER_NAME = "lb-worker"

MASTER_LOAD_BALANCER_IP = "#{IP_RANGE}#{210}"
WORKER_LOAD_BALANCER_IP = "#{IP_RANGE}#{220}"

IP_MASTER_LIST = (1..MASTER_NODES_COUNT).map do |i|
  "#{IP_RANGE}#{100 + i} #{MASTER_NODE_NAME}-#{i} #{MASTER_NODE_NAME}-#{i}"
end.join(",")

IP_WORKER_LIST = (1..WORKER_NODES_COUNT).map do |i|
  "#{IP_RANGE}#{100 + i} #{WORKER_NODE_NAME}-#{i} #{WORKER_NODE_NAME}-#{i}"
end.join(",")

Vagrant.configure(2) do |config|

  # Kubernetes Master Nodes
  (1..MASTER_NODES_COUNT).each do |i|
    config.vm.define "#{MASTER_NODE_NAME}-#{i}-#{CLUSTER_NAME}" do |masternode|
      master_node_ip = "#{IP_RANGE}#{i}"
      masternode.vm.box = VAGRANT_BOX
      masternode.vm.box_check_update = false
      masternode.vm.box_version = VAGRANT_BOX_VERSION
      masternode.vm.hostname = "#{MASTER_NODE_NAME}-#{i}"

      masternode.vm.network "private_network", ip: "#{IP_RANGE}#{100 + i}"

      masternode.vm.provider :virtualbox do |v|
        v.name = "#{MASTER_NODE_NAME}-#{i}-#{CLUSTER_NAME}"
        v.memory = "#{MEMORY_MASTER_NODE}"
        v.cpus = "#{CPUS_MASTER_NODE}"
        v.customize ["modifyvm", :id, "--groups", "/#{CLUSTER_NAME}"]
      end

      masternode.vm.provision "shell", path: "env.sh", env: {
        "MASTER_LOAD_BALANCER_IP" => MASTER_LOAD_BALANCER_IP,
        "WORKER_LOAD_BALANCER_IP" => WORKER_LOAD_BALANCER_IP,
        "IP_MASTER_LIST" => IP_MASTER_LIST,
        "IP_WORKER_LIST" => IP_WORKER_LIST,
        "MASTER_LOAD_BALANCER_NAME" => MASTER_LOAD_BALANCER_NAME,
        "WORKER_LOAD_BALANCER_NAME" => WORKER_LOAD_BALANCER_NAME,
        "MASTER_NODE_NAME" => MASTER_NODE_NAME,
        "WORKER_NODE_NAME" => WORKER_NODE_NAME,
                                       }
      masternode.vm.provision "shell", path: "bootstrap.sh"
      masternode.vm.provision "shell", path: "lb_setup.sh"
      masternode.vm.provision "shell", path: "install-kubernetes.sh"
    end
  end

  # Kubernetes Worker Nodes
  (1..WORKER_NODES_COUNT).each do |i|
    config.vm.define "#{WORKER_NODE_NAME}-#{i}-#{CLUSTER_NAME}" do |workernode|
      workernode.vm.box = VAGRANT_BOX
      workernode.vm.box_check_update = false
      workernode.vm.box_version = VAGRANT_BOX_VERSION
      workernode.vm.hostname = "#{WORKER_NODE_NAME}-#{i}"

      workernode.vm.network "private_network", ip: "#{IP_RANGE}#{200 + i}"

      workernode.vm.provider :virtualbox do |v|
        v.name = "#{WORKER_NODE_NAME}-#{i}-#{CLUSTER_NAME}"
        v.memory = "#{MEMORY_WORKER_NODE}"
        v.cpus = "#{CPUS_WORKER_NODE}"
        v.customize ["modifyvm", :id, "--groups", "/#{CLUSTER_NAME}"]
      end
      workernode.vm.provision "shell", path: "env.sh", env: {
        "MASTER_LOAD_BALANCER_IP" => MASTER_LOAD_BALANCER_IP,
        "WORKER_LOAD_BALANCER_IP" => WORKER_LOAD_BALANCER_IP,
        "IP_MASTER_LIST" => IP_MASTER_LIST,
        "IP_WORKER_LIST" => IP_WORKER_LIST,
        "MASTER_LOAD_BALANCER_NAME" => MASTER_LOAD_BALANCER_NAME,
        "WORKER_LOAD_BALANCER_NAME" => WORKER_LOAD_BALANCER_NAME,
        "MASTER_NODE_NAME" => MASTER_NODE_NAME,
        "WORKER_NODE_NAME" => WORKER_NODE_NAME,
      }
      workernode.vm.provision "shell", path: "bootstrap.sh"
      workernode.vm.provision "shell", path: "lb_setup.sh"
      workernode.vm.provision "shell", path: "install-kubernetes.sh"
    end
  end
end
