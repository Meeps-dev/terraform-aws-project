## Week 11 Troubleshooting Notes

## GitHub Actions and Application CI

## Workflow rejected because of needs: checkout

* Symptom: GitHub reported that the test job depended on an unknown job named checkout.

* Cause: checkout was a step, not a job ID.

* Fix: Removed needs: checkout.

* Verification: The runner started and completed checkout, Python setup, dependency installation, and pytest.

## PostgreSQL connection refused in CI

* Symptom: OperationalError: could not connect to server: Connection refused.

* Cause: GitHub-hosted runners do not run PostgreSQL automatically.

* Fix: Added a PostgreSQL 15 service container, health check, CI DATABASE_URL, and migration step.

* Verification: PostgreSQL became healthy and database-dependent tests passed.

##  FastAPI TestClient failed

* Symptom: starlette.testclient reported that httpx was required.

* Cause: httpx was missing from the installed test dependencies.

* Fix: Added httpx to the declared dependencies.

* Verification: Pytest collected and ran the API tests successfully.

##  Alembic authentication failed

* Symptom: fe_sendauth: no password supplied.

* Cause: The CI database URL and localhost connection did not use the intended PostgreSQL service-container credentials.

* Fix: Used a complete connection URL and changed the host to 127.0.0.1.

* Verification: alembic upgrade head completed before pytest.

##  Required database tables were missing

* Symptom: relation "users" does not exist.

* Cause: The test database schema was not reliably prepared before the tests ran.

* Fix: Added deterministic test schema setup and retained a separate Alembic migration-check job.

* Verification: Repeated test runs passed without depending on test order.

## Ruff formatting gate failed

* Symptom: ruff format --check reported that a file required formatting.

* Cause: A deliberately unformatted file was committed to test the quality gate.

* Fix: Ran ruff format, verified the file, and removed the temporary test file.

* Verification: The lint job passed and the package job was allowed to run.

##  Deliberate pytest assertion failed

* Symptom: Pytest reported an assertion such as assert 1 == 2.

* Cause: A temporary failing test was added intentionally.

* Fix: Corrected the assertion and removed the temporary test afterward.

* Verification: Tests, coverage, and artifact packaging completed successfully.

## Dependency security audit failed

* Symptom: pip-audit reported vulnerable versions, including FastAPI/Starlette-related findings.

* Cause: Application dependencies contained versions affected by known CVEs.

* Fix: Upgraded compatible affected packages and moved FastAPI and Starlette together to compatible fixed versions.

* Verification: pip-audit passed and the application tests remained green.

##  AWS OIDC and IAM

* GitHub could not assume an AWS role

* Symptom: Could not assume role with OIDC or sts:AssumeRoleWithWebIdentity was denied.

* Cause: The GitHub OIDC sub claim did not match the repository, branch, or Environment allowed by the trust policy.

