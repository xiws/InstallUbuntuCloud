#!/bin/bash

# user info
IP_ADDR=$(hostname -I | awk '{print $1}')
NODE_NAME=$(hostname)

sudo ssh-keygen -t rsa -C "zhongxiwang@live.com"
echo -e "RSAAuthentication yes\nPubkeyAuthentication yes\nPermitRootLogin yes\nAuthorizedKeysFile .ssh/authorized_keys" |cat >> /etc/ssh/sshd_config
service sshd restart
echo -e "$IP_ADDR $NODE_NAME" | cat >> /etc/hosts 

# install docker
sudo apt install -y docker.io 
mkdir /etc/containerd
containerd config default > /etc/containerd/config.toml
sudo sed -i 's|kubeadm.k8s.io/pause:2.8|registry.aliyuncs.com/google_containers/pause:3.9|g' /etc/containerd/config.toml
service containerd restart


# install kubeadm
sudo apt-get install -y ca-certificates curl software-properties-common apt-transport-https curl
curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
sudo tee /etc/apt/sources.list.d/kubernetes.list <<EOF
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

sudo apt-get update
sudo apt install -y kubectl kubelet kubeadm

sudo tee /root/init.default.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 1.2.3.4
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/docker.sock
  imagePullPolicy: IfNotPresent
  name: master
  taints: null
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.aliyuncs.com/google_containers
kind: ClusterConfiguration
kubernetesVersion: 1.28.0
networking:
  dnsDomain: cluster.local
  serviceSubnet: 10.96.0.0/12
scheduler: {}
EOF

sudo sed -i "s|1.2.3.4|$IP_ADDR|g" /root/init.default.yaml
sudo sed -i "s|master|$NODE_NAME|g" /root/init.default.yaml
kubeadm init --config=init.default.yaml --v=5
# kubeadm init --config=init.default.yaml --v=5