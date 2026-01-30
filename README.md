# Dawn Treader

![Kubernetes](https://img.shields.io/badge/kubernetes-326ce5.svg?&style=for-the-badge&logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=Helm&labelColor=0F1689)
![ArgoCD](https://img.shields.io/badge/Argo%20CD-1e0b3e?style=for-the-badge&logo=argo&logoColor=#d16044)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/Amazon_AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)

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
- **Terraform**: Used to provision the AWS infrastructure, including the VPC, subnets, security groups, and the EC2 instance that would host the Kubernetes cluster. I opted for a _m7i-flex.large_ instance, the biggest instance available in the free tier, to ensure sufficient resources for the application.
- **Ansible**: Used to configure the EC2 instance, install Docker, k3s, and ArgoCD, and deploy the application using the same GitOps workflow as in the local cluster, but automatically.

## Deployment
```
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
```

## Streamlining the application

Once the application was successfully running in the local Kubernetes cluster with ArgoCD, I took the opportunity to streamline and optimise it. This involved notably **removing NGINX**: the original application used NGINX as a reverse proxy for the different services; in a Kubernetes environment, the ingress controller (Traefik in this case) handles routing and load balancing, thus making NGINX redundant.

The pod was removed, although it could still be useful in the case that the frontend would serve static files in the future.

## Corrections and future improvements

The migration from Docker to Kubernetes has led to some application-related bugs, for instance with the avatars used in-game. The Docker solution had a shared volume used by the client and the server, however with Kubernetes, the current implementation is a standard PersistentVolume on a local disk, which only supports ReadWriteOnce, not ReadWriteMany.

This means that the volume cannot be shared across multiple pods simultaneously.  For the avatar features to work properly again, I will have to use a different storage solution, such as NFS or a cloud storage service like the AWS EFS.

Also, the WebSockets connections used for the real-time chat and multiplayer mode need to be reconfigured to account for the change of platform, domain names, and ingress controller.

Even though the source code is virtually the same as before the migration, the change of platform has impacted the functionality of the application. This highlights the real-life challenges faced when migrating applications across different platforms.

## Final thoughts

This project has been a valuable experience in learning how to migrate applications from Docker Compose to Kubernetes. Kubernetes is an extremely powerful platform, but it also comes with a steep learning curve and requires a different mindset compared to Docker.

Before embarking on this journey, I humbly thought I had a decent understanding of containerisation and orchestration, but I quickly realised that there is much more to learn. The gap between working on a local cluster and working on a cloud instance is considerable: just considering ArgoCD for instance, it meant dropping the UI and embracing the CLI for all operations, applying manifests, troubleshooting via logs, monitoring sync status, and so on.

I understand now why Docker, Kubernetes or Helm share maritime-themed names. In many aspects, leaving the comfort of the _localhost_ harbour and venturing into the open waters of the cloud felt like navigating uncharted territory. But it was also a very exciting and rewarding experience, and I look forward to continuing this journey.

## Review and feedback

If you have made it this far and are still reading, thank you very much for your interest; I hope that you enjoyed this journey.

If you'd like to try out the application, it is available at: [https://mrlouf.studio](https://mrlouf.studio) as of January 2026.

I welcome any review or feedback, especially regarding the usage I have made of the Kubernetes platform and DevOps practices. Feel free to open an issue or a pull request if you have suggestions for improvements, optimisations, or additional features.

|Technologies used ||
|--|--|
|**Containerization & Orchestration** | Docker, Kubernetes (k3d), Helm|
|**GitOps & Automation** | ArgoCD, Ansible, Terraform|
|**Cloud Infrastructure**|AWS (VPC, EC2, SG)|
|**Monitoring**|Prometheus, Grafana|
|**Networking**| Traefik (Ingress Controller), Let's Encrypt (TLS/SSL)|
|**Image Registry**| GitHub Container Registry (GHCR)|

---

#### Why that name?

This is a personal homage to C.S. Lewis' work that I discovered at a young age and still enjoy to this day.
Dawn Treader is an infrastructure journey - a ship built to carry an application from familiar shores into open waters.
What begins as a local experiment becomes a living Kubernetes cluster, navigated by Helm charts and GitOps maps, crewed by Ansible, and guided steadily toward the cloud.

This project explores how modern platforms are not just deployed, but sailed: deliberately, declaratively, and with curiosity for what lies beyond the horizon, in the hopes to find Aslan's country.