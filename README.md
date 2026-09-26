# Helm tpl Library

[Compatibility](https://github.com/grootan-devops/ai-skills/blob/main/COMPATIBILITY.md) · [Security](./SECURITY.md) · [Reporting policy](./CONTRIBUTING.md)

![Version: 1.3.0](https://img.shields.io/badge/Version-1.3.0-informational?style=flat-square) ![Type: library](https://img.shields.io/badge/Type-library-informational?style=flat-square) ![AppVersion: 1.3.0](https://img.shields.io/badge/AppVersion-1.3.0-informational?style=flat-square)

Helm tpl library for helm chart

## Quick start

Use `tpl-library` as a dependency of an application chart; it is not installed directly.
Follow the [usage guide](docs/usage.md) for registry authentication and setup.

```yaml
dependencies:
  - name: tpl-library
    version: 1.3.0
    repository: oci://registry-1.docker.io/grootantech
```

## Documentation

| Task | Read |
| --- | --- |
| Add the library dependency and authenticate | [Usage](docs/usage.md) |
| Structure a consumer chart and document its values | [Chart standards](docs/chart-standards.md) |
| Select template entrypoints and derive resource names | [Templates and naming](docs/templates.md) |
| Configure mounts, persistent storage, secrets and schema | [Configuration and storage](docs/configuration.md) |
| Look up a value, its type or default | [Generated values reference](docs/values/README.md) |
| Test this library or a consumer chart | [Testing](docs/testing.md) |
| Upgrade an existing consumer | [Migration guide](MIGRATION.md) · [Changelog](CHANGELOG.md) |

For AI-assisted work, read this index first and follow only the relevant topic links.
Resolve links against the same branch, tag or local checkout; do not load all guides by default.

## Requirements

- Helm: `>=3.2.0`
- Kubernetes: `>=1.27`

## Maintaining documentation

Edit the topic guides directly. Edit `README.gotmpl`, `docs/values/README.gotmpl`
and `values.yaml` for generated content, then run `make docs` and `make docs-check`.

## License

Copyright 2026 Grootan Technologies Pvt Ltd.

Licensed under the [GNU Affero General Public License v3.0](./LICENSE.md)
(`AGPL-3.0-only`). External contributions are not accepted; see
[CONTRIBUTING.md](./CONTRIBUTING.md) for bug and security reporting.
