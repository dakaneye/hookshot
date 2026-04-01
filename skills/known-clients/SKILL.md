---
name: known-clients
version: 1.0.0
description: Look up which dakaneye/ repos consume hookshot workflows and actions, their ecosystems, required inputs, and migration status. Use PROACTIVELY before modifying any reusable workflow or action — changes here propagate to all consumers via the @v1 tag. Also use when adding new workflows, changing inputs, or planning rollouts. Trigger on "who uses this", "what repos call go-ci", "blast radius", "which repos need apt-packages", "consumer repos", "client repos", or any question about downstream impact.
---

# Known Clients

When you modify a hookshot workflow or action, those changes propagate to every consumer repo the next time their CI runs (they pin to `@v1`). This skill tells you who those consumers are so you can assess impact before pushing.

## How to find current client data

Client data changes as repos adopt or customize hookshot callers. Always verify against live state rather than relying on cached information.

### Quick: check which repos reference hookshot

```bash
# Find all repos with hookshot caller workflows
for repo in $(gh repo list dakaneye --visibility=public --no-archived --limit 50 \
  --json name,isFork --jq '.[] | select(.isFork == false) | .name'); do
  workflows=$(gh api "repos/dakaneye/${repo}/contents/.github/workflows" \
    --jq '[.[].name]' 2>/dev/null || echo "[]")
  for wf in $(echo "$workflows" | jq -r '.[]'); do
    content=$(gh api "repos/dakaneye/${repo}/contents/.github/workflows/${wf}" \
      --jq '.content' 2>/dev/null | base64 -d 2>/dev/null)
    if echo "$content" | grep -q 'hookshot' 2>/dev/null; then
      echo "${repo}: ${wf}"
    fi
  done
done
```

### Quick: check pending sync PRs

```bash
# PRs from the .github sync engine that would add hookshot callers
for repo in $(gh repo list dakaneye --visibility=public --no-archived --limit 50 \
  --json name,isFork --jq '.[] | select(.isFork == false) | .name'); do
  pr=$(gh pr list -R "dakaneye/${repo}" --state open \
    --json number,title --jq '.[] | select(.title | contains("sync")) | "#\(.number)"' 2>/dev/null)
  [[ -n "$pr" ]] && echo "${repo}: ${pr}"
done
```

## Distribution architecture

```
dakaneye/.github (sync engine)
    │ detects ecosystem (go.mod, package.json, pyproject.toml)
    │ seeds thin caller workflows via PR (seed-only: created once, never overwritten)
    ▼
dakaneye/hookshot (this repo)
    │ reusable workflows: go-ci, node-ci, python-ci, scan, codeql, dependabot-auto-merge
    │ composite actions: cosign-releases, release-pilot, release-pilot/setup
    ▼
consumer repos
    call via: uses: dakaneye/hookshot/.github/workflows/<wf>@v1
    or:       uses: dakaneye/hookshot/<action>@v1
```

Callers are **seed-only** — the sync engine creates them but never overwrites. Repos can customize inputs after the initial seed PR merges.

## Ecosystem mapping

The sync engine seeds CI callers based on detected ecosystem:

| Ecosystem | Detection | Seeded caller |
|-----------|-----------|---------------|
| Go | `go.mod` exists | `go-ci.yml` |
| Node | `package.json` exists | `node-ci.yml` |
| Python | `pyproject.toml` or `setup.py` exists | `python-ci.yml` |
| All | always | `dependabot-auto-merge.yml`, `scan.yml` |
| Public only | not private | `codeql.yml` |

## Known input overrides

Some repos need non-default inputs. When modifying workflow inputs, check these don't break:

| Repo | Workflow | Override | Reason |
|------|----------|----------|--------|
| copilot-overlay | node-ci | `skip-test: true` | Tests in native-host/, not root |
| copilot-money-mcp | node-ci | `apt-packages: "libsecret-1-dev"` | Native module dependency |

## Impact checklist

Before pushing a workflow change:

1. **Input changes** — Is any input being renamed or removed? Check the overrides table above.
2. **Default changes** — Is a default value changing? Every consumer using the default is affected.
3. **New required inputs** — This breaks all existing callers. Add as optional with a default instead.
4. **Step removal** — A step that consumers depend on (e.g., coverage upload) can't be removed without checking who uses it.
5. **Action version bumps** — Bumping a pinned action SHA is safe (consumers inherit it), but major version bumps may change behavior.
