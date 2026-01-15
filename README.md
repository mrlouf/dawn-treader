# Dawn Treader

Dawn Treader is a cloud-native infrastructure project designed to demonstrate the evolution of a web application from local development to production-grade cloud deployment.

Starting with a local Kubernetes cluster running on **k3d**, the project adopts GitOps principles with **ArgoCD**, package management via **Helm**, and progressively extends to **AWS** using **Terraform** and **Ansible**.

The focus is on reproducibility, declarative infrastructure, and clean delivery workflows across environments.

## The web application

This project reuses a web application developed as an academic group project. The application allows users to play a game of Pong in the same spirit of the famous game released by Atari in 1972. 
The application was originally divided into eight containers orchestrated with Docker Compose.
More details about the application can be found in the [original repository](https://github.com/mrlouf/ft_transcendence).

## Migration to Kubernetes

The first step of this project was to migrate the application from Docker Compose to Kubernetes/Helm while keeping the same architecture and functionalities. The goal was to have a local Kubernetes cluster running on k3d with the same application as before but deployed with Helm charts instead of Docker Compose files.

This migration involved creating Helm charts for each component of the application, defining Kubernetes resources such as Deployments, Services, ConfigMaps, and PersistentVolumeClaims, and configuring the application to work in a Kubernetes environment.

In short: I had to translate Docker Compose concepts to Kubernetes concepts while ensuring that the application remained functional and performant. This was also an opportunity to improve some aspects of the build, such as the manual allocation
of resources (CPU, memory) to each pod and the implementation of liveness and readiness probes to replace the previous healthcheck mechanism.

The resulting Helm charts can be found in the `helm/dawn-treader` directory.
