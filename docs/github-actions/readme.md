* Week 11: Secure CI/CD with GitHub Actions, AWS OIDC, Terraform, S3, SSM, EC2 and RDS



* Project Overview

* Week 11 focused on building a production-style CI/CD platform for a FastAPI backend and its AWS infrastructure.

* The project automated application testing, migration validation, security auditing, artifact packaging, Terraform planning, protected infrastructure changes and deployment to a private EC2 instance. GitHub Actions authenticated to AWS through OpenID Connect rather than permanent AWS access keys.

* The completed platform used:

* GitHub Actions for CI and CD

* AWS OIDC and STS temporary credentials

* Terraform modules and remote state

* Native S3 state locking

* GitHub Environments and manual approvals

* A public Application Load Balancer

* A private EC2 FastAPI backend

* A private PostgreSQL RDS database

* A private, encrypted and versioned S3 deployment bucket

* AWS Systems Manager Run Command

* AWS Secrets Manager

* Alembic database migrations

* systemd application management

* Immutable release artifacts and rollback controls

* Project Objectives

* The Week 11 project was designed to prove that I could:

* Build a multi-job application CI pipeline.

* Run linting, tests, coverage, migration and dependency-security checks.

* Produce a reproducible deployment artifact.

* Authenticate GitHub Actions to AWS without long-lived credentials.

* Run Terraform formatting, validation and speculative plans in CI.

* Protect Terraform apply and destroy operations behind approval gates.

* Deploy a FastAPI application to a private EC2 instance through S3 and SSM.

* Retrieve database credentials securely at runtime.

* Verify deployments through local, ALB and database-backed smoke tests.

* Engineer controlled failures, debug them and document the corrections.

* Tear down temporary infrastructure to avoid billing surprises.

* Architecture

                                  GitHub
                                    |
                 +------------------+------------------+
                 |                                     |
         users-posts-api                    terraform-aws-project
                 |                                     |
          Application CI                         Terraform CI
                 |                                     |
      lint / test / migration                   fmt / validate
      security / package                             |
                 |                              AWS OIDC plan role
                 |                                     |
     SHA-addressed GitHub artifact             S3 remote state
                 |                             + native .tflock
                 |
      Successful push CI on main
                 |
          GitHub Environment
                 dev
                 |
          Manual approval
                 |
      AWS OIDC deployment role
                 |
   Private versioned S3 deployment bucket
                 |
           SSM Run Command
                 |
                 v
   Public ALB :80 ---> Private EC2 :8080 ---> Private RDS :5432
                          |
                          +-- systemd
                          +-- FastAPI
                          +-- Alembic
                          +-- Secrets Manager
                          +-- immutable releases

* Application Traffic Path

Client
  |
  v
Application Load Balancer
  |
  | HTTP to target port 8080
  v
Private EC2 instance
  |
  | PostgreSQL traffic on port 5432
  v
Private RDS PostgreSQL

* Infrastructure Automation Path

Pull request or feature branch
  |
  v
Terraform fmt and validate
  |
  v
GitHub OIDC
  |
  v
github-plan-role
  |
  v
Speculative Terraform plan
  |
  v
Manual workflow dispatch from main
  |
  v
Pre-approval plan
  |
  v
GitHub Environment approval
  |
  v
github-apply-role
  |
  v
Exact saved Terraform plan and apply

* Repositories

* The project was separated into two repositories.

* Application Repository

* Meeps-dev/users-posts-api

* Contains:

* FastAPI application code

* SQLAlchemy models

* Pydantic schemas

* Alembic migrations

* pytest tests

* CI workflow

* EC2 deployment workflow

* packaging, health-check, deployment and rollback scripts

* systemd service definition

* Week 11 documentation

* Infrastructure Repository

* Meeps-dev/terraform-aws-project

* Contains:

* Terraform environment configuration

* VPC module

* Security Group module

* ALB module

* EC2 compute module

* RDS module

* S3 module

* GitHub OIDC bootstrap module

