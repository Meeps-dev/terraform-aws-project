# Week 10 — Modular AWS Infrastructure with Terraform

This project rebuilds a production-inspired three-tier AWS environment with reusable Terraform modules. It was completed as Week 10 of the Meeps Cloud/Platform Engineering roadmap and demonstrates infrastructure design, remote state management, dependency wiring, import, validation, troubleshooting, and cost-aware teardown.

> Environment: `dev`  
> AWS Region: `eu-west-2`  
> Infrastructure as Code: Terraform and the AWS provider

## Project objectives

- Build repeatable AWS infrastructure from code.
- Separate networking, security, load balancing, compute, database, and storage into reusable modules.
- Store Terraform state remotely in Amazon S3.
- Use native S3 state locking instead of a DynamoDB lock table.
- Keep the EC2 backend and PostgreSQL database private.
- Apply security-group-to-security-group access rules.
- Protect database credentials with AWS Secrets Manager.
- Validate every change with `fmt`, `validate`, and a reviewed plan.
- Document cost controls, failures, recovery, and teardown.

## Architecture

```text
Internet
   |
   v
Application Load Balancer
2 public subnets across 2 Availability Zones
   |
   | TCP 8080
   v
EC2 backend
private application subnet
   |
   | PostgreSQL 5432
   v
Amazon RDS PostgreSQL
private database subnets

Application storage: private, versioned Amazon S3 bucket
Terraform state: separate private, encrypted, versioned S3 backend
State locking: native S3 lock file
```

The Application Load Balancer is the only application entry point. The backend instance has no direct public application ingress, and the RDS database accepts PostgreSQL traffic only from the application security group.

## Network design

### VPC

- CIDR block: `10.0.0.0/16`
- Purpose: Provides an isolated network for the project.

### Public subnets

- CIDR blocks: `10.0.1.0/24` and `10.0.2.0/24`
- Purpose: Host the internet-facing Application Load Balancer.

### Private application subnets

- CIDR blocks: `10.0.11.0/24` and `10.0.12.0/24`
- Purpose: Host private backend compute resources.

### Private database subnets

- CIDR blocks: `10.0.21.0/24` and `10.0.22.0/24`
- Purpose: Form the private RDS database subnet group.

The six subnets are distributed across two Availability Zones.

An Internet Gateway and public route table provide internet connectivity to the public ALB subnets.

The private application and database subnets use separate route tables.

NAT Gateway creation is optional and remains disabled when private-subnet outbound internet access is not required.

## Terraform modules

### VPC module

The `vpc` module manages:

- VPC
- Internet Gateway
- Six subnets
- Public route table
- Private application route table
- Private database route table
- Route-table associations
- Optional NAT Gateway

### Security module

The `security` module manages:

- ALB security group
- Application security group
- RDS security group
- Explicit ingress and egress paths between tiers

### ALB module

The `alb` module manages:

- Internet-facing Application Load Balancer
- HTTP listener
- Backend target group
- `/health` health checks

### Compute module

The `compute` module manages:

- Amazon Linux 2023 EC2 backend
- IAM role
- IAM instance profile
- Systems Manager policy attachment
- Target-group registration

### RDS module

The `rds` module manages:

- Private PostgreSQL database
- Database subnet group
- RDS-managed master credentials in AWS Secrets Manager

### Application S3 module

The `app-s3` module manages:

- Private application S3 bucket
- Bucket versioning
- Server-side encryption
- Ownership controls
- S3 Block Public Access

## Request and security-group flow

### Client to Application Load Balancer

- Source: Approved client CIDR blocks
- Destination: ALB security group
- Ports: `80` and `443`
- Purpose: Public application entry

### Application Load Balancer to EC2

- Source: ALB security group
- Destination: Application security group
- Port: `8080`
- Purpose: Backend application traffic

### EC2 to RDS

- Source: Application security group
- Destination: RDS security group
- Port: `5432`
- Purpose: PostgreSQL database traffic

The current development configuration permits public client traffic to the ALB.

A production deployment should terminate HTTPS using AWS Certificate Manager and restrict ALB ingress further where global public access is unnecessary.

## Remote state and locking

The development environment uses an Amazon S3 backend.

The backend configuration includes:

- State key: `week-10/dev/terraform.tfstate`
- Bucket versioning
- Server-side encryption
- S3 Block Public Access
- Native S3 lock file using `use_lockfile = true`
- No DynamoDB lock table

The backend bucket is provisioned separately from the main environment.

It must remain available until the application environment has been destroyed and the empty Terraform state has been verified.

## Repository structure

```text
.
├── docs
│   ├── architecture
│   ├── cost-security-notes
│   ├── screenshots
│   └── troubleshooting
├── infra
│   └── terraform
│       ├── envs
│       │   └── dev
│       └── modules
│           ├── alb
│           ├── app-s3
│           ├── compute
│           ├── rds
│           ├── security
│           └── vpc
├── .gitignore
└── README.md
```

## Development configuration

- Project name: `meeps`
- Environment: `dev`
- AWS Region: `eu-west-2`
- Backend application port: `8080`
- EC2 instance type: `t3.micro`
- EC2 root volume: 8 GiB `gp3`
- Detailed EC2 monitoring: Disabled
- Database engine: PostgreSQL 16
- RDS instance type: `db.t3.micro`
- RDS allocated storage: 20 GiB
- RDS deployment: Single-AZ
- Database port: `5432`
- RDS backup retention: 1 day

These values are intentionally cost-conscious lab settings and are not production sizing recommendations.

## Prerequisites

- An AWS account
- Permission to create the documented AWS resources
- AWS CLI version 2
- Terraform version compatible with `versions.tf`
- Valid AWS credentials for `eu-west-2`
- The separately bootstrapped S3 backend

