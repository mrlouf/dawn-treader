# Dawn Treader

Dawn Treader is a cloud infrastructure project designed to showcase the evolution of a web application from local development to production-grade cloud deployment.

Starting with a local Kubernetes cluster running on **k3d**, the project adopts GitOps principles with **ArgoCD**, package management via **Helm**, and progressively extends to **AWS** using **Terraform** and **Ansible**.

## The web application

This project reuses a web application developed as an academic group project. The application is a game of Pong inspired by the famous game released by Atari in 1972, enhanced with social features such as user authentication, friend lists, chat, and matchmaking. 
The application was originally divided into eight containers orchestrated with Docker Compose.
More details about the application can be found in the [original repository](https://github.com/mrlouf/ft_transcendence).

## Migration to Kubernetes

The first step of this project was to migrate the application from Docker Compose to Kubernetes/Helm while keeping the same architecture and functionalities. The goal was to have a local Kubernetes cluster running on k3d with the same application as before, but deployed with Helm charts instead of Docker Compose files.

This migration involved creating the Helm charts for each component of the application, defining Kubernetes resources such as Deployments, Services, ConfigMaps, and PersistentVolumeClaims, and configuring the application to work in a Kubernetes environment.

In other words, I had to _translate_ from Docker Compose to Kubernetes while ensuring that the application remained functional and performant. This was also an opportunity to improve and fine-tune some aspects of the build, such as the manual allocation of resources (CPU, memory) to each pod or the liveness and readiness probes to replace the previous healthcheck mechanism.

The resulting Helm charts can be found in the `helm/dawn-treader` directory.

## GitOps with ArgoCD

Once the application was successfully migrated to Kubernetes, the next step was to implement a GitOps workflow using ArgoCD. Since the application is now packaged as Helm charts, ArgoCD can be used to automatically deploy and manage the application in the Kubernetes cluster based on the state defined in the Git repository.

This involved setting up an ArgoCD instance in the k3d cluster, creating an application definition that points to the Helm charts in the repository, and configuring ArgoCD to monitor the repository for changes and automatically apply them to the cluster.

I opted to host the application repo within the same repository as the infrastructure code instead of using a separate Git repository or a Helm chart repository. This simplifies the setup and allows for easier management of the entire project in a single place, by a single person (me).

The Docker images are hosted publicly on GitHub Container Registry, and the ArgoCD application definition points to the specific image tags to use for each component.

## From local to cloud deployment

Once set afloat smoothly in the harbour (the local Kubernetes cluster), it was time to set sail towards the cloud. The next step was to extend the infrastructure to deploy the application on AWS. This involved several components:
- **Terraform**: Used to provision the AWS infrastructure, including the VPC, subnets, security groups, and the EC2 instance that would host the Kubernetes cluster. I opted for a m7i-flex.large instance, the biggest instance available in the free tier, to ensure sufficient resources for the application.
- **Ansible**: Used to configure the EC2 instance, install Docker, k3s, and ArgoCD, and deploy the application using the same GitOps workflow as in the local cluster, but automatically.

## Deployment

┌─────────────────────────────────────────────────────────────────┐
│                    Dawn Treader Deployment                      │
└─────────────────────────────────────────────────────────────────┘

  Developer                 GitHub                  AWS EC2
  ─────────                ────────                ─────────

     │                        │                        │
     │  git push              │                        │
     ├───────────────────────>│                        │
     │                        │                 ┌────────────┐
     │                        │                 │  ArgoCD    │
     │                        │                 │ (namespace)│
     │                        │                 └──────┬─────┘
     │                        │   ArgoCD polls repo    │
     │                        │<───────────────────────┤
     │                        │                        │
     │                        │   Fetch Helm charts    │
     │                        ├───────────────────────>│
     │                        │                   Helm Deploy
     │                        │                        │
     │                        │                        v
     │                        │               ┌─────────────────┐
     │                        │               │  dawn-treader   │
     │                        │               │   (namespace)   │
     │                        │               ├─────────────────┤
     │                        │               │ • Frontend      │
     │                        │               │ • Backend       │
     │                        │               │ • Redis         │
     │                        │               │ • Blockchain    │
     │                        │               │ • Prometheus    │
     │                        │               │ • Grafana       │
     │                        │               └────────┬────────┘
     │                        │                        │
     │                        │                 Traefik Ingress
     │                        │                        │
     │                                                 v
     │                                        https://mrlouf.studio
     │                                                 │
  Users ──────────────────────────────────────────────>│

## Streamlining the application

Once the application was successfully running in the local Kubernetes cluster with ArgoCD, I took the opportunity to streamline and optimise it. This involved several changes:
- **Removing NGINX**: The original application used NGINX as a reverse proxy for the different services; in a Kubernetes environment, the ingress controller (Traefik in this case) handles routing and load balancing, making NGINX redundant. The pod was removed, although it could still be useful in the case that the frontend would serve static files.
- **Removing Blockchain**: The original application included a blockchain container to deploy smart contracts for saving the game scores, but to be honest, it was more of a gimmick than a real feature. It added unnecessary complexity and overhead to the application, so I decided to remove it and simplify the architecture.