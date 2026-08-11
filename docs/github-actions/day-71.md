# Day 71: CI/CD Fundamentals and First GitHub Actions Workflow

## What I Learned

- Learned the difference between **Continuous Integration**, **Continuous Delivery**, and **Continuous Deployment**.
- Learned how GitHub Actions workflows are structured using YAML, jobs, steps, actions, and shell commands.
- Configured `push`, `pull_request`, and `workflow_dispatch` triggers.
- Used a GitHub-hosted Ubuntu runner with Python 3.12.
- Used `${{ github.sha }}` to identify the exact commit being tested.
- Learned how to inspect workflow logs and trace failures to the correct step.
- Learned that GitHub runners are clean environments and do not contain my local packages, database, or environment variables.
- Learned how PostgreSQL service containers provide temporary databases for CI testing.
- Learned that Alembic migrations must run before database-dependent tests.

## What Broke

- The workflow failed because `needs: checkout` referenced a step instead of an existing job.
- Tests failed with `Connection refused` because PostgreSQL was not running inside the GitHub Actions runner.
- The application used a hardcoded database connection instead of the CI `DATABASE_URL`.
- The `users` and `posts` tables did not exist because migrations had not been applied.
- FastAPI `TestClient` failed because the `httpx` package was missing.
- Alembic failed with `fe_sendauth: no password supplied` while connecting through `localhost`.

## How I Fixed It

- Removed the invalid `needs: checkout` dependency.
- Added a PostgreSQL 15 service container to the CI workflow.
- Updated `app/database.py` and `alembic/env.py` to read `DATABASE_URL` from environment variables.
- Added `alembic upgrade head` before running pytest.
- Added `httpx` and `pytest` to the declared dependencies.
- Changed the PostgreSQL host from `localhost` to `127.0.0.1` to use the expected IPv4 connection.
- Reviewed each failed workflow log, applied targeted fixes, committed the changes, and reran the pipeline.

## Result

The GitHub Actions workflow successfully configured Python 3.12, installed dependencies, started PostgreSQL, applied Alembic migrations, and executed the FastAPI test suite in a clean CI environment. This completed the initial Week 11 test-workflow and pipeline-debugging exercise.
