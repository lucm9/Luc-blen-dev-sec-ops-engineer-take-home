# BLEN Engineering Take-Home Challenge

Welcome to the BLEN Engineering Take-Home Challenge repository. This challenge is designed to assess candidates' skills in infrastructure-as-code, networking, security scanning, containerization, and CI/CD -- all at **zero cost** with no AWS account required.

## Challenge

**DevSecOps Engineer: Secure Three-Tier Architecture on AWS (Zero-Cost Validation)**
- [Challenge Instructions](challenge.md)
- Focus: Terraform design, network security, IaC/container scanning, Docker Compose, and GitHub Actions CI/CD

### Key Requirement: Zero AWS Cost

Candidates write real Terraform for a full three-tier AWS architecture but validate everything **locally** with `terraform validate`, `tflint`, and `checkov`/`tfsec`. No `terraform apply` is ever run. Docker Compose proves the app works. GitHub Actions (free on public repos) handles CI/CD with security scanning. GHCR (free) replaces ECR for container image storage.

### What Candidates Will Build

1. **Terraform** - Full three-tier AWS architecture (VPC, subnets, RDS, ECS Fargate, ALB) validated locally with linters and security scanners
2. **Docker Compose** - Local proof-of-life showing the Next.js app connected to PostgreSQL
3. **GitHub Actions CI/CD** - PR and merge workflows with Terraform checks, Trivy container scanning, hadolint, gitleaks secret detection, and GHCR image publishing
4. **Security Posture** - IaC scanning, container scanning, secret detection, and a security checklist

## Provided Resources

The repository includes:

- **`app/`** - A pre-built Next.js application with a Dockerfile and database connectivity check (no modifications required)
- **`.github/workflows/pr.yml`** - Skeleton PR workflow with TODO placeholders for each CI job
- **`.github/workflows/merge.yml`** - Skeleton merge workflow with TODO placeholders, including GHCR publishing
- **`challenge.md`** - Complete challenge instructions with evaluation rubric

> The Dockerfile is intentionally imperfect (runs as root, single-stage build). Candidates who run hadolint and Trivy will discover issues and can fix them for bonus points.

## How to Use This Repository

**Candidates:**
1. Click **"Use this template"** to create your own copy (must be **public**). Do **not** fork.
2. Read the [challenge instructions](challenge.md) thoroughly
3. Implement your solution in your repo
4. Update your README with architecture decisions, security considerations, and proof-of-life output
5. Submit the link to your repository to your BLEN recruiting contact

## General Guidelines

- All infrastructure must be defined with Terraform (validated locally, never applied)
- Code quality, documentation, and the ability to explain your solution are important
- Prioritize security and proper network segmentation
- Time management is crucial; focus on core requirements before bonus features
