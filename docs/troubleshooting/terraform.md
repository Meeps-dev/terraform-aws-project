# Week 10 Terraform Troubleshooting Notes

This runbook records the failures encountered during the Week 10 build and the checks used to diagnose common VPC, ALB, EC2, RDS, S3, backend, and Terraform workflow problems.

## Diagnostic order

Start with the smallest safe checks:

```bash
aws sts get-caller-identity \
  --region eu-west-2 \
  --no-cli-pager

terraform version
terraform init
terraform validate

terraform plan \
  -lock-timeout=5m \
  -detailed-exitcode
```

Do not apply a change until the Terraform plan has been reviewed.

## Issues encountered and fixed

### 1. Reference to undeclared input variable

#### Symptom

```text
Error: Reference to undeclared input variable
```

The VPC module referenced inputs such as the project name, subnet CIDRs, or NAT Gateway toggle without declaring every input in its own `variables.tf`.

#### Cause

Each Terraform child module has its own variable contract.

A variable declared in the root environment does not automatically exist inside a child module.

#### Fix

- Declare every child-module input in that module’s `variables.tf`.
- Pass the value explicitly from `envs/dev/main.tf`.
- Match the declared type to the value being supplied.

Validate the fix:

```bash
terraform fmt -recursive

cd envs/dev
terraform validate
terraform plan
```

### 2. Reference to undeclared Availability Zones data source

#### Symptom

```text
Error: Reference to undeclared resource

A data resource "aws_availability_zones" "available" has not been
declared in module.vpc.
```

#### Cause

The VPC module referenced `data.aws_availability_zones.available`, but the data block existed only in another module or in the root environment.

#### Fix

Declare the data source inside the module that consumes it:

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}
```

Terraform module scopes are isolated.

Root data sources, resources, and locals are available to a child module only when their values are passed as module inputs.

### 3. Existing S3 bucket was not under Terraform control

#### Symptom

Terraform configuration described an existing bucket, but Terraform planned to create it or returned a bucket-name conflict.

#### Cause

Writing a Terraform resource block does not automatically attach an existing AWS resource to Terraform state.

#### Fix

```bash
terraform import \
  aws_s3_bucket.import_lab \
  "<existing-bucket-name>"

terraform state show aws_s3_bucket.import_lab
terraform plan
```

The import was complete only when:

- The resource configuration matched the real S3 bucket.
- The imported state address was correct.
- The final Terraform plan reported no changes.

### 4. Backend configuration changed

#### Symptom

```text
Error: Backend configuration changed
```

#### Cause

Terraform detected that the root configuration had moved from local state to the S3 backend.

#### Fix used for the migration

```bash
terraform init -migrate-state
```

Confirm the migration prompt carefully.

Do not use `-reconfigure` when the intention is to copy existing local state into the new backend.

After the migration:

```bash
terraform state list
terraform plan
```

The managed-resource list should remain intact, and the plan should show no unintended changes.

### 5. Error acquiring the state lock

#### Symptom

```text
Error: Error acquiring the state lock
```

#### Cause

Another Terraform process held the native S3 lock.

During the Week 10 concurrency test, this error was expected and proved that native S3 state locking worked.

#### Fix

- Allow the first Terraform process to finish.
- Check for another Terraform terminal.
- Check for an active CI job.
- Check whether an interrupted Terraform operation still owns the lock.
- Retry with a reasonable lock timeout.

```bash
terraform plan \
  -lock-timeout=5m
```

Do not use `-lock=false` for normal plan, apply, or destroy operations.

Do not run `terraform force-unlock` unless the lock owner and failed operation have been verified.

### 6. AWS STS TLS handshake timeout

#### Symptom

```text
Error: validating provider credentials
retrieving caller identity from STS
TLS handshake timeout
```

#### Cause

The Mac could not complete the HTTPS connection to the regional AWS STS endpoint.

This was a network or AWS service-connectivity problem, not Terraform drift.

#### Fix

First, test AWS connectivity directly:

```bash
aws sts get-caller-identity \
  --region eu-west-2 \
  --cli-connect-timeout 30 \
  --cli-read-timeout 60 \
  --no-cli-pager
