#!/bin/

#   This script sets up a local k3d Kubernetes cluster with Docker, Helm and the rest.
#   It is intended for Debian-based systems.
#   In the future, this script should be refactored into Ansible roles for better maintainability.

set -e

CLUSTERNAME="dawn-treader"
NAMESPACE="app"

#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#                   Setup Docker                   #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#

# Install Docker first if not present:
if ! systemctl is-active --quiet docker; then
    echo "Installing Docker..."
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    
    # Actually install Docker
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
else
    echo "Docker already installed and running"
fi

#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#                   Setup k3d                      #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#

# Install k3d 
echo "Starting k3d..."
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install kubectl
if command -v kubectl &> /dev/null; then
    echo "kubectl is already installed"
else
    echo "kubectl not found, installing..."
    curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi

# Create k3d cluster
echo "Creating k3d cluster..."
k3d cluster create $CLUSTERNAME --wait \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer" \
  --port "5173:5173@loadbalancer" \
  --port "3100:3100@loadbalancer" \
  --agents 2

export KUBECONFIG="$(k3d kubeconfig write $CLUSTERNAME)"

#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#                   Install Helm                   #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#

# Install Helm
echo -e "\e[34mInstalling Helm...\e[0m"
sudo apt-get install curl gpg apt-transport-https --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm


#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#                   Build Docker images            #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#

docker build -t app-nginx:latest ./nginx
docker build -t app-frontend:latest ./frontend
docker build -t app-backend:latest ./backend
docker build -t app-redis:latest ./redis
docker build -t app-adminer:latest ./adminer
docker build -t app-blockchain:latest ./blockchain
docker build -t app-prometheus:latest ./monitoring/prometheus
docker build -t app-grafana:latest ./monitoring/grafana

k3d image import \
  app-nginx:latest \
  app-frontend:latest \
  app-backend:latest \
  app-redis:latest \
  app-adminer:latest \
  app-blockchain:latest \
  app-prometheus:latest \
  app-grafana:latest \
  -c $CLUSTERNAME