Confirm the active identity before planning:

```bash
aws sts get-caller-identity \
  --region eu-west-2 \
  --no-cli-pager
```

## Deployment

### 1. Configure the environment

```bash
cd infra/terraform/envs/dev
cp terraform.tfvars.example terraform.tfvars
```

Review `terraform.tfvars` before continuing.

Do not add AWS credentials or database passwords to this file.

### 2. Initialize and validate

```bash
terraform init

cd ../..
terraform fmt -recursive

cd envs/dev
terraform validate
```

### 3. Create and review a saved plan

```bash
umask 077

terraform plan \
  -lock-timeout=5m \
  -out=/tmp/meeps-week10.tfplan

terraform show -no-color /tmp/meeps-week10.tfplan
```

Review every addition, update, replacement, and deletion before applying.

### 4. Apply the reviewed plan

```bash
terraform apply \
  -lock-timeout=5m \
  /tmp/meeps-week10.tfplan
```

## Useful operational commands

```bash
terraform state list
terraform output
terraform providers
terraform show
```

The root module exposes operational values for:

- ALB DNS name
- ALB target-group ARN
- EC2 instance ID
- EC2 private IP address
- RDS endpoint
- RDS port
- RDS identifier
- RDS secret ARN
- Application S3 bucket name
- Application S3 bucket ARN

Configuration-only outputs were removed during the final cleanup because they repeated values already defined in the Terraform configuration.

## Validation workflow

```bash
cd infra/terraform
terraform fmt -check -recursive

cd envs/dev
terraform validate

terraform plan \
  -lock-timeout=5m \
  -detailed-exitcode
```

Detailed plan exit codes:

- Exit code `0`: The plan succeeded and no changes were detected.
- Exit code `1`: The planning operation failed.
- Exit code `2`: The plan succeeded and contains proposed changes.

An exit code of `2` must be reviewed. It is not automatic approval to apply the plan.

## Week 10 learning outcomes

- Used Terraform providers, resources, variables, locals, data sources, outputs, and object-typed configuration.
- Built reusable child modules.
- Connected child modules through explicit inputs and outputs.
- Queried the latest approved Amazon Linux 2023 AMI using a data source.
- Migrated local Terraform state to an S3 backend.
- Implemented native S3 state locking.
- Verified locking by attempting concurrent Terraform operations.
- Imported an existing S3 resource into Terraform state.
- Reached a no-change plan after completing the import.
- Used saved plans as safety and code-review gates.
- Detected and fixed undeclared module variables.
- Fixed a module-scoped Availability Zones data-source error.
- Simplified the root environment without changing live AWS resources.
- Compared Terraform modules and state workflows with CloudFormation nested stacks and stack state.
- Practised safe teardown planning and cost verification.

## Challenges and fixes

The main challenges included:

- Child modules referencing undeclared input variables
- A module referencing an undeclared Availability Zones data source
- Safely migrating local state to the S3 backend
- Expected state-lock contention during the locking test
- Understanding Terraform plan exit codes during output-only state cleanup
- An AWS STS TLS handshake timeout during final drift verification

See [the troubleshooting notes](docs/troubleshooting/README.md) for the causes, diagnostic commands, and fixes.

## Cost and security

The project uses:

- Small development instance sizes
- Optional NAT Gateway creation
- Private EC2 and RDS workloads
- Security-group-to-security-group rules
- Protected S3 buckets
- Remote state locking
- RDS-managed credentials

The following services can still generate charges:

- Application Load Balancer
- EC2
- EBS
- RDS
- Secrets Manager
- S3 storage and object versions
- Data transfer
- NAT Gateway when enabled

See [the cost and security notes](docs/cost-security-notes/README.md) before deployment or teardown.

## Teardown

Capture the required evidence and review a saved destroy plan before deleting anything.

```bash
cd infra/terraform/envs/dev

umask 077

terraform plan \
  -destroy \
  -lock-timeout=5m \
  -out=/tmp/meeps-week10-destroy.tfplan

terraform show -no-color /tmp/meeps-week10-destroy.tfplan
```

After confirming that the plan targets only the Week 10 development environment:

```bash
terraform apply \
  -lock-timeout=5m \
  /tmp/meeps-week10-destroy.tfplan

terraform state list
```

The expected final `terraform state list` output is empty.

Handle the separately bootstrapped remote-state bucket last, after preserving the required evidence and confirming that no other environment uses it.

## Terraform and CloudFormation

Terraform was selected for Week 10 because its module and provider model provides a consistent workflow for reusable platform infrastructure.

CloudFormation and SAM remain strong choices for:

- AWS-native serverless workloads
- AWS-managed stack state
- Change sets
- Automatic rollback
- StackSets

Terraform and CloudFormation can coexist, but they should never manage the same AWS resource simultaneously.

## References

- [Terraform init](https://developer.hashicorp.com/terraform/cli/commands/init)
- [Terraform fmt](https://developer.hashicorp.com/terraform/cli/commands/fmt)
- [Terraform validate](https://developer.hashicorp.com/terraform/cli/commands/validate)
- [Terraform plan](https://developer.hashicorp.com/terraform/cli/commands/plan)
- [Terraform apply](https://developer.hashicorp.com/terraform/cli/commands/apply)
- [Terraform S3 backend and native locking](https://developer.hashicorp.com/terraform/language/backend/s3)
- [AWS RDS security groups](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.RDSSecurityGroups.html)
- [AWS RDS and Secrets Manager](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-secrets-manager.html)
- [Amazon S3 Block Public Access](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html)

## Author

**Meeps**  
Cloud / Platform / DevOps Engineering portfolio project