```

If the command fails:

- Disconnect any active VPN or proxy.
- Reconnect the Wi-Fi.
- Try a trusted mobile hotspot.
- Wait briefly and retry.
- Confirm that the system clock is correct.

After the AWS STS request succeeds:

```bash
AWS_RETRY_MODE=standard \
AWS_MAX_ATTEMPTS=10 \
terraform plan \
  -lock-timeout=5m \
  -detailed-exitcode
```

The failed plan did not apply changes and did not require `terraform init -reconfigure`.

### 7. Terraform plan exit code was confusing

When `-detailed-exitcode` is used:

- Exit code `0` means the plan succeeded and no changes were detected. This is the expected result for a no-change verification.
- Exit code `1` means the planning operation failed. Fix the error and do not apply.
- Exit code `2` means the plan succeeded and contains proposed changes. Review every change before applying.

Capture the exit code immediately:

```bash
terraform plan \
  -lock-timeout=5m \
  -detailed-exitcode

PLAN_EXIT_CODE=$?

echo "Plan exit code: $PLAN_EXIT_CODE"
```

### 8. Output cleanup returned exit code 2

#### Symptom

The cleanup plan showed eight root outputs changing to `null` and returned exit code `2`.

#### Cause

Removing output blocks changes the values stored in Terraform state even when no AWS resource changes.

#### Resolution

The plan was reviewed to confirm:

- Only the intended outputs were removed.
- No VPC changed.
- No subnet changed.
- No route table changed.
- No security group changed.
- No ALB changed.
- No EC2 instance changed.
- No RDS database changed.
- No S3 bucket changed.
- The apply summary was `0 added, 0 changed, 0 destroyed`.
- A final normal plan returned exit code `0`.

An output-only plan must still be reviewed and applied if the stored Terraform state outputs should be updated.

## Infrastructure runbook

### ALB targets are unhealthy

Check the registered targets:

```bash
aws elbv2 describe-target-health \
  --target-group-arn "<target-group-arn>" \
  --region eu-west-2 \
  --no-cli-pager
```

Verify:

- The application listens on `0.0.0.0:8080`.
- The application is not listening only on `127.0.0.1`.
- `GET /health` returns a successful HTTP status.
- The target group uses the correct backend port.
- The target group uses the correct health-check path.
- The EC2 instance is registered with the target group.
- The application security group permits port `8080` from the ALB security group.
- The ALB security group permits egress to the application security group.

### Private EC2 instance does not appear in Session Manager

Verify:

- The EC2 instance is running.
- The IAM instance profile is attached.
- The IAM role includes `AmazonSSMManagedInstanceCore`.
- SSM Agent is installed.
- SSM Agent is running.
- DNS support is enabled in the VPC.
- DNS hostnames are enabled in the VPC.
- The private subnet has a network path to the SSM services.
- The network path is provided through NAT or the required VPC interface endpoints.

Do not add a public SSH rule merely to hide an SSM networking problem.

### EC2 cannot connect to RDS

From the backend instance:

```bash
nc -zv "<rds-endpoint>" 5432
```

Check:

- The endpoint matches the Terraform output.
- The port matches the Terraform output.
- RDS is in the intended database subnet group.
- RDS is not publicly accessible.
- The RDS security group allows port `5432` from the application security group.
- The application security group allows egress to the RDS security group.
- VPC DNS is working.
- The application retrieves the correct secret.
- The application uses the correct database name.

Do not open PostgreSQL port `5432` to `0.0.0.0/0`.

### ALB creation reports a subnet or Availability Zone error

An Application Load Balancer requires suitable subnets in at least two Availability Zones.

Check:

```bash
aws ec2 describe-subnets \
  --subnet-ids "<public-subnet-1>" "<public-subnet-2>" \
  --region eu-west-2 \
  --no-cli-pager
