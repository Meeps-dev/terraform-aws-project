# Week 10 Cost and Security Notes

These notes record the decisions used to keep the Terraform development environment secure, reviewable, and cost-conscious.

## Cost-control decisions

### NAT Gateway

- Development decision: NAT Gateway creation is optional and remains disabled unless private-subnet internet access is required.
- Cost reason: NAT Gateways have hourly charges and data-processing charges.

### EC2

- Development decision: Use a `t3.micro` instance with an 8 GiB `gp3` root volume.
- Detailed monitoring is disabled.
- Cost reason: This provides small lab capacity while reducing compute, storage, and monitoring costs.

### RDS PostgreSQL

- Development decision: Use a `db.t3.micro` instance with 20 GiB of storage.
- The database is Single-AZ.
- Backup retention is set to one day.
- Cost reason: This configuration is appropriate for a short-lived development lab.

### Application Load Balancer

- Development decision: Use one internet-facing ALB across two public subnets.
- Cost reason: This satisfies the Availability Zone requirement without deploying additional load balancers.

### Amazon S3

- Development decision: Enable bucket versioning and server-side encryption.
- Cost consideration: Old object versions continue consuming storage and should be monitored or expired.

### AWS Secrets Manager

- Development decision: Allow RDS to generate and manage the master secret.
- Security reason: This avoids storing plaintext database credentials in Terraform configuration.
- Cost consideration: Secrets Manager storage and API calls can generate charges.

### Terraform state

- Development decision: Use a separate S3 backend with native S3 lock files.
- Cost reason: This avoids needing a DynamoDB lock table while retaining remote coordination and state protection.

### Resource tags

Resources use project, week, owner, environment, and managed-by tags.

These tags support:

- Cost filtering
- Resource ownership
- Environment identification
- Cleanup
- Auditing

Small resource classes are not automatically free. Eligibility depends on the AWS account, Region, current AWS Free Tier terms, and available credits.

## Main billable resources

Pay particular attention to:

- Application Load Balancer running hours
- Application Load Balancer capacity units
- EC2 instance hours
- Attached EBS storage
- RDS instance hours
- RDS allocated storage
- RDS backup storage
- Manual RDS snapshots
- NAT Gateway running hours when enabled
- NAT Gateway processed data
- Public IPv4 addresses
- Elastic IP addresses
- Secrets Manager secret storage
- Secrets Manager API calls
- S3 object storage
- S3 requests
- Retained noncurrent S3 object versions
- CloudWatch logs
- CloudWatch metrics
- Detailed monitoring
- Inter-Availability-Zone data transfer
- Internet data transfer

## Budget controls

- Keep the existing AWS cost budget and email alert active.
- Use actual-spend alerts.
- Use forecast alerts when enough billing history is available.
- Filter Cost Explorer using the project tags.
- Check the Billing console after deployment.
- Check the Billing console again after teardown.
- Remember that AWS Budgets data can be delayed.
- Do not treat a budget alert as an automatic shutdown mechanism.

Recommended project tags:

```hcl
project      = "meeps"
week         = "week-10"
managed-by   = "terraform"
owner        = "meeps"
environment  = "dev"
```

## Implemented security controls

### Network isolation

- Only the Application Load Balancer is placed in public subnets.
- The backend EC2 instance is placed in a private application subnet.
- RDS is placed in a private database subnet group.
- The RDS subnet group spans two Availability Zones.
- The database is not intended to be publicly accessible.
- Application and database subnets use separate route tables.

### Security-group chaining

- Approved client CIDRs reach only the ALB entry ports.
- The application port is reachable from the ALB security group.
- The application port is not directly reachable from the internet.
- PostgreSQL port `5432` is reachable only from the application security group.
- Egress paths are restricted to the next required application tier.

AWS security groups are stateful. Response traffic for an allowed connection does not require a separate reverse rule.

### EC2 access

- The EC2 instance uses an IAM role.
- The IAM role is attached through an instance profile.
- `AmazonSSMManagedInstanceCore` supports Systems Manager Session Manager.
- No public application SSH rule is required.
- Session Manager still requires a network path to the SSM services.
- The network path can be provided through a NAT Gateway or the appropriate VPC interface endpoints.

### Database credentials

- No database password is stored in `terraform.tfvars`.
- RDS generates the master password.
- RDS stores and manages the master credentials through AWS Secrets Manager.
- Secret access should be granted only to workloads and operators that require it.
- The secret ARN is operational metadata.
- The secret value must never be printed in screenshots or committed to Git.

### Amazon S3 protection

Both the application bucket and remote-state bucket use:

- S3 Block Public Access
- Server-side encryption
- Bucket versioning
- Explicit ownership controls

The application bucket name includes the AWS account ID to reduce global bucket-name collisions.

### Terraform state protection

- State is stored in a private S3 backend.
- Bucket versioning provides recovery from accidental state overwrites.
- Native S3 lock files reduce concurrent-write risk.
- Backend IAM permissions should be restricted to the required bucket, state key, and lock key.
- Saved plan files are created under `/tmp`.
- A restrictive `umask` is used before creating plan or state files.

Marking a Terraform value as `sensitive` hides it from normal CLI output, but the value can still exist in state and saved plan files.

Terraform state and plan access must therefore be treated as privileged.

