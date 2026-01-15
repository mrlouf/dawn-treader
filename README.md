# Dawn Treader

Dawn Treader is a cloud-native infrastructure project designed to demonstrate the evolution of a web application from local development to production-grade cloud deployment.

Starting with a local Kubernetes cluster running on **k3d**, the project adopts GitOps principles with **ArgoCD**, package management via **Helm**, and progressively extends to **AWS** using **Terraform** and **Ansible**.

The focus is on reproducibility, declarative infrastructure, and clean delivery workflows across environments.

## The web application

This project reuses a web application developed as an academic group project. The application allows users to play a game of Pong in the same spirit of the famous game released by Atari in 1972. 