```

Confirm that the subnets:

- Belong to the same VPC.
- Are located in different Availability Zones.
- Are associated with the public route table.
- Have a default route to the Internet Gateway.

### S3 bucket deletion fails because the bucket is not empty

With bucket versioning enabled, deleting the visible objects is not enough.

The bucket can still contain:

- Noncurrent object versions
- Delete markers
- Incomplete multipart uploads

Inspect the bucket before teardown:

```bash
aws s3api list-object-versions \
  --bucket "<application-bucket-name>" \
  --no-cli-pager
```

Back up anything that must be preserved.

Remove current objects, noncurrent versions, and delete markers before retrying the reviewed Terraform destroy.

Never run an account-wide S3 deletion command.

### RDS deletion fails

Check:

- Whether deletion protection is enabled.
- Whether Terraform expects a final snapshot.
- Whether the chosen final snapshot identifier already exists.
- Whether the database is currently modifying.
- Whether the database is backing up.
- Whether the database is restarting.

For a disposable development database, the Terraform configuration must explicitly represent the intended deletion-protection and snapshot policy before creating a new destroy plan.

Do not change these settings blindly in the AWS console.

### Provider installation or Terraform Registry timeout

Test the internet connection and DNS first:

```bash
curl -I https://registry.terraform.io
terraform init
```

Do not use `terraform init -upgrade` merely to fix a temporary registry timeout.

The `-upgrade` option can:

- Select newer provider versions permitted by the version constraints.
- Update `.terraform.lock.hcl`.
- Introduce unrelated provider changes.

## Formatting appears to produce no output

No output from the following command normally means the formatting check passed:

```bash
terraform fmt -check -recursive
```

For clearer terminal evidence:

```bash
terraform fmt -recursive

terraform fmt -check -recursive &&
  echo "PASS: All Terraform files are correctly formatted."
```

If the command prints filenames, inspect the formatting changes using Git before committing.

## Recovery rules

- Never delete or edit a Terraform state file manually.
- Never delete the backend bucket while an environment still uses it.
- Never apply a plan that has not been reviewed.
- Never reuse a saved plan after editing the Terraform configuration.
- Avoid `-target` during routine deployment.
- Reserve `-target` for exceptional recovery scenarios.
- Avoid `-lock=false`.
- Store sensitive saved plans or state only in protected temporary storage.
- If an apply partially succeeds, rerun `terraform plan`.
- Do not assume Terraform automatically rolled back a partially completed apply.

## Final verification

### Live environment

```bash
terraform plan \
  -lock-timeout=5m \
  -detailed-exitcode
```

Expected result:

```text
No changes. Your infrastructure matches the configuration.
```

The expected exit code is `0`.

### Destroyed environment

```bash
terraform state list

terraform plan \
  -destroy \
  -lock-timeout=5m \
  -detailed-exitcode
```

Expected results:

- `terraform state list` returns no managed resources.
- The destroy-mode plan returns exit code `0`.

Do not run a normal Terraform plan after teardown unless you intentionally want to preview recreating the infrastructure.

## References

- [Terraform init](https://developer.hashicorp.com/terraform/cli/commands/init)
- [Terraform fmt](https://developer.hashicorp.com/terraform/cli/commands/fmt)
- [Terraform validate](https://developer.hashicorp.com/terraform/cli/commands/validate)
- [Terraform plan](https://developer.hashicorp.com/terraform/cli/commands/plan)
- [Terraform apply](https://developer.hashicorp.com/terraform/cli/commands/apply)
- [Terraform state locking](https://developer.hashicorp.com/terraform/language/state/locking)
- [Application Load Balancer target health checks](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html)
- [EC2 Session Manager](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-with-systems-manager-session-manager.html)
- [Working with RDS in a VPC](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_VPC.WorkingWithRDSInstanceinaVPC.html)
