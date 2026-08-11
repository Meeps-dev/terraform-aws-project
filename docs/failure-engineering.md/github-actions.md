## Week 11: Failure Engineering Record

This document records the CI/CD, Terraform, OIDC, IAM, migration, and EC2 deployment failures encountered during Week 11. Each entry captures the observable signal, root cause, exact correction, verification, and preventive control.


## 1. Invalid needs: checkout Dependency

* Signal: GitHub reported that the workflow was invalid and that the test job depended on an unknown job named checkout.

* Failed workflow or step: Day 71 workflow validation failed before GitHub allocated a runner or executed any steps.

* Root cause: needs can reference only a job ID defined under jobs. checkout was a step inside the test job, not a separate job.

* Evidence: Red workflow-validation annotation pointing to .github/workflows/ci.yml; no checkout, Python setup, dependency installation, or pytest step started.

* Exact correction: Removed needs: checkout because the workflow contained only one job.

* Successful verification: GitHub parsed the workflow, started the Ubuntu runner, checked out the repository, configured Python 3.12, installed dependencies, and ran pytest successfully.

* Preventive control: Reference only existing job IDs in needs; review the workflow job graph before merging; keep the initial workflow simple until multiple jobs are introduced.

## 2. PostgreSQL Unavailable in CI

* Signal: SQLAlchemy/psycopg2 returned OperationalError: could not connect to server: Connection refused.

* Failed workflow or step: Day 71 pytest and database-dependent CI execution.

* Root cause: The GitHub-hosted Ubuntu runner did not provide PostgreSQL by default. The application also depended on a local database URL, and the required schema had not been created in the CI database.

* Evidence: Workflow traceback showing connection refusal on PostgreSQL port 5432; tests failed before completing database operations.

* Exact correction: Added a PostgreSQL 15 service container, configured an isolated CI DATABASE_URL, added a database health check, and ran alembic upgrade head before pytest.

* Successful verification: PostgreSQL became healthy, Alembic created the schema, and the database-dependent user and post tests passed.

* Preventive control: Use an ephemeral database for every CI job; never connect tests to production RDS; validate database readiness before migrations and tests.

## 3. Missing httpx Dependency

* Signal: FastAPI/Starlette raised RuntimeError: The starlette.testclient module requires the httpx package to be installed.

* Failed workflow or step: Pytest collection when importing or creating TestClient.

* Root cause: httpx was used indirectly by FastAPI's test client but was not declared in the installed test dependencies.

* Evidence: CI traceback identified starlette.testclient and explicitly stated that httpx was required.

* Exact correction: Added httpx to the declared dependencies and ensured the CI dependency-installation step installed the complete test dependency set.

* Successful verification: Pytest collected the test suite and executed the API tests successfully.

* Preventive control: Keep test-only dependencies in a version-controlled development requirements file; reproduce CI installation from a clean virtual environment before pushing.

## 4. Alembic Database Authentication Failure

* Signal: alembic upgrade head failed with fe_sendauth: no password supplied.

* Failed workflow or step: Day 71 Alembic migration step.

* Root cause: The CI connection URL used localhost, and the resulting connection path did not use the expected PostgreSQL service-container credentials. The connection string therefore reached PostgreSQL without the intended authentication details.

* Evidence: Alembic/psycopg2 traceback showed authentication failure while connecting to port 5432.

* Exact correction: Replaced localhost with the explicit IPv4 loopback address 127.0.0.1 and supplied the PostgreSQL username, password, port, and database name in DATABASE_URL.

* Successful verification: alembic upgrade head connected to the CI database and completed before pytest.

* Preventive control: Use explicit, tested CI connection strings; include a PostgreSQL health check; avoid relying on ambiguous hostname resolution in service-container workflows.

## 5. Ruff Formatting Failure

* Signal: ruff format --check reported that a file would be reformatted and returned a non-zero exit code.

* Failed workflow or step: Day 72 lint job, specifically the formatting-check step; the dependent package job was skipped.

* Root cause: A deliberately badly formatted Python file was committed to verify that the quality gate blocked packaging.

* Evidence: Red lint job showing the temporary file path and Ruff formatting diagnostic; workflow graph showed package skipped.

* Exact correction: Ran ruff format on the file, verified ruff check and ruff format --check, then removed the temporary test file after evidence was captured.

* Successful verification: The lint job passed and the package job ran after all required quality gates were green.

* Preventive control: Run Ruff locally or through a pre-commit hook; keep packaging dependent on lint, tests, migrations, and security checks.

## 6. Deliberate Pytest Assertion Failure

* Signal: Pytest reported a failed assertion such as assert 1 == 2.

* Failed workflow or step: Day 72 test job; the dependent package job was skipped.

* Root cause: A temporary failing test was intentionally added to prove that defective code could not progress to the build artifact.

* Evidence: Red test job showing the test filename, line number, assertion output, and skipped package job.

* Exact correction: Corrected the assertion, reran the isolated test, and removed the temporary failure test after capturing the evidence.

