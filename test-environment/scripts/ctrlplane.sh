show()
{ 
    echo
    echo -ne "==> "
    echo -ne "\033[7m$@\033[0m"
    echo -e " <=="
}

show "*** RUNNING: ctrlplane.sh ***"

show "Doing kubeadm init"
kubeadm init \
  --apiserver-advertise-address="$CTRL_PLANE_IP" \
  --apiserver-cert-extra-sans="$CTRL_PLANE_IP" \
  --node-name ctrlplane.local \
  --pod-network-cidr="$POD_NETWORK_CIDR" \
  --ignore-preflight-errors=NumCPU 

show "Setting up kubectl for the vagrant user"
mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/ 

show "Configuring kubectl for the current (root) user"
if [ $UID == 0  ] ; then
  export KUBECONFIG=/etc/kubernetes/admin.conf
fi  

#show "Printing Join Command and copying to /vagrant/scripts"
kubeadm token create --print-join-command | tee /vagrant/scripts/join.sh
chmod 755 /vagrant/scripts/join.sh

#show "Installing Calico"
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/tigera-operator.yaml
curl -s https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/custom-resources.yaml | sed "s#192.168.0.0/16#$POD_NETWORK_CIDR#" > custom-resources.yaml
kubectl apply -f custom-resources.yaml 
#kubectl apply -f /vagrant/manifests/calico.yaml

#show "Enabling bash completion for kubernetes commands"
source <(kubectl completion bash)
kubectl completion bash > /etc/bash_completion.d/kubectl

show "Copying kubectl config (from .kube directory) to /vagrant"
[ -d /vagrant/.kube ] && rm -rf /vagrant/.kube
cp -ri /home/vagrant/.kube/ /vagrant

show "*** COMPLETE: ctrlplane.sh ***"
