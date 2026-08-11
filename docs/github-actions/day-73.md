# Day 73: Github OIDC and AWS least-privilege IAM ROLE

## What I Did, Learned, Broke and Fixed

## What I Did

* Inspected the GitHub OIDC `sub` and `aud` claims for the Terraform and application repositories.
* Created a separate Terraform bootstrap root for GitHub OIDC and IAM resources.
* Configured an AWS GitHub OIDC provider using `token.actions.githubusercontent.com`.
* Created separate least-privilege IAM roles:

  * `github-plan-role`
  * `github-apply-role`
  * `github-app-deploy-role`
* Restricted the plan role by repository and approved branches.
* Restricted apply and deployment roles to the protected `dev` GitHub Environment.
* Configured native S3 state locking and separate state access for plan and apply roles.
* Created a private S3 bucket for application deployment artifacts.
* Added GitHub Actions OIDC smoke-test workflows.
* Used `aws sts get-caller-identity` to verify assumed-role sessions.
* Created an intentional OIDC trust failure and tested the correction.
* Removed temporary Day 73 branches and retained only `main`.

## What I Learned

* GitHub Actions can access AWS through identity federation without storing permanent AWS access keys.
* `id-token: write` only allows a job to request an OIDC token; the IAM role still determines AWS permissions.
* The IAM trust policy defines **who can assume a role**, while the permissions policy defines **what the role can do**.
* The OIDC `aud` claim identifies AWS STS, while the `sub` claim identifies the repository, branch, pull request, or environment.
* Environment-based jobs use a subject similar to:

```text
repo:OWNER/REPOSITORY:environment:dev
```

* Terraform plan and apply operations should use separate IAM roles.
* A plan role needs limited write access to the native S3 `.tflock` object but should not modify infrastructure.
* Role session names make GitHub workflow activity easier to identify in AWS logs.
* Terraform bootstrap resources should use separate state so normal environment teardown does not remove pipeline authentication.

## What Broke

* Terraform initially failed because the S3 remote-state bucket no longer existed.
* OIDC variables were mistakenly placed in the Week 10 development root module.
* Terraform modules and the S3 backend were not initialized.
* `terraform.tfvars` incorrectly contained Terraform expressions such as:

```hcl
"${data.aws_caller_identity.current.account_id}"
```

* Quotation marks entered at interactive prompts became part of the AWS Region and OIDC subject values.
* The `tags` variable expected a map but received a single string.
* Complete OIDC subjects containing `:ref:refs/heads/...` were supplied where only repository prefixes were required.
* The AWS provider reported a deprecated `aws_region.current.name` reference.
* An intentional branch outside the approved `feature/*` namespace failed to assume the plan role.

## How I Fixed It

* Recreated and secured the Terraform state bucket with encryption, versioning, public-access blocking, and native lock-file support.
* Created a separate private deployment-artifact bucket.
* Moved OIDC values into:

```text
bootstrap/github-oidc/terraform.tfvars
```

* Reinitialized the correct root module with:

```bash
terraform init -reconfigure -backend-config=backend.hcl
```

* Replaced computed expressions in `terraform.tfvars` with literal bucket names and ARNs.
* Removed quotation marks when responding to interactive prompts and later used `-input=false`.
* Changed `tags` to a proper map.
* Removed branch suffixes from the OIDC repository prefixes.
* Replaced:

```hcl
data.aws_region.current.name
```

with:

```hcl
data.aws_region.current.region
```

* Corrected the intentional OIDC failure by moving the test commit to an approved `feature/*` branch instead of widening the IAM trust policy.
* Verified the pipeline identity using temporary STS assumed-role credentials rather than a personal IAM user.

## Result

Day 73 established secure GitHub-to-AWS authentication using OIDC, temporary AWS STS credentials, repository and environment trust restrictions, and separate least-privilege IAM roles for Terraform planning, Terraform application, and application deployment. This satisfies Week 11’s AWS OIDC, secure authentication, intentional pipeline failure, and documentation objectives. 
