# Day 75: Protected Terraform Apply and Destroy

## What I Did

- Created a manual Terraform apply workflow using `workflow_dispatch`.
- Configured the protected `dev` GitHub Environment with approval and `main` branch restrictions.
- Used separate `github-plan-role` and `github-apply-role` OIDC sessions.
- Added a pre-approval Terraform plan before the protected apply job.
- Used the shared `terraform-dev` concurrency group to prevent overlapping apply and destroy operations.
- Added service-specific IAM permissions for VPC, EC2, ALB, RDS, S3, IAM, Secrets Manager, and KMS.
- Created a manual-only protected destroy workflow using the `dev-destroy` environment.
- Successfully applied the remaining development resources after approval.
- Successfully destroyed the development environment through the protected workflow.

## What I Learned

- GitHub Environments provide a human approval gate before infrastructure changes.
- Environment-based OIDC jobs use subjects such as `environment:dev` and `environment:dev-destroy`.
- Terraform records successful resources from a partial apply in remote state.
- A later plan continues only with the resources that remain.
- Apply and destroy workflows should share one concurrency group to protect the same state.
- Least-privilege IAM permissions should be expanded only when a specific `AccessDenied` proves an action is required.
- Terraform workflow logs, commit SHAs, approvals, role-session names, and state keys provide an audit trail.

## What Broke

- The three GitHub IAM roles were manually deleted from AWS, creating drift from Terraform state.
- The protected apply initially failed because the apply role lacked required AWS mutation permissions.
- The S3 policy used the wrong action, `s3:PutBucketEncryption`, instead of `s3:PutEncryptionConfiguration`.
- The compute module required IAM role and instance-profile lifecycle permissions.
- RDS-managed credentials required additional Secrets Manager and KMS permissions.
- The destroy workflow initially failed because the live apply-role trust policy allowed `environment:dev` but not `environment:dev-destroy`.

## How I Fixed It

- Restored the deleted IAM roles and policy attachments through Terraform.
- Added the exact S3 encryption action: `s3:PutEncryptionConfiguration`.
- Added the required IAM role, instance-profile, `iam:PassRole`, Secrets Manager, and KMS actions.
- Updated the apply-role trust policy to allow both `environment:dev` and `environment:dev-destroy`.
- Applied the IAM and trust-policy corrections through reviewed Terraform plans.
- Reran the approved apply workflow successfully.
- Reran the protected destroy workflow successfully.

## Evidence and Result

- The first pre-approval plan reported `44 create`, `1 update`, and `0 delete` actions.
- After the partial apply was saved to remote state, the next plan reported only `8 create`, `0 update`, and `0 delete` actions.
- The protected apply completed successfully from the exact approved commit.
- The protected destroy completed successfully with:

```text
Apply complete! Resources: 0 added, 0 changed, 45 destroyed.