* Successful verification: Pytest passed, coverage was generated, and the package job produced the commit-specific ZIP artifact.

* Preventive control: Require test success before packaging or deployment; keep intentional-failure experiments isolated to feature branches.

## 7. OIDC Subject Mismatch

* Signal: AWS credential configuration failed with Could not assume role with OIDC or Not authorized to perform sts:AssumeRoleWithWebIdentity.

* Failed workflow or step: Day 73 AWS OIDC smoke-test credential step.

* Root cause: The workflow ran from a test/** branch, but the github-plan-role trust policy allowed only main, feature/*, and pull-request subjects.

* Evidence: Failed credential step; inspected GitHub token sub did not match any subject allowed by the IAM role trust policy.

* Exact correction: Renamed/moved the branch into the approved feature/* namespace instead of broadening the role trust policy.

* Successful verification: aws sts get-caller-identity returned an assumed-role ARN containing github-plan-role.

* Preventive control: Inspect the real GitHub OIDC sub and aud claims; restrict trust to exact repositories, branches, pull requests, or Environments; never use a broad repo:*/* subject.

## 8. Missing Linux Provider Checksum

* Signal: terraform init -lockfile=readonly refused to install AWS provider 6.57.1 because the Linux package checksum was absent from .terraform.lock.hcl.

* Failed workflow or step: Day 74 Terraform/OIDC root initialization on the GitHub-hosted Linux runner.

* Root cause: The dependency lock file had been generated on macOS and contained only the local platform checksum.

* Evidence: Terraform initialization log stated that the selected provider package did not match checksums in the lock file; CI ran on linux_amd64.

* Exact correction: Regenerated the provider lock information for both local and CI platforms:

terraform providers lock \
  -platform=darwin_amd64 \
  -platform=linux_amd64

* Successful verification: Read-only Terraform initialization and validation passed on GitHub Actions.

* Preventive control: Generate and commit provider checksums for every supported execution platform; keep -lockfile=readonly in CI so the runner cannot silently change dependency selections.

## 9. Missing s3:GetAccelerateConfiguration

* Signal: Terraform plan failed with 403 AccessDenied while reading the managed application-artifact S3 bucket.

* Failed workflow or step: Day 74 speculative Terraform plan during state refresh.

* Root cause: The AWS provider called s3:GetAccelerateConfiguration. The plan role allowed s3:GetBucket*, but that wildcard does not match s3:GetAccelerateConfiguration.

* Evidence: Terraform/AWS provider diagnostic named the denied API action and the affected S3 bucket.

* Exact correction: Added s3:GetAccelerateConfiguration to the Terraform read policy and scoped it only to managed_s3_bucket_arns; applied the IAM bootstrap update.

* Successful verification: IAM simulation reported the action as allowed, and the Terraform plan completed successfully.

* Preventive control: Add only the exact provider read action shown in the failure; scope S3 permissions to managed bucket ARNs; do not replace the policy with AmazonS3FullAccess.

## 10. Protected Apply AccessDenied

* Signal: The protected Terraform apply reached AWS but failed with one or more AccessDenied responses.

* Failed workflow or step: Day 75 approved terraform apply job.

* Root cause: The apply role initially had remote-state and read permissions but lacked the service-specific mutation actions required by the VPC, compute, ALB, RDS, S3, IAM, Secrets Manager, and KMS resources.

* Evidence: Apply logs identified denied actions against specific AWS resources; a later plan showed that resources created before the failure had been saved in remote state.

* Exact correction: Added only the required actions, including EC2/IAM instance-profile lifecycle operations, iam:PassRole, RDS-managed-secret permissions, and related service mutations; updated the OIDC bootstrap policies through a reviewed plan.

* Successful verification: The corrected policy update succeeded; the next dev plan showed only the remaining resources, and the protected apply completed successfully.

* Preventive control: Separate plan and apply roles; use service-scoped policies; correct the exact denied action rather than attaching AdministratorAccess; rely on remote state to continue safely after partial applies.

## 11. Incorrect S3 Encryption Permission

* Signal: Terraform failed while managing aws_s3_bucket_server_side_encryption_configuration.

* Failed workflow or step: Day 75 protected apply.

* Root cause: The policy used s3:PutBucketEncryption, but the required IAM action is s3:PutEncryptionConfiguration.

* Evidence: Apply error identified the S3 encryption operation; policy review showed the incorrect action name.

* Exact correction: Replaced the incorrect action with:

s3:PutEncryptionConfiguration

* Successful verification: The IAM correction plan applied with 0 added, 2 changed, 0 destroyed, and the subsequent protected infrastructure apply passed the S3 encryption step.

* Preventive control: Verify IAM action names against AWS service authorization documentation; use the action reported by CloudTrail or the provider error instead of guessing action names.

## 12. Destroy Environment Trust Mismatch

* Signal: The protected destroy workflow could not assume github-apply-role through OIDC.

* Failed workflow or step: Day 75 destroy workflow credential-configuration step.

