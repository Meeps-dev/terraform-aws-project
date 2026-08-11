# Day 72: Linting, tests, coverage, migrations and build artifact

## What I Learned

- Learned how to split CI into separate `lint`, `test`, `migration-check`, `security-check`, and `package` jobs.
- Learned how independent jobs run in parallel while `needs` controls when the package job starts.
- Used Ruff for linting and formatting checks.
- Used `pytest-cov` to measure the existing test coverage before setting a coverage threshold.
- Learned how isolated test databases prevent CI tests from affecting local or production data.
- Used Alembic to validate database migrations against a clean PostgreSQL database.
- Used `pip-audit` to identify vulnerable Python dependencies.
- Learned how workflow artifacts store test reports, coverage reports, and commit-specific ZIP deployment packages.

- Initial measured coverage: 98%
- Initial enforced threshold: 98%
- The threshold was based on measured coverage, not an arbitrary target.

## What Broke

- The test job failed with:

```text
relation "users" does not exist
```

- The test database did not contain the required `users` and `posts` tables before pytest executed.
- There was no `tests/conftest.py` file to prepare the database schema for the test session.
- The dependency security job failed because vulnerable package versions were present.
- Starlette was a transitive FastAPI dependency, so upgrading it independently created compatibility concerns.
- Additional vulnerable versions were detected in `click`, `idna`, `Mako`, `pytest`, and `python-dotenv`.

## How I Fixed It

- Created `tests/conftest.py`.
- Imported the application models before database setup.
- Used `Base.metadata.create_all(bind=engine)` to create the test tables before pytest executed.
- Kept Alembic validation in the separate `migration-check` job so test setup did not replace migration testing.
- Upgraded compatible vulnerable dependencies:

```text
click: 8.3.1 → 8.3.3
idna: 3.11 → 3.15
Mako: 1.3.10 → 1.3.12
pytest: 9.0.2 → 9.0.3
python-dotenv: 1.2.1 → 1.2.2
```

- Upgraded FastAPI and Starlette together to compatible fixed versions instead of changing Starlette alone.
- Reran linting, tests, coverage, migration validation, and `pip-audit` after the dependency changes.

## Result

The CI pipeline could validate code quality, run database-dependent tests, measure coverage, check migrations, audit dependencies, and prepare the application artifact through separate quality-gate jobs. This supports Week 11’s requirement to add lint, test, build, security, and pipeline-debugging automation.
