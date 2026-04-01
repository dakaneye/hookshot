# Hookshot

Reusable GitHub Actions workflows and composite actions for all `dakaneye/` repos.

## Architecture

- **Reusable workflows** live in `.github/workflows/` with `on: workflow_call` triggers
- **Composite actions** live in top-level directories (`cosign-releases/`, `release-pilot/`)
- **Distribution** via `dakaneye/.github` sync engine which seeds thin caller workflows into consumer repos
- **Versioning**: single `v1` floating tag, updated on each release

## Key Files

- `KNOWN_CLIENTS.md` — which repos use which workflows, migration status, input overrides
- `README.md` — usage examples for external consumers
- `.github/workflows/ci.yml` — hookshot's own CI (actionlint + dogfood scan/codeql)

## Conventions

- All action SHAs pinned to 40-char commits with precise version comments (`# v6.0.2` not `# v6`)
- Workflow inputs from `workflow_call` use `${{ inputs.* }}` directly in `run:` blocks (trusted caller YAML)
- Composite action inputs use `env:` block indirection (untrusted event data possible)
- Bash blocks include `set -Eeuo pipefail`, use `WORK_DIR` not `TMPDIR` (avoids system variable shadowing)

## When Modifying Workflows

1. Push to main (admin bypass is configured)
2. Wait for CI to pass (actionlint + scan + codeql)
3. Update v1 tag: `git tag -f v1 -m "v1: <description>" && git push origin v1 --force`
4. Consumer repos on `@v1` pick up changes automatically