* Fix: Used the approved feature/* branch or corrected the exact Environment subject.

* Verification: aws sts get-caller-identity returned the expected assumed-role ARN.

##  Terraform OIDC variables were rejected

* Symptom: Subject-prefix validation failed, the AWS Region contained quotation marks, and tags expected a map.

* Cause: Values were entered interactively with extra quotes, full branch subjects were used instead of repository prefixes, and expressions were placed in .tfvars.

* Fix: Used literal values in terraform.tfvars, removed branch suffixes, and supplied tags as a map.

* Verification: terraform validate and terraform plan -input=false succeeded.

## GitHub IAM roles were missing from AWS

* Symptom: Terraform planned to recreate the plan, apply, and deployment roles.

* Cause: The roles had been manually deleted, creating drift between Terraform state and AWS.

* Fix: Restored the roles and attachments through the OIDC Terraform bootstrap.

* Verification: The roles existed again and their trust and permission policies matched Terraform.

## Terraform CI, Apply, and Destroy

* S3 backend bucket did not exist

* Symptom: NoSuchBucket during terraform init.

* Cause: The remote-state bucket had been deleted.

* Fix: Recreated and secured the persistent state bucket with encryption, versioning, public-access blocking, and native locking.

* Verification: terraform init -reconfigure successfully initialized the S3 backend.

##  Renamed backend key risked empty state

* Symptom: The new backend key did not initially contain the previous Terraform state.

* Cause: Changing an S3 backend key changes the state-object location.

* Fix: Verified old and new keys and used terraform init -migrate-state when migration was required.

* Verification: terraform state list showed the expected resources under the new key.

## Provider lock file failed on Linux

* Symptom: terraform init -lockfile=readonly rejected AWS provider 6.57.1.

* Cause: .terraform.lock.hcl contained macOS checksums but not linux_amd64.

* Fix:

terraform providers lock \
  -platform=darwin_amd64 \
  -platform=linux_amd64

* Verification: Terraform initialized successfully on GitHub's Linux runner.

##  Terraform plan could not inspect an S3 bucket

* Symptom: 403 AccessDenied for s3:GetAccelerateConfiguration.

* Cause: s3:GetBucket* does not include s3:GetAccelerateConfiguration.

* Fix: Added the exact read action and scoped it to the managed S3 bucket ARNs.

* Verification: IAM simulation and the speculative Terraform plan succeeded.

##  Protected Terraform apply returned AccessDenied

* Symptom: The approved apply reached AWS but failed during resource creation or modification.

* Cause: The apply role had state and read permissions but lacked specific mutation actions required by the modules.

* Fix: Added only the required EC2, ALB, RDS, S3, IAM, Secrets Manager, and KMS actions.

##  Verification: A new plan contained only the remaining resources and the protected apply succeeded.

* Incorrect S3 encryption permission

* Symptom: Terraform failed while configuring S3 server-side encryption.

* Cause: The IAM policy used s3:PutBucketEncryption.

* Fix: Replaced it with:

s3:PutEncryptionConfiguration

* Verification: The policy update and subsequent S3 encryption resource completed successfully.

##  Destroy workflow could not assume the apply role

* Symptom: OIDC authentication failed in the dev-destroy job.

* Cause: The live trust policy allowed environment:dev but not environment:dev-destroy.

* Fix: Added both protected Environment subjects and applied the trust-policy update.

* Verification: The destroy workflow assumed the role and completed the protected teardown.

##  EC2 Deployment Through S3 and SSM

* CD job was skipped after successful CI

* Symptom: CI passed, but the deployment job showed skipped with zero runtime.

* Cause: The deployment condition required a source CI event of push, but CI had been started with workflow_dispatch.

* Fix: Triggered a fresh CI run through a real push or merge to main.

* Verification: The new workflow_run event created a deployment run.

##  Private EC2 was not ready for deployment traffic

* Symptom: SSM, package installation, or AWS API access could not work from the private instance.

* Cause: NAT was disabled and the application Security Group did not allow HTTPS egress.

* Fix: Temporarily enabled NAT for the lab and allowed controlled HTTPS egress.

* Verification: The instance appeared Online in Systems Manager.

## SSM deployment failed during Alembic execution

* Symptom: SSM transport succeeded, but the remote command failed during alembic upgrade head.

* Cause: The URL-encoded RDS password contained %, which Alembic treated as interpolation syntax.

* Fix: Escaped % before setting the Alembic SQLAlchemy URL.

* Verification: The encoded-password regression test and database upgrade passed.

##  Unsafe migration removed application tables

* Symptom: users or posts tables were absent after migration.

* Cause: An existing migration incorrectly contained destructive table-drop operations.

* Fix: Neutralized the unsafe migration and added an idempotent repair migration.

* Verification: A blank database upgraded to head, alembic check showed no drift, and missing tables were repaired.

##  EC2 virtual-environment permissions failed

* Symptom: The application user could not reliably execute or use the deployed virtual environment.

* Cause: Virtual-environment ownership and permissions were inconsistent with the systemd service user.

* Fix: Corrected ownership and restricted permissions while preserving execute/read access for the service group.

* Verification: systemd launched FastAPI and the local /health check passed.

##  First-deployment rollback was unsafe

* Symptom: Rollback expected a previous FastAPI release even when none existed.

* Cause: The first deployment had no earlier current symlink to restore.

* Fix: Added separate rollback behavior for first deployment and restored the placeholder backend when necessary.

* Verification: Failed deployment logs showed the correct rollback path, and the previous working service remained available.

##  ALB health check failed because of a port mismatch

* Symptom: The service could start, but the ALB target remained unhealthy.

* Cause: FastAPI and the ALB target group were not using the same application port.

* Fix: Standardized the application, systemd, Security Group, target group, and health checks on port 8080.

* Verification: Local and ALB /health checks passed.

##  Teardown and Cost Troubleshooting

* Versioned S3 bucket could not be deleted

* Symptom: Terraform could not remove a versioned S3 bucket even after current objects were deleted.

* Cause: Noncurrent versions and delete markers remained, while the bucket used restrictive destroy behavior.

* Fix: Removed object versions and delete markers, and added an S3 lifecycle rule for future release cleanup.

* Verification: Terraform deleted the application buckets during the protected teardown.

##  Deployment workflow could target deleted infrastructure

* Symptom: A later successful CI run could attempt deployment after EC2, ALB, and RDS had been destroyed.

* Cause: The deployment workflow had no explicit enable/disable control.

* Fix: Added a deployment gate variable and disabled EC2 deployment after evidence collection.

* Verification: Post-teardown deployment jobs were intentionally skipped rather than failing against stale resource IDs.

##  Useful Diagnostic Commands

* GitHub and Git

* git status
* git diff
* git branch --show-current
* gh run list
* gh run view <run-id> --log-failed

* Terraform

* terraform fmt -check -recursive infrastructure
* terraform validate
* terraform plan -input=false -no-color -lock-timeout=5m
* terraform state list

* AWS Identity and OIDC

* aws sts get-caller-identity
* aws iam get-role --role-name github-plan-role
* aws iam get-role --role-name github-apply-role
* aws iam get-role --role-name github-app-deploy-role

* Systems Manager and EC2

* aws ssm describe-instance-information
* aws ssm list-command-invocations --details
* sudo systemctl status users-posts-api
* sudo journalctl -u users-posts-api -n 100 --no-pager
* curl -f http://127.0.0.1:8080/health

* ALB and RDS

* aws elbv2 describe-target-health --target-group-arn <target-group-arn>
* aws rds describe-db-instances
* curl -f http://<alb-dns-name>/health

##  Final Troubleshooting Principle

* Read the first complete error, not only the final failure line.

* Fix one root cause at a time.

* Add only the exact missing IAM permission.

* Do not bypass failures with continue-on-error, AdministratorAccess, disabled tests, or disabled state locking.

* Preserve the failed log, correction commit, and successful rerun as portfolio evidence.