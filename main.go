package main

import (
	"fmt"
	"html/template"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// Insert indexHTML and vagrantFileTemplate constants here

const indexHTML = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Kubernetes Vagrant Setup</title>
</head>
<body>
  <h1>Kubernetes Vagrant Setup</h1>
  <form action="/" method="post">
    <label for="masterNodes">Master Nodes:</label>
    <input type="number" id="masterNodes" name="masterNodes" value="1" min="1"><br><br>

    <label for="workerNodes">Worker Nodes:</label>
    <input type="number" id="workerNodes" name="workerNodes" value="1" min="1"><br><br>

    <label for="ipRange">IP Range:</label>
    <input type="text" id="ipRange" name="ipRange" value="172.16.16."><br><br>

    <label for="masterLbIp">Master Load Balancer IP:</label>
    <input type="text" id="masterLbIp" name="masterLbIp" value="172.16.16.210"><br><br>

    <label for="workerLbIp">Worker Load Balancer IP:</label>
    <input type="text" id="workerLbIp" name="workerLbIp" value="172.16.16.220"><br><br>

    <input type="submit" value="Run Vagrant">
  </form>
</body>
</html>
`

const vagrantFileTemplate = `
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

MASTER_NODES_COUNT = 1
WORKER_NODES_COUNT = 1

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
`
func sseHandler(w http.ResponseWriter, r *http.Request) {
	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "Streaming unsupported!", http.StatusInternalServerError)
		return
	}

	masterNodes, _ := strconv.Atoi(r.URL.Query().Get("masterNodes"))
	workerNodes, _ := strconv.Atoi(r.URL.Query().Get("workerNodes"))
	ipRange := r.URL.Query().Get("ipRange")
	masterLbIp := r.URL.Query().Get("masterLbIp")
	workerLbIp := r.URL.Query().Get("workerLbIp")

	updatedVagrantfile := vagrantFileTemplate
	updatedVagrantfile = replace(updatedVagrantfile, "MASTER_NODES_COUNT = 1", fmt.Sprintf("MASTER_NODES_COUNT = %d", masterNodes))
	updatedVagrantfile = replace(updatedVagrantfile, "WORKER_NODES_COUNT = 1", fmt.Sprintf("WORKER_NODES_COUNT = %d", workerNodes))
	updatedVagrantfile = replace(updatedVagrantfile, "IP_RANGE = \"172.16.16.\"", fmt.Sprintf("IP_RANGE = \"%s\"", ipRange))
	updatedVagrantfile = replace(updatedVagrantfile, "MASTER_LOAD_BALANCER_IP = \"#{IP_RANGE}#{210}\"", fmt.Sprintf("MASTER_LOAD_BALANCER_IP = \"%s\"", masterLbIp))
	updatedVagrantfile = replace(updatedVagrantfile, "WORKER_LOAD_BALANCER_IP = \"#{IP_RANGE}#{220}\"", fmt.Sprintf("WORKER_LOAD_BALANCER_IP = \"%s\"", workerLbIp))

	dir := filepath.Join("/tmp", "vagrant")
	err := os.MkdirAll(dir, 0755)
	if err != nil {
		http.Error(w, "Failed to create Vagrant directory", http.StatusInternalServerError)
		return
	}

	err = ioutil.WriteFile(filepath.Join(dir, "Vagrantfile"), []byte(updatedVagrantfile), 0644)
	if err != nil {
		http.Error(w, "Failed to write Vagrantfile", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")

	cmd := exec.Command("vagrant", "up")
	cmd.Dir = dir
	stdout, _ := cmd.StdoutPipe()
	cmd.Stderr = cmd.Stdout
	cmd.Start()

	scanner := bufio.NewScanner(stdout)
	for scanner.Scan() {
		fmt.Fprintf(w, "data: %s\n\n", scanner.Text())
		flusher.Flush()
	}

	cmd.Wait()
}

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost {
			http.Redirect(w, r, fmt.Sprintf("/ws?masterNodes=%s&workerNodes=%s&ipRange=%s&masterLbIp=%s&workerLbIp=%s",
				r.FormValue("masterNodes"), r.FormValue("workerNodes"), r.FormValue("ipRange"),
				r.FormValue("masterLbIp"), r.FormValue("workerLbIp")), http.StatusFound)
		} else {
			tmpl, _ := template.New("index").Parse(indexHTML)
			tmpl.Execute(w, nil)
		}
	})

	http.HandleFunc("/ws", wsHandler)

	http.ListenAndServe(":8080", nil)
}

func replace(src, oldValue, newValue string) string {
	return strings.Replace(src, oldValue, newValue, -1)
}




