# DevSecOps Engineer Take-Home: Secure Three-Tier Architecture on AWS

## Overview

This assessment evaluates your ability to design a **secure, scalable three-tier architecture** on AWS using Terraform -- without provisioning any real resources or incurring any cost. You will write production-quality Terraform for the full architecture, validate it locally with linters and security scanners, prove the application works with Docker Compose, and wire everything together with GitHub Actions CI/CD.

**No AWS account is required. No `terraform apply`. Zero cost.**

## Getting Started

1. Click **"Use this template"** on GitHub to create your own copy (must be **public** for Actions to run free). Do **not** fork -- use the template button so your repo is not linked to other candidates' submissions.
2. **Read** this entire document before writing any code
3. **Implement** your solution following the parts below
4. **Document** your work in your README (see [Submission Instructions](#submission-instructions))
5. **Submit** the link to your repository to your BLEN recruiting contact

### Expected Project Structure
```
/
├── terraform/              # All Terraform configuration files
├── app/                    # Provided Next.js application (do not modify)
├── docker-compose.yml      # Local proof-of-life (you create this)
├── .github/workflows/      # CI/CD pipelines (skeletons provided, you implement)
│   ├── pr.yml
│   └── merge.yml
└── README.md               # Your documentation
```

### Architecture Diagram

The Terraform you write must describe this architecture. It will be validated locally -- never applied.

```
                        ┌─────────────────────────────────────────────────────┐
                        │                       VPC                           │
                        │                                                     │
                        │  ┌─────────────────┐     ┌─────────────────┐       │
        Internet ──────►│  │  Public Subnet   │     │  Public Subnet   │      │
                        │  │     (AZ-1)       │     │     (AZ-2)       │      │
                        │  │  ┌───────────┐   │     │  ┌───────────┐   │      │
                        │  │  │    ALB    │   │     │  │    ALB    │   │      │
                        │  │  └───────────┘   │     │  └───────────┘   │      │
                        │  │  ┌───────────┐   │     │  ┌───────────┐   │      │
                        │  │  │  NAT GW   │   │     │  │  NAT GW   │   │      │
                        │  │  └─────┬─────┘   │     │  └─────┬─────┘   │      │
                        │  └────────┼─────────┘     └────────┼─────────┘      │
                        │           │                        │                │
                        │  ┌────────▼─────────┐     ┌────────▼─────────┐      │
                        │  │  ┌────────────┐   │     │  ┌────────────┐   │     │
                        │  │  │ ECS Fargate│   │     │  │ ECS Fargate│   │     │
                        │  │  └─────┬──────┘   │     │  └─────┬──────┘   │     │
                        │  └────────┼──────────┘     └────────┼──────────┘     │
                        │           │                         │               │
                        │  ┌────────▼─────────┐     ┌────────▼─────────┐      │
                        │  │ Isolated Subnet   │     │ Isolated Subnet   │     │
                        │  │     (AZ-1)        │     │     (AZ-2)        │     │
                        │  │  ┌────────────┐   │     │  ┌────────────┐   │     │
                        │  │  │  RDS (Pri) │◄──┼─────┼──│ RDS (Stdby)│   │     │
                        │  │  └────────────┘   │     │  └────────────┘   │     │
                        │  └───────────────────┘     └───────────────────┘     │
                        └─────────────────────────────────────────────────────┘
```

---

## Part 1: Terraform (Validated Locally -- Never Applied)

Write real, production-quality Terraform for the full three-tier AWS architecture described below. All validation is done locally:

```bash
terraform init -backend=false    # works without AWS credentials
terraform fmt -check             # formatting
terraform validate               # syntax and type checking
tflint                           # linting
checkov -d . / tfsec .           # security scanning
```

> **Note:** `terraform init -backend=false` initializes providers without configuring a remote backend, so no AWS credentials are needed. `terraform validate` checks HCL syntax and type correctness only -- it does not contact AWS.

### Step 1: Networking Foundation

> This is the most critical step. A well-architected network is the backbone of a secure cloud deployment.

Using Terraform, create the following:

#### VPC
- A VPC with a `/16` CIDR block (e.g., `10.0.0.0/16`)

#### Subnets (across 2 Availability Zones)
| Subnet Type       | Purpose                              | Internet Access         |
|--------------------|--------------------------------------|-------------------------|
| **Public** (x2)    | ALB, NAT Gateways                   | Direct via IGW          |
| **Private** (x2)   | ECS Fargate tasks (application)      | Outbound via NAT GW    |
| **Isolated** (x2)  | RDS instances (database)             | None                    |

#### Gateways
- **Internet Gateway (IGW)**: Attached to the VPC, enabling internet access for public subnets
- **NAT Gateway(s)**: Deployed in each public subnet, enabling outbound internet access for private subnets (e.g., pulling container images)

#### Route Tables
- **Public Route Table**: Routes `0.0.0.0/0` to the Internet Gateway
- **Private Route Table(s)**: Routes `0.0.0.0/0` to the NAT Gateway
- **Isolated Route Table**: No route to `0.0.0.0/0` (completely isolated from the internet)

#### Validation Criteria
- Public subnets can reach the internet
- Private subnets can reach the internet only via NAT Gateway (outbound only)
- Isolated subnets have **no** internet access
- All route table associations are correct

---

### Step 2: Data Tier -- RDS PostgreSQL

Using Terraform, provision the database layer:

#### RDS Instance
- **Engine**: PostgreSQL
- **Deployment**: Place in the **isolated subnets** using a DB subnet group
- **High Availability**: Enable **Multi-AZ deployment** so the database has a primary and standby in different Availability Zones
- **Public Access**: Disabled (`publicly_accessible = false`)
- **Storage**: Use a reasonable instance size (e.g., `db.t3.micro` for this exercise)
- **Encryption**: Enable storage encryption

#### Security
- Create a **security group** for RDS that allows inbound PostgreSQL traffic (port `5432`) **only** from the application tier's security group
- No other inbound traffic should be allowed
- Store database credentials in **AWS Secrets Manager**

---

### Step 3: Application Tier -- ECS Fargate

Deploy the provided Next.js application using ECS Fargate.

#### Container Image
- The container image will be stored in **GHCR** (GitHub Container Registry)
- Use a variable for the image URI (e.g., `var.container_image`) so it can be set at plan time

#### ECS Cluster & Service
- Create an **ECS cluster** with Fargate launch type
- Create a **task definition** that:
  - References the container image variable
  - Retrieves database credentials from **Secrets Manager** and injects them as environment variables (`DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_PORT`)
  - Runs in the **private subnets**
- Create an **ECS service** with desired count of at least 1

#### Security
- Create a **security group** for ECS tasks:
  - Allow inbound traffic on port `3000` from the ALB security group only
  - Allow outbound traffic to the RDS security group on port `5432`
  - Allow outbound HTTPS (port `443`) for pulling images and accessing AWS services
  - Ensure DNS resolution is possible

---

### Step 4: Presentation Tier -- Application Load Balancer

#### ALB Configuration
- Deploy an **Application Load Balancer** in the **public subnets**
- Create a **target group** pointing to the ECS service on port `3000`
- Configure an **HTTPS listener** on port `443` (reference an ACM certificate data source or variable)
- (Optional) Configure an HTTP listener on port `80` that redirects to HTTPS
- Set up **health checks** against the application

#### Security
- Create a **security group** for the ALB:
  - Allow inbound HTTPS (port `443`) from `0.0.0.0/0`
  - (Optional) Allow inbound HTTP (port `80`) from `0.0.0.0/0` for redirect only
  - Allow outbound traffic to the ECS security group on port `3000`

---

### Step 5: Terraform Quality Requirements

Your Terraform code must meet these standards:

- [ ] `terraform fmt -check` passes with no changes
- [ ] `terraform validate` succeeds
- [ ] `tflint` reports no errors
- [ ] `checkov` or `tfsec` runs with no critical/high findings (document any intentional skips)
- [ ] Code is organized into **modules** (e.g., `terraform/modules/networking/`, `terraform/modules/database/`)
- [ ] All configurable values use **variables** with descriptions and sensible defaults
- [ ] Key resource identifiers are exposed as **outputs** (VPC ID, ALB DNS, RDS endpoint, etc.)
- [ ] Proper use of `locals`, `data` sources, and resource dependencies

---

## Part 2: Docker Compose (Local Proof-of-Life)

Create a `docker-compose.yml` at the repository root that proves the application works end-to-end locally.

### Requirements
- **PostgreSQL service**: Use the official `postgres` image with health checks
- **App service**: Build from `app/Dockerfile`, depends on the database being healthy
- **Networking**: Both services communicate over a shared Docker network
- **Environment variables**: Wire `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_PORT` from the Compose file into the app container
- **Verification**: After `docker compose up`, `curl localhost:3000/api/db-check` returns a successful database connection response

### Deliverable
Include a screenshot or terminal output in your README showing a successful `db-check` response.

---

## Part 3: GitHub Actions CI/CD

Skeleton workflow files are provided in `.github/workflows/`. Each job contains `# TODO` comments where you must add the implementation steps.

### PR Workflow (`.github/workflows/pr.yml`)

Runs on every pull request to `main`. Jobs:

| Job | Purpose |
|-----|---------|
| `terraform-checks` | `fmt -check`, `init -backend=false`, `validate`, `tflint`, `checkov` or `tfsec` |
| `docker-lint` | Lint `app/Dockerfile` with `hadolint` |
| `docker-build-and-scan` | Build the Docker image and scan it with `Trivy` |
| `app-security` | Run `npm audit` or `trivy fs` on the app directory |
| `secret-detection` | Scan the repo for leaked secrets with `gitleaks` |
| `docker-compose-test` | `docker compose up`, `curl` the db-check endpoint, `docker compose down` |

### Merge Workflow (`.github/workflows/merge.yml`)

Runs on every push to `main`. Includes all the PR checks **plus**:

| Job | Purpose |
|-----|---------|
| `build-and-push` | Build the Docker image and push to **GHCR** (GitHub Container Registry) tagged with the Git SHA and `latest` |

> GHCR is free for public repositories. Authentication uses the built-in `GITHUB_TOKEN`.

---

## Part 4: Security Checklist

Ensure the following security practices are addressed in your submission:

### Infrastructure-as-Code Security
- [ ] `checkov` or `tfsec` runs clean (document any intentional skips with inline comments)
- [ ] RDS is in isolated subnets with no internet access
- [ ] RDS `publicly_accessible = false`
- [ ] RDS storage encryption enabled
- [ ] Security groups follow least-privilege (only allow required ports between tiers)
- [ ] IAM roles follow least-privilege
- [ ] Database credentials stored in Secrets Manager, never hardcoded

### Container Security
- [ ] `hadolint` passes on the Dockerfile (or you document and fix findings)
- [ ] `Trivy` container scan shows no critical/high vulnerabilities (or you document findings)
- [ ] Base image is pinned to a specific version

### CI/CD Security
- [ ] `gitleaks` finds no secrets in the repository
- [ ] GHCR authentication uses `GITHUB_TOKEN` (no long-lived credentials)
- [ ] Workflows use pinned action versions (e.g., `actions/checkout@v4`)

---

## Evaluation Rubric

Your submission will be evaluated on the following criteria:

| Area | Weight | What We Look For |
|------|--------|------------------|
| **Terraform Quality** | 25% | Correct resource definitions, modular structure, variables/outputs, clean `validate`/`tflint` |
| **Security Posture** | 25% | IaC scanner results, network isolation, least-privilege SGs, secrets handling, container scanning |
| **CI/CD Pipelines** | 20% | All jobs implemented and passing, correct triggers, proper tool configuration |
| **Local Proof-of-Life** | 15% | Working `docker-compose.yml`, successful `db-check`, evidence in README |
| **Documentation** | 15% | Architecture decisions, security considerations, clear README, trade-offs explained |

---

## Bonus Points (Optional)

If time allows, consider:
- **Improve the Dockerfile**: Add a multi-stage build and run as a non-root user (hadolint and Trivy will flag the current Dockerfile)
- **Infracost**: Add cost estimation to the CI pipeline
- **Pre-commit hooks**: Set up `pre-commit` with terraform-fmt, tflint, and gitleaks
- **Reusable workflows**: Extract shared CI steps into reusable GitHub Actions workflows
- **CODEOWNERS**: Add a `CODEOWNERS` file for review automation

---

## Out of Scope

To help you focus on the core requirements, the following are explicitly out of scope:
- Running `terraform apply` or provisioning real AWS resources
- Kubernetes or container orchestration beyond ECS definitions
- Custom domain names or DNS configuration
- Monitoring, alerting, or observability stacks
- Application code changes (the app is provided and ready to use)

---

## Submission Instructions

1. Ensure your repository is **public** (required for free GitHub Actions and GHCR)
2. All GitHub Actions workflows must show **green checks** on your main branch
3. Update your `README.md` with:
   - Architecture decisions and trade-offs
   - Security considerations and how you addressed them
   - Screenshot or output of successful `docker compose up` and `db-check`
   - Any scanner findings you intentionally skipped (with justification)
4. Verify your repository follows the [expected project structure](#expected-project-structure)
5. **Submit the link to your GitHub repository to your BLEN recruiting contact**
