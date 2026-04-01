# Contributing

Contributions are welcome! Here's how to get started.

## Reporting Issues

Open an issue for bugs, feature requests, or questions.

## Pull Requests

1. Fork the repo and create your branch from `main`
2. Make your changes
3. Ensure all workflow YAML passes [actionlint](https://github.com/rhysd/actionlint)
4. Open a pull request

## Development

This repo is YAML and bash only. To validate workflows locally:

```sh
# Install actionlint
go install github.com/rhysd/actionlint/cmd/actionlint@latest

# Run validation
actionlint
```

## Action SHA Pinning

All GitHub Actions must be pinned to full 40-character commit SHAs with a version comment:

```yaml
# Good
uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2

# Bad
uses: actions/checkout@v6
```

To find the SHA for a release:

```sh
gh api repos/OWNER/ACTION/git/refs/tags/vX.Y.Z --jq '.object.sha'
```
