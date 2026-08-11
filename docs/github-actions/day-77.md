# Day 77: Pipeline Hardening, Documentation and Teardown

## What I Did

- Audited both repositories for AWS keys, database passwords, `.env` files, and other committed secrets.
- Verified the GitHub OIDC trust policies, separate plan/apply/deploy roles, limited token permissions, and protected `dev` environments.
- Confirmed Terraform state remained private, encrypted, versioned, and protected by native S3 state locking.
- Reviewed CloudTrail records for GitHub OIDC role assumptions and AWS activity.
- Added lifecycle and cleanup controls for old deployment artifacts.
- Completed the Week 11 failure-engineering, security, cost, and troubleshooting documentation.
- Disabled EC2 deployment after testing to prevent deployments to deleted infrastructure.
- Ran the protected Terraform destroy workflow and verified the development resources were removed.
- Retained the Terraform state bucket, GitHub OIDC provider, and IAM pipeline roles for later weeks.
- Reviewed Cost Explorer and AWS Budgets for remaining charges.

## What I Learned

- CI/CD security requires layered controls: OIDC, least privilege, approvals, exact commits, state locking, and audit logs.
- Plan, apply, destroy, and application deployment jobs should use separate permissions.
- Versioned S3 buckets may retain noncurrent versions and delete markers after normal object deletion.
- Infrastructure teardown should be treated as a protected deployment operation, not an uncontrolled local command.
- Separating bootstrap state from application-infrastructure state allows OIDC roles and remote state to survive environment teardown.
- CloudTrail role-session records provide evidence of who accessed AWS, which role was assumed, and when the action occurred.

## What Broke or Was Exposed

- The security audit found that application configuration still allowed a hardcoded local database-password fallback.
- Old versioned deployment artifacts could prevent Terraform from deleting an S3 bucket with `force_destroy = false`.
- The deployment workflow could continue triggering after EC2 teardown unless an explicit deployment switch was added.
- Workflow actions using movable version tags were less tamper-resistant than full commit-SHA references.

## How I Fixed It

- Removed the hardcoded database credential fallback and required `DATABASE_URL` to come from the environment.
- Confirmed `.env` remained ignored and kept runtime credentials in AWS Secrets Manager.
- Added S3 lifecycle and explicit object-version cleanup before teardown.
- Added a deployment enable/disable control and disabled EC2 CD after the lab.
- Hardened workflow permissions and recorded the requirement to pin third-party actions to immutable commit SHAs.
- Used the protected destroy workflow with approval, OIDC, concurrency control, and native state locking.
- Verified EC2, ALB, target groups, RDS, NAT, and temporary application resources were removed.

## Result

Week 11 ended with a hardened, documented, auditable, and cost-aware CI/CD platform. Temporary development infrastructure was removed to prevent billing surprises, while the reusable Terraform state backend, GitHub OIDC provider, and least-privilege IAM roles were retained for the next stages of the roadmap.