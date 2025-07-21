# 🌐 Full Stack Deployment on AWS using Terraform, Docker & Kubernetes

## 📘 Overview

This project provisions a full cloud infrastructure on **AWS** using **Terraform**, and deploys a Node.js-based website using **Docker** and **Kubernetes**. It demonstrates complete automation of the following:

- Creating a custom VPC with public/private subnets
- Launching an EC2 instance (in public subnet)
- Launching an RDS MySQL database (in private subnet)
- Cloning a website on EC2 and installing Node.js, Docker, Kubernetes
- Building a Docker image and pushing it to Docker Hub
- Pulling and running the app on Kubernetes using Pods

---

## ⚙️ Tech Stack

- **Infrastructure as Code**: Terraform
- **Cloud Platform**: AWS (VPC, EC2, RDS)
- **Backend**: MySQL (RDS)
- **Application**: Node.js
- **Containerization**: Docker
- **Orchestration**: Kubernetes (k3s or kubectl)

---

## 🧱 Infrastructure Architecture

- **VPC**
  - Public Subnet → EC2 Instance
  - Private Subnet → RDS (MySQL)
- **Security Groups**
  - EC2: Allows SSH (22), HTTP (80), K8s ports
  - RDS: Allows MySQL traffic only from EC2’s SG
- **EC2**
  - Clones website code from GitHub
  - Installs required tools: Node.js, Docker, kubectl
  - Builds and pushes Docker image to Docker Hub
  - Deploys website as Kubernetes Pod

---

## 🚀 How to Use

1. 🔐 Configure AWS Credentials
        export AWS_ACCESS_KEY_ID="your-access-key"
        export AWS_SECRET_ACCESS_KEY="your-secret-key"
2. ADD Docker Login username and password
3. ADD RDS Endpoint,Username and password, DB name
4. 📦 Terraform Setup
        terraform init        # Initialize providers and modules
        terraform plan        # Preview resources
        terraform apply       # Deploy infrastructure

