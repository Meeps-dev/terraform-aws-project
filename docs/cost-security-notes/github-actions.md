# Week 11: Cost and Security Notes

## Cost Awareness

* Used small development resources such as `t3.micro` EC2 and `db.t3.micro` RDS where possible.
* Kept RDS Single-AZ and disabled Performance Insights for this cost-conscious lab.
* Used the NAT Gateway only when private EC2 required outbound access for packages and AWS APIs.
* Recognized the main Week 11 cost drivers as:

  * NAT Gateway hourly and data-processing charges
  * Application Load Balancer hourly charges
  * RDS instance, storage, and backup charges
  * EC2 instance and EBS storage
  * Secrets Manager secret storage
  * S3 object versions and deployment artifacts
  * CloudWatch and Systems Manager logs
* Named deployment artifacts using the commit SHA to prevent unnecessary duplicate or ambiguous releases.
* Set GitHub Actions artifact retention to seven days.
* Added an S3 lifecycle policy for old application releases and noncurrent object versions.
* Deleted obsolete application artifacts before destroying versioned S3 buckets.
* Used a protected Terraform destroy workflow after collecting screenshots and deployment evidence.
* Successfully removed the development infrastructure, including EC2, ALB, target groups, RDS, networking resources, and application storage.
* The protected teardown completed with:

```text
Apply complete! Resources: 0 added, 0 changed, 45 destroyed.
```

* Retained the Terraform remote-state bucket because it will be reused in later weeks.
* Retained the GitHub OIDC provider and pipeline IAM roles for future Docker, ECS, EKS, and deployment work.
* Reviewed AWS Cost Explorer and AWS Budgets after teardown to check for remaining charges.
* Used resource tags including:

```text
project=meeps
week=week-11
environment=dev
managed-by=terraform
```

## Security Decisions

* Used GitHub OIDC and AWS STS temporary credentials instead of permanent AWS access keys.
* Stored no `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` in GitHub.
* Created separate IAM roles for:

  * Terraform plan
  * Protected Terraform apply
  * Application deployment
* Restricted the Terraform plan role to the correct repository, approved branches, and pull requests.
* Restricted apply and destroy access to the protected `dev` and `dev-destroy` GitHub Environments.
* Restricted the application deployment role to the `users-posts-api` repository and the protected `dev` Environment.
* Did not attach `AdministratorAccess`, `PowerUserAccess`, or broad AWS service policies.
* Added individual permissions only when an exact `AccessDenied` error showed they were required.
* Granted `id-token: write` only to jobs that authenticated to AWS.
* Kept ordinary linting, testing, migration, and validation jobs at:

```yaml
permissions:
  contents: read
```

* Required manual approval before Terraform apply, Terraform destroy, and EC2 application deployment.
* Prevented pull requests from running `terraform apply` or `terraform destroy`.
* Used a shared concurrency group to prevent apply and destroy workflows from modifying the same state simultaneously.
* Checked out the exact approved commit SHA before infrastructure or application deployment.
* Kept the EC2 backend in a private subnet with no public IP address.
* Exposed the backend only through the Application Load Balancer.
* Allowed application traffic from the ALB Security Group to the EC2 Security Group only.
* Allowed database traffic from the application Security Group to the RDS Security Group only.
* Kept RDS private with public access disabled.
* Stored the RDS master password in AWS Secrets Manager using the RDS-managed secret.
* Allowed the EC2 instance role—not GitHub—to retrieve the database secret.
* Kept database passwords, `DATABASE_URL`, JWT secrets, and application secrets out of GitHub.
* Ensured `.env` was ignored and not committed.
* Removed the hardcoded fallback database password from the application configuration.
* Used private S3 buckets with:

  * Public access blocked
  * Server-side encryption
  * Versioning enabled
  * Lifecycle cleanup
* Stored deployment artifacts under immutable paths:

```text
releases/users-posts-api/<commit-sha>/users-posts-api.zip
```

* Generated and verified SHA-256 checksums before deployment.
* Kept Terraform state in a private, encrypted, and versioned S3 bucket.
* Used native S3 `.tflock` state locking instead of disabling locking or adding DynamoDB.
* Did not publish Terraform binary plan files as public workflow artifacts.
* Used CloudTrail to verify GitHub OIDC role assumptions and AWS activity.
* Preserved role session names containing GitHub workflow run identifiers for audit tracing.

## Security Failures Corrected

* Corrected GitHub OIDC subject mismatches without widening repository trust.
* Added missing Linux provider checksums instead of allowing CI to rewrite the Terraform lock file.
* Added exact S3 read permissions instead of attaching full S3 access.
* Corrected missing Terraform apply permissions individually.
* Replaced the invalid S3 action:

```text
s3:PutBucketEncryption
```

with:

```text
s3:PutEncryptionConfiguration
```

* Added `environment:dev-destroy` to the live apply-role trust policy before using the destroy workflow.
* Corrected Alembic handling of percent-encoded database passwords.
* Corrected unsafe database migrations and added an idempotent repair migration.
* Improved EC2 release permissions and rollback handling.

## Production Improvements

* Pin every GitHub Action to a full immutable commit SHA instead of only a version tag.
* Use Dependabot to monitor GitHub Actions and Python dependency updates.
* Replace temporary NAT-based outbound access with suitable VPC endpoints where practical.
* Add ACM and an HTTPS listener to the ALB.
* Redirect HTTP traffic to HTTPS.
* Use Multi-AZ RDS for production workloads.
* Enable deletion protection and retain a final RDS snapshot in production.
* Use a customer-managed KMS key where stronger key-control requirements exist.
* Add CloudWatch alarms for ALB errors, unhealthy targets, EC2 health, and RDS capacity.
* Send deployment and systemd logs to CloudWatch Logs.
* Add automated secret rotation where supported.
* Apply stricter branch protection and required-reviewer rules for production.
* Use separate AWS accounts or environments for development, staging, and production.

## Final Status

Week 11 demonstrated a cost-aware and security-focused CI/CD design using GitHub Actions, AWS OIDC, least-privilege IAM, protected Terraform workflows, immutable artifacts, private EC2 and RDS resources, Secrets Manager, S3 state locking, deployment approval, CloudTrail auditing, and a verified cost-conscious teardown. The roadmap requires weekly cost/security documentation and removal of temporary NAT Gateway, RDS, ALB, and other lab resources after evidence is collected. 
