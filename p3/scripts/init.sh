#!/bin/bash

################################################################################
# Setup Script for Part 3: K3d and Argo CD
################################################################################

# Exit on error, treat unset vars as errors, print command before executing
set -eux
# Ensure the script is being run as sudo
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi
echo $SUDO_USER

################################################################################
# Install Docker (from Docker docs)
################################################################################

# Remove any existing repos so that old repos don't interfere with new setup.
apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
# Add Docker's official GPG key:
apt-get update -y
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
# Update again in case anything changed
apt-get update -y
# Install the latest version of Docker
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Verify that Docker is running
sleep 5
systemctl --no-pager status docker
# let docker run without sudo (important for using k3d without sudo later on)
# sudo usermod -aG docker "$USER"
# newgrp docker
# docker ps

################################################################################
# Install K3d
################################################################################

# Install script from K3d website
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

################################################################################
# Install kubectl on local machine (for interacting with k3d cluster)
################################################################################

# Download Binary
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# Download checksum
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
# Validate download
sha256sum --check <(awk '{print $1"  kubectl"}' kubectl.sha256)
rm -f kubectl.sha256
# Install Binary
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
# Verify install is working
kubectl version --client --output=yaml
rm -f kubectl

################################################################################
# Create a cluster using k3d
################################################################################

# Create the cluster
k3d cluster create
# Verify
k3d cluster list
# Take the config from the newly created cluster and put it in our current users home and use it as the default context
whoami
k3d kubeconfig merge k3s-default --kubeconfig-merge-default
kubectl config use-context k3d-k3s-default
# Set config to be owned by user
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.kube
# Verify nodes are reachable
kubectl get nodes

