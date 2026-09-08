# ThreatLens 

### A containerised Flask application deployed to AWS using Terraform, Docker, ECS and GitHub Actions, with container security built into the CI/CD workflow.


![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazonaws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Containers-2496ED?logo=docker&logoColor=white)
![ECS](https://img.shields.io/badge/ECS-Fargate-FF9900?logo=amazonecs&logoColor=white)
![ECR](https://img.shields.io/badge/Amazon-ECR-FF9900?logo=amazonaws&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?logo=githubactions&logoColor=white)
![OIDC](https://img.shields.io/badge/GitHub-OIDC-181717?logo=github&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-Container_Security-1904DA?logo=aqua&logoColor=white)
![TFLint](https://img.shields.io/badge/TFLint-Terraform_Lint-7B42BC?logo=terraform&logoColor=white)
![Checkov](https://img.shields.io/badge/Checkov-IaC_Security-8A2BE2)
![CloudWatch](https://img.shields.io/badge/CloudWatch-Monitoring-FF4F8B?logo=amazoncloudwatch&logoColor=white)
![Route 53](https://img.shields.io/badge/Route_53-DNS-8C4FFF?logo=amazonroute53&logoColor=white)
![ACM](https://img.shields.io/badge/ACM-TLS%2FHTTPS-DD344C?logo=amazonaws&logoColor=white)
![VPC](https://img.shields.io/badge/AWS_VPC-Networking-FF9900?logo=amazonaws&logoColor=white)
![ALB](https://img.shields.io/badge/ALB-Load_Balancing-8C4FFF?logo=awselasticloadbalancing&logoColor=white)
![S3](https://img.shields.io/badge/Amazon_S3-Remote_State-569A31?logo=amazons3&logoColor=white)
![IAM](https://img.shields.io/badge/AWS_IAM-Security-DD344C?logo=amazonaws&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-Containers-FCC624?logo=linux&logoColor=black)
![Python](https://img.shields.io/badge/Python-Flask-3776AB?logo=python&logoColor=white)
![Git](https://img.shields.io/badge/Git-Version_Control-F05032?logo=git&logoColor=white)

**Live application:** https://tm.threatlenslab.com

## Key Features

- Containerised Python/Flask application
- AWS ECS Fargate deployment
- ECS tasks deployed in private subnets
- No public IP assigned to application containers
- Internet-facing Application Load Balancer
- HTTPS using AWS Certificate Manager
- HTTP → HTTPS redirection
- Custom DNS using Route 53
- Amazon ECR container registry
- Modular Terraform Infrastructure as Code
- S3 remote Terraform state
- Native S3 state locking
- GitHub Actions CI/CD
- GitHub OIDC authentication
- SHA-based Docker image tagging
- Trivy container vulnerability scanning
- TFLint Terraform linting
- Checkov Infrastructure as Code security scanning
- Non-root container runtime
- Multi-stage Docker build
- CloudWatch application logging
- CloudWatch infrastructure alarms
- NAT Gateway for private-subnet outbound connectivity


---

##  Project Overview

ThreatLens is a hands-on DevSecOps project that demonstrates how a containerised application can be securely built, scanned, provisioned and deployed to AWS using Infrastructure as Code and CI/CD.

The application runs on **Amazon ECS Fargate inside private subnets** with no public IP address. An internet-facing Application Load Balancer provides the public entry point, terminates TLS and forwards traffic to the application on port `8080`.

Terraform manages the AWS infrastructure while GitHub Actions automates infrastructure validation, container security scanning, image publishing and ECS deployment.

GitHub Actions authenticates to AWS using **OIDC and short-lived credentials**, removing the need to store long-lived AWS access keys in GitHub.



## Architecture

The diagram below shows the AWS infrastructure, CI/CD pipeline,
container security scanning and Terraform workflow used to deploy ThreatLens.

<img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/f047830b-e7a7-45a9-9a17-d018226a7d56" />




##  Deployment Workflow

```text
Code
  ↓
GitHub
  ↓
GitHub Actions
  ├── Terraform → TFLint → Checkov → Plan / Apply
  └── Docker Build → Trivy → Amazon ECR → ECS Deployment
                                             ↓
                                        ECS Fargate
                                             ↓
                                      ALB / HTTPS
                                             ↓
                                  tm.threatlenslab.com
```

---




The infrastructure is deployed in AWS `eu-west-2` across two Availability Zones.

### Request Flow

```text
Internet
   │
   ▼
Route 53
   │
   ▼
Application Load Balancer
Public Subnets
   │
   ├── HTTP :80 → 301 Redirect → HTTPS :443
   │
   ▼
Target Group
HTTP :8080
   │
   ▼
ECS Fargate
Private Subnets
assign_public_ip = false
   │
   ▼
Gunicorn / Flask
Port 8080
Non-root appuser
```

Only the Application Load Balancer is internet-facing. ECS tasks remain within private subnets and receive application traffic through the ALB.



# AWS Infrastructure

## VPC & Networking

ThreatLens runs inside a dedicated VPC:

```text
Region: eu-west-2
VPC:    10.0.0.0/16
```

The network spans two Availability Zones.

### Public Subnets

```text
10.0.0.0/24 — eu-west-2a
10.0.1.0/24 — eu-west-2b
```

The public layer contains the internet-facing Application Load Balancer.

A NAT Gateway provides outbound connectivity for workloads running inside the private subnets.

### Private Subnets

```text
10.0.2.0/24 — eu-west-2a
10.0.3.0/24 — eu-west-2b
```

The ECS Fargate service runs within the private subnet tier.

```hcl
assign_public_ip = false
```

This prevents ECS tasks from being directly exposed to the internet.

### Security Groups

Traffic between the load balancer and application is restricted using security-group references.

```text
Internet
   │
   │ 80 / 443
   ▼
ALB Security Group
   │
   │ TCP 8080
   ▼
ECS Security Group
```

The ECS security group accepts application traffic on port `8080` from the ALB security group rather than from the public internet.

---

# Containerisation

The application is packaged using Docker and served by Gunicorn.

The production container:

- Uses an Alpine-based runtime
- Uses a multi-stage build
- Runs as an unprivileged `appuser`
- Uses Gunicorn instead of the Flask development server
- Exposes port `8080`
- Includes a container health check
- Uses a `.dockerignore` to reduce build context

The application runs as:

```text
USER appuser
Gunicorn → 0.0.0.0:8080
```

Using port `8080` allows the application to run without root privileges while the ALB continues to expose standard HTTP/HTTPS ports externally.

### Image Optimisation

The original image was approximately:

```text
230 MB
```

After moving to the optimized Alpine-based build:

```text
140 MB
```

This reduced the Docker image size by approximately **39%**.

---

# CI/CD

GitHub Actions provides separate workflows for application delivery, security scanning, infrastructure deployment and ECS deployment.

```text
.github/workflows/
├── Push-Docker-Image-To-ECR.yml
├── Deploy-ECS.yml
├── Terraform.yml
└── trivy.yml
```

## Application Pipeline

Application changes follow:

```text
Git Push
   │
   ▼
GitHub Actions
   │
   ▼
Build Docker Image
   │
   ▼
Trivy Scan
   │
   ▼
Authenticate to AWS using OIDC
   │
   ▼
Push Image to Amazon ECR
   │
   ├── latest
   └── Git commit SHA
   │
   ▼
Register ECS Task Definition
   │
   ▼
Deploy ECS Service
```

Using Git commit SHA tags provides traceability between a deployed container and the source code used to build it.

---

# Infrastructure CI

Terraform changes are automatically checked before infrastructure changes are deployed.

The pipeline runs:

```text
terraform fmt
      ↓
terraform init
      ↓
terraform validate
      ↓
TFLint
      ↓
Checkov
      ↓
terraform plan
      ↓
terraform apply
```

### TFLint

TFLint provides Terraform-specific linting and catches configuration and provider issues before deployment.

### Checkov

Checkov scans the Terraform configuration for infrastructure security and configuration issues.

It currently runs in advisory mode, allowing findings to be reviewed while keeping the project pipeline usable during development.

### Terraform Plan

Infrastructure changes are previewed using:

```bash
terraform plan -out=tfplan
```

This makes the proposed infrastructure changes visible before they are applied.

---

# GitHub OIDC & IAM

GitHub Actions authenticates to AWS using OpenID Connect.

```text
GitHub Actions
      │
      │ OIDC
      ▼
AWS STS
      │
      │ AssumeRole
      ▼
threatlens-github-actions-role
```

This avoids storing long-lived:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

inside GitHub.

Instead, GitHub Actions receives temporary AWS credentials by assuming the dedicated IAM role.

The ECS workload uses a separate execution role:

```text
threatlens-ecs-execution-role
```

This separates CI/CD permissions from the permissions required by the ECS task.

---

# Container Security

## Trivy

Trivy is integrated into the CI/CD workflow and scans the Docker image for known vulnerabilities before deployment.

The pipeline checks for:

```text
HIGH
CRITICAL
```

severity vulnerabilities.

This makes vulnerability scanning part of the delivery process rather than relying solely on manual security checks after deployment.

---

# Amazon ECS Fargate

The Flask application runs using Amazon ECS Fargate.

The deployment consists of:

- ECS cluster
- Task definition
- ECS service
- Fargate task
- ECS execution role
- CloudWatch logging
- ALB target group integration

The current validated deployment reached:

```text
Desired: 1
Running: 1
Pending: 0
```

The Application Load Balancer target also reported:

```text
State: healthy
```

---

# Load Balancing & HTTPS

The Application Load Balancer is deployed across the two public subnets.

### HTTP Listener

```text
Port 80
   │
   └── 301 Redirect → HTTPS :443
```

### HTTPS Listener

```text
HTTPS :443
     │
     ▼
Target Group
HTTP :8080
     │
     ▼
ECS Fargate :8080
```

TLS is terminated at the ALB using a certificate provisioned through AWS Certificate Manager.

Internal ALB-to-container communication uses HTTP on port `8080`.

---

# DNS

Amazon Route 53 provides DNS for:

```text
tm.threatlenslab.com
```

The DNS record directs users to the Application Load Balancer.

The public application is therefore accessed through:

```text
https://tm.threatlenslab.com
```

rather than directly through an ECS task or IP address.

---

# Monitoring & Logging

Application logs are sent from ECS to Amazon CloudWatch Logs.

```text
/ecs/threatlens
```

Log retention is configured for:

```text
30 days
```

CloudWatch alarms monitor:

| Metric | Trigger |
|---|---|
| ECS CPU utilisation | ≥ 80% |
| ECS memory utilisation | ≥ 80% |
| ALB unhealthy targets | ≥ 1 |
| ALB target 5XX responses | ≥ 5 |

This provides visibility into application health and ECS resource utilisation.

---

# Terraform Infrastructure as Code

The AWS environment is provisioned using reusable Terraform modules.

```text
infra/
├── main.tf
├── provider.tf
├── variables.tf
├── outputs.tf
│
└── modules/
    ├── acm/
    ├── alb/
    ├── ecr/
    ├── ecs/
    ├── iam/
    ├── monitoring/
    ├── route53/
    ├── security-groups/
    └── vpc/
```

This keeps networking, compute, security, monitoring and supporting AWS services separated into reusable components.

---

# Remote Terraform State

Terraform state is stored remotely in Amazon S3.

```hcl
terraform {
  backend "s3" {
    bucket       = "threatlens-terraform-state-113462084471"
    key          = "threatlens/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
}
```

Native S3 state locking is enabled using:

```hcl
use_lockfile = true
```

This protects against concurrent Terraform operations modifying the same state.

The backend infrastructure is managed separately through:

```text
bootstrap/
```

---

# Application

ThreatLens is a lightweight Python Flask application.

The main routes are:

```text
/
```

and:

```text
/health
```

The health endpoint returns:

```json
{
  "status": "ok"
}
```

The endpoint is used for application and load balancer health checks.

---

# Running Locally

Clone the repository:

```bash
git clone https://github.com/Faiz425/threatlens-platform.git
cd threatlens-platform
```

Build the production container:

```bash
docker build -t threatlens:local -f Docker/Dockerfile .
```

Run it:

```bash
docker run --rm -p 8080:8080 threatlens:local
```

Test the application:

```bash
curl http://localhost:8080
```

Test the health endpoint:

```bash
curl http://localhost:8080/health
```

Expected response:

```json
{"status":"ok"}
```

You can also expose local port `80` while keeping the container on its non-root port:

```bash
docker run --rm -p 80:8080 threatlens:local
```

---

# Project Structure

```text
threatlens-platform/
│
├── app/
│   ├── app.py
│   ├── scanner.py
│   └── requirements.txt
│
├── Docker/
│   └── Dockerfile
│
├── bootstrap/
│   └── main.tf
│
├── infra/
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   │
│   └── modules/
│       ├── acm/
│       ├── alb/
│       ├── ecr/
│       ├── ecs/
│       ├── iam/
│       ├── monitoring/
│       ├── route53/
│       ├── security-groups/
│       └── vpc/
│
├── .github/
│   └── workflows/
│       ├── Deploy-ECS.yml
│       ├── Push-Docker-Image-To-ECR.yml
│       ├── Terraform.yml
│       └── trivy.yml
│
├── .gitignore
└── README.md
```

---

# Deployment Evidence

The screenshots below show the application, infrastructure and CI/CD pipelines running successfully.

## Live HTTPS Application

![Live Application](docs/images/live-application.png)

## Health Endpoint

```text
https://tm.threatlenslab.com/health
```

![Health Endpoint](docs/images/health-endpoint.png)

## ECS Service

The deployed ECS service reached steady state:

```text
Desired: 1
Running: 1
Pending: 0
```

![ECS Service](docs/images/ecs-service.png)

## ALB Target Health

The ECS task successfully registered with the target group and reached:

```text
State: healthy
```

![ALB Target Health](docs/images/alb-target-health.png)

## GitHub Actions

![GitHub Actions](docs/images/github-actions.png)

## Trivy Security Scan

![Trivy](docs/images/trivy.png)

## Terraform Pipeline

![Terraform](docs/images/terraform.png)

## Amazon ECR

![Amazon ECR](docs/images/ecr.png)

## CloudWatch

![CloudWatch](docs/images/cloudwatch.png)

---

# Troubleshooting

One of the most valuable parts of this project was diagnosing issues across multiple layers of the deployment.

## Non-Root Container & Port 80

After changing the production container to run as an unprivileged user, ECS tasks repeatedly stopped.

CloudWatch showed:

```text
connection to ('0.0.0.0', 80) failed: [Errno 13] Permission denied
```

The application was attempting to bind Gunicorn to privileged port `80`.

I moved the internal application port to:

```text
8080
```

and updated the:

- Dockerfile
- Docker health check
- ECS task definition
- ECS port mapping
- Security group
- ALB target group

The final architecture became:

```text
Internet
   │
HTTPS :443
   ▼
ALB
   │
HTTP :8080
   ▼
ECS Fargate
   │
   ▼
Gunicorn :8080
USER appuser
```

This allowed the container to remain non-root while the public application continued using standard HTTPS.

## ALB Target Group Replacement

Changing the target group from port `80` to `8080` required Terraform to replace the resource.

The first deployment failed because the existing target group was still referenced by an ALB listener.

The target group was updated to support safe replacement:

```hcl
lifecycle {
  create_before_destroy = true
}
```

A generated name prefix was also used so the new and old target groups could temporarily coexist during replacement.

## Container Image Version

After updating the ECS configuration to `8080`, a task still attempted to start Gunicorn on port `80`.

I compared:

```text
Git commit
     ↓
Docker build
     ↓
ECR image tag
     ↓
ECR image digest
     ↓
ECS task definition
     ↓
Running ECS task
```

This showed that the deployed ECR image had been built from an earlier Dockerfile.

After committing the corrected Dockerfile, rebuilding the image and deploying the new task definition, ECS reached steady state and the ALB target became healthy.

## IAM & S3 State

The Terraform pipeline also encountered IAM `AccessDenied` and S3 state-locking permission errors.

I traced the failed AWS API calls and updated the permissions required by the GitHub Actions IAM role.

OIDC authentication was retained throughout rather than replacing it with static AWS access keys.

---

# What I Learned

This project helped me understand how individual DevOps tools connect together in a complete deployment.

The main areas I gained practical experience with were:

- AWS VPC networking
- Public and private subnet design
- NAT Gateway routing
- ECS Fargate
- Amazon ECR
- Application Load Balancers
- Route 53 and DNS
- AWS Certificate Manager
- IAM and least-privilege concepts
- GitHub OIDC
- Terraform modules
- Terraform remote state and locking
- Docker multi-stage builds
- Non-root container security
- GitHub Actions
- CI/CD
- Trivy
- TFLint
- Checkov
- CloudWatch logs and alarms
- Debugging ECS task failures
- ALB health checks
- Container image/version traceability

The troubleshooting was particularly valuable because failures had to be followed across **GitHub Actions → IAM → Terraform → ECR → ECS → ALB → CloudWatch**, rather than debugging each component in isolation.

---

# Future Improvements

The current deployment meets the goals of the project, but further production hardening could include:

- ECS service autoscaling
- AWS WAF
- VPC Flow Logs
- ALB access logging
- ECS Container Insights
- KMS encryption where appropriate
- AWS Secrets Manager if application secrets are introduced
- Additional unit and integration tests
- Blue/green deployments
- Multi-AZ NAT Gateway design for higher availability
- Further remediation of Checkov findings

---

# Project Status

**Successfully deployed and validated.**

```text
ECS Desired Tasks : 1
ECS Running Tasks : 1
ECS Pending Tasks : 0
ALB Target        : Healthy
HTTPS             : Enabled
ECS Public IP     : Disabled
Container User    : Non-root
Application Port  : 8080
CI/CD             : Passing
```

**Live:** https://tm.threatlenslab.com

---

# Author

**Faizan Akbar**

DevOps / Cloud / DevSecOps portfolio project focused on AWS, Terraform, Docker, CI/CD, Infrastructure as Code and cloud security.
