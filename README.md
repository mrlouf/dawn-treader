# Dawn Treader

Dawn Treader is a cloud-native infrastructure project designed to demonstrate the evolution of a web application from local development to production-grade cloud deployment.

Starting with a local Kubernetes cluster running on **k3d**, the project adopts GitOps principles with **ArgoCD**, package management via **Helm**, and progressively extends to **AWS** using **Terraform** and **Ansible**.

The focus is on reproducibility, declarative infrastructure, and clean delivery workflows across environments.

## The web application

This project reuses a web application developed as an academic group project. The application is a game of Pong inspired by the famous game released by Atari in 1972, enhanced with social features such as user authentication, friend lists, chat, and matchmaking. 
The application was originally divided into eight containers orchestrated with Docker Compose.
More details about the application can be found in the [original repository](https://github.com/mrlouf/ft_transcendence).

## Migration to Kubernetes

The first step of this project was to migrate the application from Docker Compose to Kubernetes/Helm while keeping the same architecture and functionalities. The goal was to have a local Kubernetes cluster running on k3d with the same application as before but, deployed with Helm charts instead of Docker Compose files.

This migration involved creating the Helm charts for each component of the application, defining Kubernetes resources such as Deployments, Services, ConfigMaps, and PersistentVolumeClaims, and configuring the application to work in a Kubernetes environment.

In other words, I had to translate from Docker Compose to Kubernetes while ensuring that the application remained functional and performant. This was also an opportunity to improve and fine-tune some aspects of the build, such as the manual allocation of resources (CPU, memory) to each pod or the liveness and readiness probes to replace the previous healthcheck mechanism.

The resulting Helm charts can be found in the `helm/dawn-treader` directory.

## GitOps with ArgoCD

Once the application was successfully migrated to Kubernetes, the next step was to implement a GitOps workflow using ArgoCD. Since the application is now packaged as Helm charts, ArgoCD can be used to automatically deploy and manage the application in the Kubernetes cluster based on the state defined in the Git repository.

This involved setting up an ArgoCD instance in the k3d cluster, creating an application definition that points to the Helm charts in the repository, and configuring ArgoCD to monitor the repository for changes and automatically apply them to the cluster.

I opted to host the application repo within the same repository as the infrastructure code instead of using a separate Git repository or a Helm chart repository. This simplifies the setup and allows for easier management of the entire project in a single place, by a single person (me).

In the future, hosting the application in a Helm chart repository could be envisaged for better separation of concerns and easier sharing of the charts.

## Streamlining the application

Once the application was successfully running in the local Kubernetes cluster with ArgoCD, I took the opportunity to streamline and optimise it. This involved several changes:
- **Removing NGINX**: The original application used NGINX as a reverse proxy for the different services; in a Kubernetes environment, the ingress controller (Traefik in this case) handles routing and load balancing, making NGINX redundant. The pod was removed, although it could still be useful in the case that the frontend would serve static files.