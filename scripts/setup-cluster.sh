#!/bin/bash

#   This script sets up a local k3d Kubernetes cluster with Docker, Helm and the rest.
#   It is intended for Debian-based systems.
#   In the future, this script should be refactored into Ansible roles for better maintainability.


# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color


set -e

#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#                   Setup Docker                   #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#

# Install Docker first if not present:
if ! systemctl is-active --quiet docker; then

    echo -e "${YELLOW}Installing Docker...${NC}"

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
    echo -e "${GREEN}Docker already installed and running${NC}"
fi

#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#                   Setup k3d + kubectl            #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#

# Install k3d 
echo -e "${BLUE}Starting k3d...${NC}"
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install kubectl
if command -v kubectl &> /dev/null; then
    echo -e "${GREEN}kubectl is already installed${NC}"
else
    echo -e "${YELLOW}kubectl not found, installing...${NC}"
    curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi

if k3d cluster list | grep -q "dawn-treader"; then
    echo -e "${YELLOW}k3d cluster 'dawn-treader' already exists${NC}"
else
    # Create k3d cluster
    echo -e "${BLUE}Creating k3d cluster...${NC}"
    k3d cluster create dawn-treader --wait \
      --port "80:80@loadbalancer" \
      --port "443:443@loadbalancer" \
      --port "5173:5173@loadbalancer" \
      --port "3100:3100@loadbalancer" \
      --agents 2
fi


# export KUBECONFIG="$(k3d kubeconfig write dawn-treader)"
mkdir -vp ~/.kube
k3d kubeconfig merge dawn-treader --kubeconfig-merge-default

#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#                   Install Helm                   #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#

if command -v helm &> /dev/null; then
    echo -e "${GREEN}Helm is already installed${NC}"
else
    # Install Helm
    echo -e "${BLUE}Installing Helm...${NC}"
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
    chmod 700 get_helm.sh
    ./get_helm.sh && rm get_helm.sh
fi


#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#                   Build Docker images            #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#

# docker build -t app-nginx:latest ./nginx
docker build -t app-frontend:latest ./app/frontend
docker build -t app-backend:latest ./app/backend

##############
docker tag app-backend:latest ghcr.io/mrlouf/dawn-treader-backend:latest
docker tag app-frontend:latest ghcr.io/mrlouf/dawn-treader-frontend:latest
##############

docker push ghcr.io/mrlouf/dawn-treader-backend:latest
docker push ghcr.io/mrlouf/dawn-treader-frontend:latest

k3d image import \
  app-frontend:latest \
  app-backend:latest \
  -c dawn-treader

#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#                   Install ArgoCD                 #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl wait -n argocd --for=condition=Ready pods --all --timeout=300s

kubectl apply -n argocd -f ./argocd/ingress.yaml

kubectl patch deployment argocd-server -n argocd --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--insecure"}]'
kubectl rollout status deployment/argocd-server -n argocd

kubectl wait -n argocd --for=condition=Available deployment argocd-server --timeout=120s

#   You should delete the argocd-initial-admin-secret from the Argo CD namespace once you changed the password.
#   The secret serves no other purpose than to store the initially generated password in clear and can safely be deleted at any time.
#   It will be re-created on demand by Argo CD if a new admin password must be re-generated.
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo $ARGOCD_PASSWORD

#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#                   Deploy the app                 #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#

kubectl create namespace dawn-treader

kubectl create secret generic dawn-treader-secrets \
  --from-literal=jwtSecret="$(openssl rand -hex 32)" \
  --from-literal=jwtRefreshSecret="$(openssl rand -hex 32)" \
  --from-literal=jwtExpiresIn="15minutes" \
  --from-literal=sessionSecret="$(openssl rand -hex 32)" \
  --from-literal=blockchainPrivateKey="$(openssl rand -hex 32)" \
  --from-literal=grafanaPassword="$(openssl rand -hex 32)" \
  --from-literal=adminEmail="ft.transcendence.42.pong@gmail.com" \
  --from-literal=domainName="localhost" \
  -n dawn-treader

kubectl apply -n argocd -f ./argocd/app-dev.yaml

