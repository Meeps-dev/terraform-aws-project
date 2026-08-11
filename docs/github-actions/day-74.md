### Day 74: Terraform CI — fmt, validate and plan Repository

### What I Did, Learned, Broke and Fixed


### What I Did

* Created .github/workflows/terraform-ci.yml.
* Configured workflow triggers for:
* Pull requests targeting main
* Pushes to feature/** branches
* Manual runs using workflow_dispatch
* Added path filters so documentation or application-only changes do not trigger Terraform CI.
* Created separate jobs for:
* Terraform formatting and validation
* Terraform planning through AWS OIDC
* Set:
TF_IN_AUTOMATION=true
TF_INPUT=false
* Authenticated GitHub Actions to AWS using github-plan-role.
* Initialized the existing S3 backend using the renamed Week 10 state key:
* terraform-bootstrap/dev-backend/terraform.tfstate
* Used native S3 .tflock state locking instead of DynamoDB.
* Added Terraform detailed exit-code handling.
* Prevented terraform apply and terraform destroy from running in the CI workflow.
* Created, captured, corrected, and removed an intentional Terraform formatting failure.

### What I Learned

* Infrastructure CI validates Terraform code and previews infrastructure changes without modifying AWS resources.
terraform fmt, validate, and plan should run before any protected apply operation.
* Only the Terraform plan job needs id-token: write.
* .terraform.lock.hcl must contain provider checksums for every platform used by the team and CI runners.
* macOS and GitHub Actions Linux runners can require different provider checksums.
* -lockfile=readonly prevents CI from silently modifying the dependency lock file.
* Terraform refreshes resources already stored in state before producing a plan.
* A least-privilege plan role may require additional read-only permissions when new resources are imported into state.
* Terraform exit codes mean:
0 — plan succeeded with no changes
1 — plan failed
2 — plan succeeded with proposed changes
* Binary plan files and sensitive plan details should not be published as public workflow artifacts.

### What Broke

* The OIDC Terraform root failed during initialization because its lock file was generated on macOS and did not contain the Linux checksum for AWS provider 6.57.1.
* Because CI used -lockfile=readonly, Terraform refused to install the Linux provider package or update the lock file.
* The Terraform plan later failed with 403 AccessDenied while refreshing the imported application-artifact S3 bucket.
* The AWS provider attempted to call:
s3:GetAccelerateConfiguration
The GitHub plan role did not contain that exact permission.
* The existing s3:GetBucket* wildcard did not match s3:GetAccelerateConfiguration.
* The deliberate unformatted Terraform file caused terraform fmt -check to fail and correctly prevented the plan job from running.

### How I Fixed It

* Regenerated the provider lock file with checksums for both macOS and Linux:
terraform providers lock \
  -platform=darwin_amd64 \
  -platform=linux_amd64
* Committed the updated .terraform.lock.hcl so GitHub Actions could install the verified Linux provider package.
* Added the exact permission:
s3:GetAccelerateConfiguration
* Scoped the permission only to the approved managed_s3_bucket_arns.
* Planned and applied the least-privilege IAM policy update.
* Verified through IAM simulation that the action was allowed.
* Formatted the intentionally broken Terraform file and reran the workflow.
* Removed the temporary formatting-test file after capturing the failed and successful evidence.

### Result

* The final Terraform CI pipeline successfully completed formatting checks, validation, AWS OIDC authentication, S3 remote-state access, native state locking, resource refresh, and a speculative Terraform plan. No infrastructure was applied or destroyed. This completed Week 11’s Terraform-plan-in-CI, AWS OIDC, failure-debugging, and documentation requirements.