## Git protection

The repository should ignore:

```gitignore
**/.terraform/*
*.tfstate
*.tfstate.*
*.tfplan
crash.log
crash.*.log
terraform.tfvars
*.auto.tfvars
.DS_Store
```

Commit `.terraform.lock.hcl` because it records selected provider versions and checksums.

Never commit:

- AWS access keys
- Database passwords
- Secret values
- Private `terraform.tfvars`
- Local or downloaded Terraform state
- Saved plan files
- CLI output containing sensitive values

## Development versus production

### HTTP listener

Development choice:

- The project currently uses an HTTP listener.

Production improvement:

- Request an ACM certificate.
- Add an HTTPS listener.
- Redirect HTTP traffic to HTTPS.

### Public ALB ingress

Development choice:

- The ALB can accept traffic from broad client CIDR ranges.

Production improvement:

- Restrict client CIDRs where possible.
- Consider AWS WAF for additional protection.

### Single-AZ RDS

Development choice:

- RDS is deployed as Single-AZ.

Production improvement:

- Use Multi-AZ for database resilience.

### One-day backup retention

Development choice:

- RDS backup retention is one day.

Production improvement:

- Use a retention period that satisfies the organisation’s recovery requirements.

### RDS deletion protection

Development choice:

- RDS deletion protection is disabled for the disposable lab.

Production improvement:

- Enable deletion protection.

### AWS-managed encryption keys

Development choice:

- AWS-managed encryption is sufficient for the learning environment.

Production improvement:

- Consider customer-managed KMS keys where governance or compliance requires them.

### Optional NAT Gateway

Development choice:

- NAT Gateway creation remains disabled unless needed.

Production improvement:

- Provide controlled outbound access through NAT or service-specific VPC endpoints based on workload requirements.

### One EC2 backend

Development choice:

- The project deploys one private EC2 backend.

Production improvement:

- Use an Auto Scaling Group across multiple private subnets.

### Local Terraform workflow

Development choice:

- Terraform commands are executed from a local development environment.

Production improvement:

- Add automated CI checks.
- Add approval gates.
- Add infrastructure policy checks.
- Add security scanning.
- Add audit logging.

## Safe pre-apply checklist

- [ ] Confirm the active AWS account and Region.
- [ ] Confirm that `terraform.tfvars` contains no credentials.
- [ ] Run `terraform fmt -check -recursive`.
- [ ] Run `terraform validate`.
- [ ] Save and inspect the Terraform plan.
- [ ] Confirm the plan contains no unexpected replacements.
- [ ] Confirm the plan contains no unexpected deletions.
- [ ] Confirm the intended NAT Gateway setting.
- [ ] Confirm the ALB ingress CIDRs.
- [ ] Confirm the EC2 instance size.
- [ ] Confirm the RDS instance size.
- [ ] Confirm that the remote-state lock can be acquired.
- [ ] Confirm that the AWS budget alert is active.

## Teardown checklist

### Before destroy

- [ ] Save the required screenshots.
- [ ] Complete the project documentation.
- [ ] Confirm the current AWS identity.
- [ ] Confirm the active AWS Region.
- [ ] Confirm that no other environment uses the backend.
- [ ] Check the application bucket for current objects.
- [ ] Check the application bucket for noncurrent object versions.
- [ ] Check the application bucket for delete markers.
- [ ] Decide whether an RDS snapshot must be preserved.
- [ ] Create and review a saved destroy plan.

### Destroy the application environment

```bash
cd infra/terraform/envs/dev

umask 077

terraform plan \
  -destroy \
  -lock-timeout=5m \
  -out=/tmp/meeps-week10-destroy.tfplan

terraform show -no-color /tmp/meeps-week10-destroy.tfplan

terraform apply \
  -lock-timeout=5m \
  /tmp/meeps-week10-destroy.tfplan
```

Do not proceed if the plan includes resources outside the Week 10 development environment.

### Verify cleanup

```bash
terraform state list

terraform plan \
  -destroy \
  -lock-timeout=5m \
  -detailed-exitcode
```

Expected results after a successful destroy:

- `terraform state list` returns no managed resources.
- A destroy-mode plan returns exit code `0`.

Also verify in AWS that none of the following project resources remain:

- Application Load Balancer
- EC2 instance
- RDS instance
- NAT Gateway
- Elastic IP address
- Unattached EBS volume
- Manual RDS snapshot
- Application S3 object version
- Orphaned Secrets Manager secret

### Delete the backend last

The remote-state bucket must not be deleted before the main Terraform destroy finishes.

After the state is empty and all evidence has been preserved:

- Confirm that the backend is not shared.
- Inspect every state-object version.
- Remove the backend using its separate bootstrap configuration.
- Verify that the bucket is gone.
- Verify that the native S3 lock object is gone.

## References

- [Terraform S3 backend and native locking](https://developer.hashicorp.com/terraform/language/backend/s3)
- [Terraform sensitive data](https://developer.hashicorp.com/terraform/language/manage-sensitive-data)
- [AWS Budgets](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)
- [Amazon VPC security groups](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)
- [Amazon RDS security groups](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.RDSSecurityGroups.html)
- [RDS password management with Secrets Manager](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-secrets-manager.html)
- [Amazon S3 Block Public Access](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html)
