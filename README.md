# hookshot

Reusable GitHub Actions workflows and composite actions for CI/CD.

## Reusable Workflows

| Workflow | Description | Usage |
|----------|-------------|-------|
| `go-ci.yml` | Go build, test, lint, tidy | `uses: dakaneye/hookshot/.github/workflows/go-ci.yml@v1` |
| `node-ci.yml` | Node.js install, build, test | `uses: dakaneye/hookshot/.github/workflows/node-ci.yml@v1` |
| `python-ci.yml` | Python install, lint, typecheck, test | `uses: dakaneye/hookshot/.github/workflows/python-ci.yml@v1` |
| `dependabot-auto-merge.yml` | Auto-merge Dependabot minor/patch PRs | `uses: dakaneye/hookshot/.github/workflows/dependabot-auto-merge.yml@v1` |
| `scan.yml` | Grype vulnerability scan | `uses: dakaneye/hookshot/.github/workflows/scan.yml@v1` |
| `codeql.yml` | CodeQL security analysis | `uses: dakaneye/hookshot/.github/workflows/codeql.yml@v1` |

## Composite Actions

### cosign-releases

Sign all GitHub Release assets with keyless Sigstore signing.

```yaml
- uses: dakaneye/hookshot/cosign-releases@v1
  with:
    release-tag: ${{ github.ref_name }}
```

### release-pilot

AI-powered release orchestration.

```yaml
- uses: dakaneye/hookshot/release-pilot@v1
  with:
    anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
```

Setup-only (install CLI without running):

```yaml
- uses: dakaneye/hookshot/release-pilot/setup@v1
```

## Workflow Examples

### Go project

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
jobs:
  ci:
    uses: dakaneye/hookshot/.github/workflows/go-ci.yml@v1
    with:
      codecov: true
    secrets:
      codecov-token: ${{ secrets.CODECOV_TOKEN }}
```

### Release with signing

```yaml
name: Release
on:
  push:
    tags: ["v*"]
permissions:
  contents: write
  id-token: write
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - uses: dakaneye/hookshot/release-pilot@v1
        with:
          anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
          sign: "true"
      - uses: dakaneye/hookshot/cosign-releases@v1
        with:
          release-tag: ${{ github.ref_name }}
```

## License

MIT