* Root cause: The workflow token used the subject suffix environment:dev-destroy, while the live IAM trust policy allowed only environment:dev. The Terraform code contained the new subject, but the trust-policy change had not yet been applied to AWS.

* Evidence: Failed OIDC step; token claim and live role trust policy showed different Environment subjects.

* Exact correction: Added both approved subjects to the apply-role trust policy and applied the bootstrap change:

environment:dev
environment:dev-destroy

* Successful verification: The trust-policy plan reported 0 added, 1 changed, 0 destroyed; the destroy workflow assumed the role and later completed the protected teardown.

* Preventive control: Treat every GitHub Environment as a distinct OIDC subject; run an OIDC smoke test for each protected Environment before enabling state-changing jobs.

## 13. CD Skipped Because CI Used workflow_dispatch

* Signal: CI passed, but the deployment job was immediately marked skipped and no runner was allocated.

* Failed workflow or step: Day 76 job-level condition in .github/workflows/deploy-dev.yml.

* Root cause: The deployment condition required the source CI run event to be push, but the CI workflow had been started manually with workflow_dispatch.

* Evidence: Condition comparison showed conclusion=success, branch=main, and same repository were true, but workflow_run.event was workflow_dispatch instead of push; the skipped job duration was zero seconds.

* Exact correction: Triggered a fresh CI run through a real push/merge to main rather than rerunning the manually dispatched CI event.

* Successful verification: The new workflow_run event satisfied the deployment condition and created a CD run for the new commit.

* Preventive control: Document the CI-to-CD event contract; accept only trusted push runs from main; do not weaken the condition merely to deploy a manually generated artifact.

## 14. Alembic % Interpolation Failure

* Signal: SSM transport succeeded, but the remote deployment command failed during alembic upgrade head with a ConfigParser interpolation error.

* Failed workflow or step: Day 76 SSM deployment command during the Alembic migration operation.

* Root cause: The RDS password contained URL-encoded % characters. Alembic's configuration parser interpreted % as interpolation syntax instead of as part of the encoded password.

* Evidence: SSM command output and Alembic traceback referenced invalid interpolation syntax; the database URL contained percent-encoded password characters.

* Exact correction: Escaped % as %% before setting Alembic's SQLAlchemy URL and added regression coverage for percent-encoded database credentials.

* Successful verification: The regression test passed; the blank-database Alembic upgrade reached the migration head; alembic check reported no schema drift.

* Preventive control: Test migration configuration with reserved URL characters; avoid writing raw secrets to logs; keep encoded-credential regression tests in CI.

## 15. Unsafe Migration and Missing-Table Repair

* Signal: Migration testing or deployment produced missing-relation errors such as relation "users" does not exist, and an existing migration attempted to remove the users and posts tables.

* Failed workflow or step: Day 72/76 migration validation and the remote Alembic deployment step.

* Root cause: Alembic metadata did not load all application models consistently, and a destructive migration was incompatible with the intended schema. Some environments could therefore reach a state where required tables were absent.

* Evidence: Database traceback referenced the missing users relation; migration review showed DROP TABLE users and DROP TABLE posts.

* Exact correction: Loaded all models into Alembic metadata, neutralized the destructive migration, and added an idempotent repair migration that creates missing users and posts tables without damaging healthy environments.

* Successful verification: A blank database upgraded to head, alembic check showed no drift, and the repair migration restored deliberately missing tables.

* Preventive control: Review generated migrations before committing; test upgrades from an empty database and from damaged/older schemas; prefer backward-compatible forward migrations over automatic destructive downgrades.

## 16. EC2 Virtual-Environment Permission and Rollback Issue

* Signal: The SSM deployment script failed while preparing or using the Python virtual environment, and first-deployment rollback could not safely restore a previous FastAPI release.

* Failed workflow or step: Day 76 remote EC2 deployment script and rollback handler.

* Root cause: Virtual-environment ownership/permissions were inconsistent with the systemd application user, and the rollback path assumed a previous release existed even during the first deployment.

* Evidence: SSM output, systemctl status, and journalctl showed deployment/service failure; release structure had no earlier current target during the first deployment.

* Exact correction: Corrected virtual-environment permissions, made deployment steps idempotent, checked whether a previous release existed before rollback, and restored the placeholder service when no earlier FastAPI release was available.

* Successful verification: Shell syntax and deployment tests passed; the corrected script could prepare the release, manage systemd safely, and execute the appropriate rollback path.

* Preventive control: Test both first-deployment and upgrade-deployment paths; verify ownership explicitly; retain at least one previous release; collect SSM, systemd, and journal logs automatically when deployment fails.

## Overall Engineering Outcome

Week 11 demonstrated that pipeline failures should be treated as controlled engineering signals rather than bypassed with broad permissions or disabled quality gates. The completed controls included isolated CI databases, dependency and migration validation, immutable artifacts, AWS OIDC, separate least-privilege roles, protected apply/destroy Environments, native S3 state locking, SSM deployment, health verification, rollback handling, and evidence-driven corrections.