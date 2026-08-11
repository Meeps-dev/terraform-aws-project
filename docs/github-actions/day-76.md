# Day 76: FastAPI Deployment to Private EC2

## What I Did

- Created a CD workflow that runs after successful CI on `main`.
- Used the protected `dev` GitHub Environment and AWS OIDC deployment role.
- Packaged the FastAPI application as an immutable commit-SHA artifact.
- Uploaded the ZIP file and checksum to the private versioned S3 deployment bucket.
- Used AWS Systems Manager Run Command to deploy to the private EC2 instance.
- Configured release directories, a `current` symlink, systemd, Alembic migrations, health checks, and rollback handling.
- Separated packaging, deployment, health-check, rollback, and systemd assets into version-controlled files.
- Added ALB, users, and posts smoke-test steps.

## What I Learned

- A `workflow_run` deployment condition evaluates the original CI event.
- A manually triggered CI run uses `workflow_dispatch`, not `push`.
- SSM transport can work correctly even when the remote deployment command fails.
- URL-encoded database passwords can contain `%`, which Alembic treats as interpolation syntax.
- Database migrations must be safe, repeatable, and must not accidentally remove existing tables.
- A new immutable artifact must be built after code changes; an old deployment artifact cannot contain the fix.

## What Broke

- CI passed, but the CD job was skipped because the source CI run used `workflow_dispatch` while `deploy-dev.yml` required a `push` event.
- The SSM deployment failed during `alembic upgrade head`.
- The RDS password contained URL-encoded `%` characters, causing Alembic `ConfigParser` interpolation errors.
- An existing migration incorrectly attempted to remove the `users` and `posts` tables.
- EC2 virtual-environment permissions and first-deployment rollback handling also required correction.

## How I Fixed It

- Triggered deployment from a fresh push to `main` instead of manually rerunning the CI workflow.
- Escaped `%` safely before passing `DATABASE_URL` into Alembic configuration.
- Loaded all application models into Alembic metadata.
- Corrected the destructive migration so it no longer drops the application tables.
- Added an idempotent repair migration for environments with missing `users` or `posts` tables.
- Corrected EC2 virtual-environment permissions and first-deployment rollback logic.
- Added a regression test for percent-encoded database credentials.
- Refactored deployment assets into `scripts/package.sh`, `scripts/deploy.sh`,
  `scripts/health-check.sh`, `scripts/rollback.sh`, and
  `deploy/users-posts-api.service`.

## Verification

- `7` tests passed.
- Coverage reached `98.21%`.
- Ruff linting and formatting passed.
- Shell syntax checks passed.
- A blank database upgraded successfully to the latest migration.
- `alembic check` reported no schema drift.
- The repair migration successfully restored missing application tables.

## Result

The Day 76 deployment flow was corrected so a fresh successful CI run on `main` can build a new immutable artifact and deploy it through S3, OIDC, SSM, systemd, Alembic, the ALB, and the private RDS database. Final live deployment evidence should be recorded from the new successful CD run.
