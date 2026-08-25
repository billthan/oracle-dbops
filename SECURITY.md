# Security Policy

## Reporting a vulnerability

Please do **not** open a public issue for security problems.

Report vulnerabilities through
[private vulnerability reporting](https://github.com/billthan/oracle-dbops/security/advisories/new)
on the **Security** tab. Include the affected script, the Oracle version you ran
it against, and the steps needed to reproduce the problem.

You can expect an initial response within 14 days.

## Scope

These scripts are run interactively by a DBA against a live database and write
files to server-side Oracle `DIRECTORY` objects. Reports about the following are
in scope:

* Unintended privilege escalation or SQL injection in the exported PL/SQL.
* Writing files outside the configured `DIRECTORY` objects.
* Credentials or other secrets leaking into exported DDL, `summary.txt`, or
  `error_log.txt`.

## Handling exported DDL

The exported DDL is intended to be committed to a repository, so treat every
export as untrusted content before pushing it:

* Oracle emits `IDENTIFIED BY VALUES '...'` password hashes for users and
  `CREATE DATABASE LINK ... IDENTIFIED BY ...` clauses in clear text. Scrub these
  before committing.
* `export_grants.sql` and `export_roles.sql` reproduce the full privilege model
  of the database. Review who can read the repository before publishing them.
* `error_log.txt` is git-ignored because it can contain database error text with
  object and schema details.

Secret scanning push protection (see [README](README.md#security)) is the
backstop for this, not a replacement for reviewing what you commit.

## Automated security checks

| Feature | Where it is configured |
| --- | --- |
| Code scanning (CodeQL) | [`.github/workflows/codeql.yml`](.github/workflows/codeql.yml) |
| Dependabot version updates | [`.github/dependabot.yml`](.github/dependabot.yml) |
| Secret scanning and push protection | Repository **Settings → Advanced Security** |
| Private vulnerability reporting | Repository **Settings → Advanced Security** |
