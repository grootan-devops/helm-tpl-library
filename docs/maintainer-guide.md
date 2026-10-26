# Maintainer guide

## Releases

`Chart.yaml` holds the release: `version` and `appVersion` are the same, and a merge to `main`
tags that version, publishes a GitHub release and pushes the chart to
`oci://registry-1.docker.io/grootantech`. A pull request that ships a change:

1. bumps `version` and `appVersion` in `Chart.yaml`, and the `tpl-library` dependency of the
   mock consumer in `tests/Chart.yaml`;
2. adds a [`CHANGELOG.md`](../CHANGELOG.md) entry and a [`MIGRATION.md`](../MIGRATION.md)
   section split into Required, Recommended and Verify, even when nothing is required;
3. runs `make docs` after any change to `values.yaml`, `README.gotmpl` or
   `docs/values/README.gotmpl`, and `make verify` before pushing.

The pull request checks reject a version or tag that already exists, a missing changelog or
migration section and an unpinned reusable workflow, then lint the chart and run the
helm-unittest suites. A pull request publishes a candidate as `<version>-<run>.<pr>`; only the
merge publishes `<version>` itself, so a consumer never pins a candidate by accident. Example
pins in the docs are `<version>`: they show syntax and never need a release bump.

## Versioning

Releases follow semantic versioning for the public interface:

- the value keys and what they render, including their defaults;
- the `tpl.*` entrypoints and the context parameters they take;
- every name the templates derive (resources, containers, env ConfigMaps and Secrets, claims)
  and the labels they set;
- [`docs/chart-contract.json`](chart-contract.json).

Patch and minor releases stay backward compatible within a major version. A breaking change
needs a new major version and a Required migration step. A change to a derived name is
breaking even when every value still renders: it renames claims and Services, so a consumer
gets a new, empty volume. A deprecated key or alias, such as `subcomponent`, root `partOf` or
`global.ingress.*`, keeps working for at least the next minor release and is announced in the
changelog and the migration guide before it goes. A page describes the release it ships in:
history belongs in the changelog and migration guide.

## Chart contract

[`docs/chart-contract.json`](chart-contract.json) is the machine-readable form of the
consumer-chart rules in [Chart standards](chart-standards.md),
[Templates and naming](templates.md) and [Configuration](configuration.md). Audit tools read
it at the version a chart pins and refuse a version without it, so change it in the same
commit as the rule or template:

- `manifest`, `readme`, `helmDocs`, `helmignore` and `chartNames`: the files a consumer chart
  carries, how they are generated and how the chart is named.
- `values.optionalBlocks`: each optional block and the entrypoints that render it; an empty
  list means no template reads the block.
- `values.placeholders`: keys whose defaults in `values.yaml` are placeholders a consumer must
  replace. The placeholder values themselves stay in `values.yaml`.
- `values.exampleMaps`, `values.applicationValues`, `values.documentedLeaves`,
  `values.mountsNeedEnabled`, `values.schemaEnums` and `values.templateKeys`: the replica,
  ordering, documentation, mount, schema and naming rules of the values file.

The file holds only what a reader checks. Names that are part of the public interface, such
as `values.<release>.yaml` overlays and the `tpl.*` entrypoints, are documented in the guides
and stay stable within a major version.

The file ships inside the packaged chart, so a consumer's resolved dependency carries the rules
of exactly the version it renders with. `schema` is the version of this contract. Raise it when
a change to the file's shape, or to a key or entrypoint it names, would make an older reader
misjudge a chart: readers refuse a schema they do not know instead of guessing.

[Documentation index](../README.md)
