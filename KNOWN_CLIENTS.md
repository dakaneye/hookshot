# Known Clients

Repos under `dakaneye/` that consume hookshot workflows and actions, distributed via the [`dakaneye/.github`](https://github.com/dakaneye/.github) sync engine.

## Distribution Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      dakaneye/.github                           │
│                      (sync engine)                              │
│                                                                 │
│  Runs weekly + on push to main                                  │
│  Detects ecosystem per repo (go.mod, package.json, pyproject)   │
│  Seeds thin caller workflows via PR                             │
│  Enforced: community health files, rulesets, dependabot         │
│  Seed-only: CI callers, scan, codeql (created once, not updated)│
└──────────────┬──────────────────────────────────────────────────┘
               │ seeds caller workflows pointing to:
               ▼
┌─────────────────────────────────────────────────────────────────┐
│                     dakaneye/hookshot                            │
│                  (reusable workflows + actions)                  │
│                                                                 │
│  Workflows (workflow_call):                                     │
│    go-ci.yml       — build, test, lint, tidy                    │
│    node-ci.yml     — install, build, test                       │
│    python-ci.yml   — install, lint, typecheck, test             │
│    scan.yml        — grype vulnerability scan                   │
│    codeql.yml      — CodeQL security analysis                   │
│    dependabot-auto-merge.yml — auto-merge minor/patch PRs       │
│                                                                 │
│  Actions (composite):                                           │
│    cosign-releases — keyless Sigstore signing of release assets  │
│    release-pilot   — AI-powered release orchestration           │
│    release-pilot/setup — install CLI only                       │
└──────────────┬──────────────────────────────────────────────────┘
               │ called by consumer repos via:
               │   uses: dakaneye/hookshot/.github/workflows/<wf>@v1
               │   uses: dakaneye/hookshot/<action>@v1
               ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Consumer Repos                              │
│                                                                 │
│  Each has thin caller workflows (~10 lines) that delegate       │
│  to hookshot. Updates to CI logic propagate automatically       │
│  through the @v1 tag without touching consumer repos.           │
└─────────────────────────────────────────────────────────────────┘
```

## Client Inventory

### Go Repos

| Repo | Hookshot Workflows | Special Inputs | Notes |
|------|--------------------|----------------|-------|
| `release-pilot` | go-ci, dependabot-auto-merge, scan, codeql | — | Also uses release-pilot action (dogfood) |
| `claude-sandbox` | go-ci, dependabot-auto-merge, scan, codeql | — | Has custom container-scan job in existing CI |
| `org-pulse` | go-ci, dependabot-auto-merge, scan, codeql | — | |
| `kora` | go-ci, dependabot-auto-merge, scan, codeql | — | Existing CI runs on macos-latest (hookshot uses ubuntu) |
| `claude-session-manager` | go-ci, dependabot-auto-merge, scan, codeql | — | |

### Node Repos

| Repo | Hookshot Workflows | Special Inputs | Notes |
|------|--------------------|----------------|-------|
| `copilot-overlay` | node-ci, dependabot-auto-merge, scan, codeql | `skip-test: true` | Tests in native-host/, not root |
| `copilot-money-mcp` | node-ci, dependabot-auto-merge, scan, codeql | `apt-packages: "libsecret-1-dev"` | Native module dependency |

### Other Repos

| Repo | Hookshot Workflows | Notes |
|------|--------------------|-------|
| `word-clock` | scan, codeql | Arduino project, no CI workflow from hookshot |
| `claude-skills` | scan | YAML/markdown only, no language-specific CI |
| `dakaneye.dev` | scan | Hugo site, no CI workflow from hookshot |

## Migration Status

Hookshot callers are distributed as **seed-only** files — created if missing, never overwritten. Consumer repos that already have a `ci.yml` keep their existing workflow. Migration to hookshot callers is manual per-repo.

| State | Meaning |
|-------|---------|
| **Seeded** | Sync engine created the hookshot caller workflow via PR |
| **Adopted** | Repo merged the caller and removed or archived its old inline CI |
| **Pending** | Sync engine has a PR open waiting for merge |
| **Not applicable** | No hookshot workflow matches this repo's ecosystem |

| Repo | go-ci | node-ci | python-ci | scan | codeql | auto-merge | Status |
|------|-------|---------|-----------|------|--------|------------|--------|
| release-pilot | Pending | — | — | Existing | Existing | Pending | PR #10 |
| org-pulse | Pending | — | — | Existing | Existing | Pending | PR #11 |
| copilot-overlay | — | Pending | — | Existing | Existing | Pending | PR #7 |
| claude-sandbox | Not seeded | — | — | Existing | Existing | Not seeded | Sync PR blocked |
| kora | Not seeded | — | — | Existing | Existing | Existing | Sync PR blocked |
| copilot-money-mcp | — | Not seeded | — | Existing | Existing | Not seeded | Sync PR blocked |
| claude-session-manager | Not seeded | — | — | Existing | Existing | Not seeded | Sync PR blocked |
| claude-skills | — | — | — | Existing | — | Not seeded | No language CI |
| word-clock | — | — | — | Existing | Existing | Not seeded | Arduino, no hookshot CI |
| dakaneye.dev | — | — | — | Existing | — | Not seeded | Hugo site |

## Workflow Inputs Reference

All inputs are optional with sensible defaults. Only document non-default usage here.

### Shared Inputs (all CI workflows)

| Input | Type | Default | Purpose |
|-------|------|---------|---------|
| `skip-test` | boolean | false | Skip the test step entirely |
| `skip-lint` | boolean | false | Skip the lint step entirely |
| `apt-packages` | string | "" | Space-separated apt packages to install |

### go-ci.yml

| Input | Type | Default |
|-------|------|---------|
| `go-version` | string | "" (reads go.mod) |
| `lint-version` | string | "latest" |
| `run-race` | boolean | true |
| `codecov` | boolean | false |

### node-ci.yml

| Input | Type | Default |
|-------|------|---------|
| `node-version` | string | "22" |
| `build-command` | string | "npm run build" (empty to skip) |
| `test-command` | string | "npm test" |

### python-ci.yml

| Input | Type | Default |
|-------|------|---------|
| `python-version` | string | "3.12" |
| `test-command` | string | "pytest -v --tb=short" |
| `lint` | boolean | true |
| `typecheck` | boolean | false |
| `codecov` | boolean | false |