* Terraform CI workflow

* protected apply workflow

* protected destroy workflow

* remote-state and locking configuration

* Technology Stack

* Application

* Python 3.12

* FastAPI

* SQLAlchemy

* PostgreSQL

* Alembic

* Pydantic

* Uvicorn

* pytest

* pytest-cov

* Ruff

* pip-audit

* AWS

* IAM

* AWS STS

* S3

* EC2

* Application Load Balancer

* Target Groups

* RDS PostgreSQL

* Secrets Manager

* Systems Manager

* CloudTrail

* VPC

* Security Groups

* NAT Gateway during the deployment lab

* Automation and Infrastructure

* GitHub Actions

* GitHub Environments

* GitHub OIDC

* Terraform

* Remote S3 state

* Native S3 state locking

* Bash

* systemd

* Application CI

The application workflow is stored at:

* .github/workflows/ci.yml

It runs on:

* Pull requests targeting main

* Pushes to main

* Pushes to feature/**

* Manual workflow_dispatch

* CI Job Graph

lint ------------------\
test -------------------\
migration-check ---------> package
security-check ----------/

* Lint Job

* The lint job runs:

ruff check .
ruff format --check .

* This blocks packaging when code quality or formatting checks fail.

* Test and Coverage Job

* The test job:

* Starts an isolated PostgreSQL 15 service container.

* Applies Alembic migrations.

* Runs pytest against the temporary database.

* Generates terminal, XML and JUnit reports.

* Enforces the measured coverage baseline.

python -m pytest -q \
  --cov=app \
  --cov-report=term-missing \
  --cov-report=xml:reports/coverage.xml \
  --junitxml=reports/pytest.xml \
  --cov-fail-under=98

* Final verification reached:

* 7 tests passed
* 98.21% coverage

* Migration Check Job

The migration job validates the complete schema history on a separate blank PostgreSQL database:

alembic heads
alembic upgrade head
alembic current
alembic check

* This catches:

* Invalid migration syntax

* Broken revision dependencies

* Missing schema changes

* Model and migration drift

* Unsafe database changes

* Security Check Job

The security job runs:

pip-audit -r requirements.txt

* Vulnerable packages were upgraded to compatible fixed versions rather than ignoring the audit.

* Package Job

The package job starts only after all four quality gates pass.

* It produces:

users-posts-api-<commit-sha>.zip
users-posts-api-<commit-sha>.zip.sha256

* The package includes:

* app/

* alembic/

* alembic.ini

* requirements.txt

* deploy/

* deployment and rollback scripts

* It excludes:

* .git

* .env

* virtual environments

* caches

* local database files

* test reports

* secrets

* GitHub Actions retains the CI artifact for seven days.

* Terraform CI

The Terraform CI workflow is stored at:

* .github/workflows/terraform-ci.yml

It runs when:

* A pull request into main modifies Terraform code.

* A feature/** branch modifies Terraform code.

* The workflow is dispatched manually.

* Path filters prevent unrelated documentation or application changes from starting Terraform CI.

* Static Checks

The first job runs without AWS credentials:

terraform fmt -check -recursive infrastructure
terraform init -backend=false -input=false -lockfile=readonly
terraform validate -no-color

* Both the development root and the GitHub OIDC bootstrap root are validated.

* OIDC Plan Job

The plan job receives:

permissions:
  contents: read
  id-token: write

* It:

* Assumes github-plan-role through OIDC.

* Verifies the AWS caller identity.

* Confirms the state bucket and state key.

* Confirms native S3 locking is enabled.

* Initializes the remote S3 backend.

* Runs a speculative Terraform plan.

* Handles Terraform detailed exit codes.

* Writes only a safe summary to the workflow summary.

* Does not upload the binary plan file.

* Terraform detailed exit codes are handled as:

* 0 = successful plan with no changes
* 1 = Terraform error
* 2 = successful plan with proposed changes

* Remote State and Locking

Terraform state is stored in a private S3 bucket.

* The development state key is:

terraform-bootstrap/dev-backend/terraform.tfstate

* Native S3 state locking is enabled:

use_lockfile = true

* The corresponding lock object is:

terraform-bootstrap/dev-backend/terraform.tfstate.tflock

* The state bucket uses:

* Public-access blocking

* Server-side encryption

* Versioning

* Restricted IAM access

* The plan role can read state and manage only the lock object. The apply role can read and update the state and manage the lock object.

* DynamoDB locking was not added because this project uses native S3 lock files.

* AWS OIDC and Least-Privilege IAM

* GitHub Actions authenticates to AWS through:

token.actions.githubusercontent.com

* AWS STS exchanges the GitHub OIDC token for temporary credentials. No permanent AWS access key is required by the workflows.

* IAM Roles

* Three separate roles were created:

github-plan-role
github-apply-role
github-app-deploy-role

* Plan Role

* Used by Terraform CI.

* It can:

Read Terraform remote state.

Create and delete the native S3 lock object.

Inspect Terraform-managed AWS resources.

Run read-only discovery operations required by the AWS provider.

* It cannot apply or destroy infrastructure.

* Apply Role

* Used by the protected Terraform apply and destroy workflows.

* It can:

Read and update Terraform state.

Manage the native state lock.

Perform the service-specific mutations required by the development stack.

Pass only approved EC2 roles to EC2.

* It is not attached to AdministratorAccess.

* Application Deployment Role

* Used by the FastAPI CD workflow.

* It can:

Upload artifacts only to the approved release prefix.

Inspect the target EC2 instance.

Send the approved SSM Run Command document.

Read SSM command status and output.

* It cannot create VPCs, databases or unrelated infrastructure.

* Trust Restrictions

* Trust policies restrict access by:

OIDC audience

GitHub organization and repository

Branch or pull-request subject

* Protected GitHub Environment

* The Terraform apply role accepts:

environment:dev
environment:dev-destroy

* The application deployment role is restricted to the application repository's dev Environment.

* Role Session Names

* Workflow run identifiers are included in AWS role-session names:

gha-plan-<run-id>-<attempt>
gha-apply-<run-id>-<attempt>
gha-destroy-<run-id>-<attempt>
gha-deploy-<run-id>-<attempt>

* This makes CloudTrail activity easier to trace back to a GitHub Actions run.

* Protected Terraform Apply

* The apply workflow is stored at:

.github/workflows/terraform-apply.yml

* It is manual only:

on:
  workflow_dispatch:

* The operator must:

* Select main.

* Enter APPLY-DEV.

* Provide a deployment reason.

* Review the pre-approval plan.

* Approve the protected dev Environment.

* Apply Sequence

Validate request
   |
   v
Checkout exact commit
   |
   v
Assume github-plan-role
   |
   v
Generate safe pre-approval plan
   |
   v
Wait for dev Environment approval
   |
   v
Assume github-apply-role
   |
   v
Generate a fresh exact saved plan
   |
   v
Block unexpected delete actions
   |
   v
Apply the exact plan
   |
   v
Capture non-sensitive outputs

* The normal apply workflow stops if the plan includes delete or replacement actions.

* Protected Terraform Destroy

* The destroy workflow is stored at:

.github/workflows/terraform-destroy.yml

* It:

* Runs only through workflow_dispatch.

* Requires the exact DESTROY-DEV confirmation.

* Requires a teardown reason.

* Uses the protected dev-destroy Environment.

* Generates an exact destroy plan.

* Applies only the saved destroy plan.

* Removes the temporary plan afterward.

* Apply and destroy use the same concurrency group:

terraform-dev

* This prevents them from changing the same remote state at the same time.

* FastAPI Deployment Through S3 and SSM

* The deployment workflow is stored at:

.github/workflows/deploy-dev.yml

* It runs after the application CI workflow completes successfully for a push to main.

* The deployment job also requires approval from the application repository's protected dev Environment.

* Deployment Sequence

* Validate required deployment variables.

* Check out the exact successful commit.

* Download the exact CI artifact from the originating workflow run.

* Verify the SHA-256 checksum.

* Assume github-app-deploy-role through OIDC.

* Upload the ZIP and checksum to the private S3 bucket.

* Confirm that the private EC2 instance is online in Systems Manager.

* Send the deployment command through SSM.

* Wait for the command to finish.

* Display SSM output and errors.

* Verify the local FastAPI health endpoint.

* Verify the ALB health endpoint.

* Create and list a user.

* Create and list a post.

* Record the deployment result in the workflow summary.

* Immutable S3 Release Path

releases/users-posts-api/<commit-sha>/users-posts-api.zip

* Each release is identified by the exact Git commit that created it. The pipeline does not rely on a mutable latest.zip object.

* EC2 Release Structure

/opt/users-posts-api/
├── releases/
│   ├── <previous-commit-sha>/
│   └── <new-commit-sha>/
│       ├── .venv/
│       ├── app/
│       ├── alembic/
│       ├── deploy/
│       ├── scripts/
│       └── .env
└── current -> releases/<active-commit-sha>

* Runtime Operations

* The remote deployment script:

* Validates required variables and ports.

* Uses flock to prevent overlapping host-level deployments.

* Creates an immutable release directory.

* Retrieves the RDS-managed secret.

* Builds a URL-encoded PostgreSQL connection string.

* Creates a release-specific Python virtual environment.

* Installs Python dependencies.

* Runs alembic upgrade head.

* Installs the systemd service definition.

* Updates the current symlink.

* Restarts the FastAPI service.

* Runs local health and database-backed checks.

* Application Endpoints

GET  /health
POST /users/
GET  /users/
POST /posts/users/{user_id}
GET  /posts/users/{user_id}

* The ALB health check uses:

/health

* The FastAPI service listens on:

8080

* Secrets Handling

* The live RDS password is never passed through GitHub Actions.

* The security flow is:

RDS-managed Secrets Manager secret
              |
              v
       EC2 instance role
              |
              v
     Runtime DATABASE_URL
              |
              v
   Release-specific .env file

* Security controls include:

* No permanent AWS access keys in GitHub workflows.

* OIDC and temporary STS credentials.

* RDS master credentials stored in Secrets Manager.

* EC2 retrieves the database secret at deployment time.

* The GitHub deployment role cannot read the database password.

* .env is excluded from source control and deployment artifacts.

* The generated EC2 .env file uses restrictive file permissions.

* Sensitive Terraform outputs are marked sensitive.

* Terraform state and plans are treated as sensitive data.

* Secrets are not printed deliberately in workflow logs.

* Repository hardening note: the current application repository still contains a local-only fallback PostgreSQL URL in app/config.py and .env.example. It is not the live RDS credential, but it should be replaced with a mandatory DATABASE_URL placeholder before treating the repository as production-ready.

* Rollback Strategy

* Deployment uses immutable release directories and a current symlink.

* Before changing the active release, the deployment script records:

* The previous release path

* The previous systemd service unit

* Whether the placeholder service was active

* Whether the active symlink was changed

* If deployment or health validation fails, rollback:

* Restores the previous current symlink.

* Restores the previous systemd unit when necessary.

* Restarts the previous application.

* Runs the health check again.

* Restores the placeholder service during a failed first deployment.

* Prints systemctl and journalctl diagnostics.

* Marks the GitHub Actions deployment as failed.

* Database migrations use forward fixes rather than automatic production downgrades.

* Failure Engineering and Troubleshooting

* Controlled failures were created throughout the week to verify that the pipeline failed safely.

* Application CI Failures

* Invalid needs: checkout job dependency

* PostgreSQL unavailable in CI

* Missing httpx

* Alembic database authentication failure

* Missing test tables

* Ruff formatting failure

* Deliberate pytest assertion failure

* Vulnerable Python dependencies

* OIDC and Terraform Failures

* Incorrect OIDC subject

* Incorrectly formatted Terraform variable values

* Missing S3 backend bucket

* Renamed backend state keys

* Missing Linux provider checksum

* Missing s3:GetAccelerateConfiguration

* Protected apply AccessDenied

* Incorrect S3 encryption IAM action

* dev-destroy trust-policy mismatch

* Deployment Failures

* CD skipped because the source CI run used workflow_dispatch

* Alembic % interpolation failure with an encoded RDS password

* Unsafe migration that removed required tables

* Missing-table repair requirement

* EC2 virtual-environment permissions

* First-deployment rollback behavior

* The detailed failure record is stored at:

docs/CI.CD/week-11-failure-engineering.md

* Security Decisions

* GitHub OIDC replaced stored AWS access keys.

* IAM trust policies are restricted to the correct repository and execution context.

* Plan, apply and application deployment permissions are separated.

* id-token: write is granted only to AWS-facing jobs.

* Ordinary CI jobs use read-only repository permissions.

* Pull requests cannot run Terraform apply or destroy.

* Infrastructure changes require manual dispatch and Environment approval.

* Application deployment requires successful CI and Environment approval.

* Apply and destroy are serialized through concurrency controls.

* Exact commit SHAs are checked before state-changing operations.

* Terraform workflows pin third-party Actions to immutable commit SHAs.

* The application workflows currently use trusted version tags; full SHA pinning remains a production hardening action.

* EC2 has no public IP address.

* RDS is not publicly accessible.

* ALB-to-EC2 and EC2-to-RDS access use Security Group references.

* Deployment artifacts are private, encrypted, versioned and checksum-verified.

* CloudTrail records OIDC role assumptions and AWS API activity.

* No AdministratorAccess policy was attached to the pipeline roles.

* Cost Controls and Teardown

* The development environment used cost-conscious settings:

t3.micro EC2

db.t3.micro RDS

Single-AZ RDS

Minimal EBS storage

Performance Insights disabled

Temporary NAT Gateway only while testing private EC2 deployment

Seven-day GitHub artifact retention

S3 lifecycle cleanup for deployment releases

* The S3 release lifecycle:

* Expires current release objects after 14 days.

* Removes older noncurrent versions after seven days.

* Retains two newer noncurrent versions.

* Aborts incomplete multipart uploads after one day.

* After screenshots and verification were completed, the protected destroy workflow removed the temporary development environment.

* Final teardown evidence:

* Apply complete! Resources: 0 added, 0 changed, 45 destroyed.

* Removed resources included:

* EC2

* ALB

* Target Group

* RDS

* NAT Gateway

* VPC and subnets

* route tables

* application Security Groups

* temporary application S3 resources

* Retained for later weeks:

* Terraform remote-state bucket

* GitHub OIDC provider

* GitHub plan role

* GitHub apply role

* GitHub application deployment role

* pipeline documentation

* AWS Cost Explorer and AWS Budgets were reviewed after teardown.

* Running the Project

* Run Application Checks Locally

python -m pip install -r requirements-dev.txt

ruff check .
ruff format --check .

python -m pytest -q \
  --cov=app \
  --cov-report=term-missing

* Run Terraform Validation Locally

terraform fmt -check -recursive infrastructure

terraform \
  -chdir=infrastructure/terraform/envs/dev \
  init \
  -backend=false \
  -input=false \
  -lockfile=readonly

terraform \
  -chdir=infrastructure/terraform/envs/dev \
  validate

* Run Protected Terraform Apply

* In GitHub:

Actions
→ Protected Terraform Apply
→ Run workflow
→ Select main
→ Enter APPLY-DEV
→ Provide the change reason
→ Review the plan
→ Approve the dev Environment

* Deploy the Application

* Merge an approved application change into main.

* Wait for all CI quality gates to pass.

* Confirm that the commit-specific artifact was created.

* Open the deployment workflow.

* Approve the protected dev deployment.

* Verify S3, SSM, systemd, ALB and API smoke-test output.

* Run Protected Teardown

* In GitHub:

Actions
→ DANGER - Protected Terraform Destroy
→ Run workflow
→ Select main
→ Enter DESTROY-DEV
→ Provide the teardown reason
→ Approve the dev-destroy Environment

* Evidence

* The final project evidence should include:

* Application CI job graph

* Successful lint and format checks

* pytest and coverage result

* successful Alembic migration check

* successful pip-audit

* generated SHA-addressed ZIP artifact

* Terraform CI workflow graph

* successful Terraform plan

* S3 remote-state and .tflock evidence

* GitHub OIDC provider

* IAM trust and permissions policies

* assumed-role caller identities

* GitHub Environment waiting for approval

* approved Terraform apply

* successful EC2 deployment through SSM

* S3 deployment artifact and version ID

* active systemd service

* healthy ALB target

* /health, users and posts responses

* failed deployment and rollback evidence

* protected teardown result

* Cost Explorer and Budget review

* Production Improvements

* This project is a development lab. A production implementation should add:

* Networking and Edge Security

* Route 53 DNS

* ACM TLS certificate

* HTTPS ALB listener

* HTTP-to-HTTPS redirect

* AWS WAF

* Restricted administrative access

* VPC endpoints for S3, SSM and Secrets Manager

* Reduced reliance on NAT Gateway

* Compute and Availability

* Auto Scaling Group across multiple Availability Zones

* Multiple EC2 application instances

* Immutable machine images or container deployment

* Blue/green or canary deployment

* ECS Fargate or EKS for workload orchestration

* Automated instance replacement

* Database

* Multi-AZ RDS

* Deletion protection

* Final snapshots

* Longer backup retention

* Tested restore procedure

* Connection pooling

* Read replicas where required

* Secret rotation

* CI/CD and Supply Chain

* Pin every application workflow Action to a full commit SHA

* Add Dependabot for GitHub Actions and Python dependencies

* Add CodeQL and secret scanning

* Add policy-as-code checks

* Add Terraform security scanning

* Sign deployment artifacts

* Generate provenance and an SBOM

* Use separate AWS accounts for development, staging and production

* Observability

* Send systemd and application logs to CloudWatch Logs

* Add ALB 5xx and unhealthy-target alarms

* Add EC2 status alarms

* Add RDS CPU, storage and connection alarms

* Create a CloudWatch dashboard

* Add deployment notifications

* Define incident runbooks and rollback alerts

* Application Hardening

* Remove the committed local database-password fallback

* Require DATABASE_URL in every runtime

* Add authentication and authorization

* Add input constraints and duplicate handling

* Add structured logging

* Add rate limiting

* Add readiness and liveness endpoints

* Add migration compatibility checks between releases

* Key Lessons

* CI and CD should be separated but connected through immutable artifacts.

* Infrastructure planning should be automatic, while apply and destroy should be protected.

* OIDC removes the need for permanent AWS credentials in GitHub.

* IAM permissions should be corrected one denied action at a time.

* Terraform state and plan files must be protected as sensitive assets.

* A successful transport does not guarantee a successful deployment.

* Database migrations require independent testing and safe forward-repair strategies.

* Release identity should be tied to the Git commit SHA.

* Rollback must handle both upgrade deployments and first deployments.

* Cost-aware teardown is part of cloud engineering, not an optional cleanup step.

* Final Status

* Week 11 successfully delivered:

* A multi-job application CI pipeline

* A Terraform plan pipeline

* GitHub-to-AWS OIDC federation

* Separate least-privilege IAM roles

* protected Terraform apply and destroy workflows

* immutable application artifacts

* private EC2 deployment through S3 and SSM

* private RDS integration

* Secrets Manager credential retrieval

* systemd release management

* deployment smoke testing

* rollback engineering

* failure-engineering documentation

* security and cost review

* verified infrastructure teardown

* This project provides the CI/CD and cloud-automation foundation required for Week 12 Docker, Docker Compose and Amazon ECR.