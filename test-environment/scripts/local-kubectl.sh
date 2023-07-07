#!/bin/bash

echo "==> Configuring kubectl on local linux host"
[ -d ~/.kube ] && rm -rf ~/.kube
cp -ri /home/edrandall/github/vagrant/kubernetes-env-ubuntu/.kube ~/