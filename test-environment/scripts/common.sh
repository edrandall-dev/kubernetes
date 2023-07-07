#!/bin/bash

KUBE_PKG_VERSION="$KUBE_VERSION-00"

show()
{ 
    echo
    echo -ne "==> "
    echo -ne "\033[7m$@\033[0m"
    echo -e " <=="
}

show "*** RUNNING: common.sh ***"

function kubelet_ip_flag {
  echo "Create an entry in /etc/default/kubelet to ensure host-only IP is node IP"
  IPADDR=$(ip a s | grep $HOST_NET | awk {'print $2'} | sed 's/\/16//')

  echo "IPADDR is $IPADDR"
  cat <<-EOF | sudo tee /etc/default/kubelet
    KUBELET_EXTRA_ARGS='--node-ip $IPADDR'
EOF
}

function tln_route {
  echo "Creating a route back to 10.10.11.0/24"
  ip route add 10.10.11.0/24 via $HOST_NET.1 onlink dev enp0s8
}

function bridged_traffic {
  cat <<-EOF | sudo tee /etc/modules-load.d/k8s.conf
    overlay
    br_netfilter
EOF

  modprobe overlay 
  modprobe br_netfilter

  cat <<-EOF | sudo tee /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-iptables  = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.ipv4.ip_forward                 = 1
EOF

  sysctl --system
  sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
}

function install_kubelet_kubeadm {
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg
  echo "deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg] https://packages.cloud.google.com/apt/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

  apt-get update
  apt-get install -y kubelet=$KUBE_PKG_VERSION kubeadm=$KUBE_PKG_VERSION kubectl=$KUBE_PKG_VERSION
  apt-mark hold kubelet kubeadm kubectl

  #Create an alias k=kubectl
  echo "alias k=kubectl" | sudo tee -a /etc/bash.bashrc
}

function install_containerd {
  apt-get update
  apt-get install \
    ca-certificates \
    curl \
    gnupg

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
  
  echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/trusted.gpg.d/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt-get update
  apt-get install containerd.io

  cat <<-EOF > /etc/containerd/config.toml
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
      SystemdCgroup = true
EOF
  systemctl restart containerd  
}

function bridged_traffic {
  cat <<-EOF | sudo tee /etc/modules-load.d/k8s.conf
    overlay
    br_netfilter
EOF

  modprobe overlay 
  modprobe br_netfilter

  cat <<-EOF | sudo tee /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-iptables  = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.ipv4.ip_forward                 = 1
EOF

  sysctl --system
  sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
}

show "==> Function: bridged_traffic"
bridged_traffic

show "==> Function: install_containerd"
install_containerd

show "==> Function: kubelet_ip_flag"
kubelet_ip_flag

show "==> Function: install_kubelet_kubeadm"
install_kubelet_kubeadm

show "==> Function: tln_route"
tln_route