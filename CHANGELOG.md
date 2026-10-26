# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0] - 2026-10-27

### Added

- `docs/chart-contract.json`: the consumer-chart rules of this release (manifest, README, helm-docs flags, `.helmignore` entries, chart names, optional blocks, placeholders, mounts, schema enums), for audit tools to read at the version a chart pins. It ships inside the packaged chart.
- `docs/maintainer-guide.md`: release steps, the versioning and deprecation policy, and how to keep the chart contract in step with the rules.
- `kubeVersion: ">=1.27.0-0"` in `Chart.yaml`, so the requirements line is generated.

### Changed

- The README drops its link to the ai-skills compatibility page: this library documents its own versioning. Its AI reading notes are a section that says which release to read and names the chart contract.
- The Helm requirement is `>=3.8.0`, the first release that resolves `oci://` dependencies; `>=3.2.0` could not install the documented dependency.
- Example dependency pins in `docs/usage.md` and `docs/chart-standards.md` are `<version>` instead of a release that every release had to edit.
- Pull request verification publishes its candidate as `<version>-<run>.<pr>`. It published the bare release version to the release repository, where a consumer could pin it before the release.

### Fixed

- `docs/chart-standards.md`: the consumer `.helmignore` baseline excludes `tests/`, where helm-unittest suites live, not `test/`. The `# @default -- Check values.yaml` list names the blocks `values.yaml` marks (`strategy`, the container and pod `securityContext`), and the container example matches `values.yaml`, with the non-root identity on `pod.securityContext`.
- `docs/testing.md`: helm-unittest snapshots are not committed, so the full-render suite proves the render succeeds rather than that it is unchanged.
- `values.yaml`: the liveness probe example is headed as an example and named `liveness:`, and `service.default` loses the `# --` line the comments law forbids on a parent key.
- `example.yaml`: `releaseNameLength` is the length of its `partOf`, and a comment's `incude` is `include`.
- `.gitignore`: drops the `test/` entries and the `make deps` target, which no longer exist.

## [1.4.0] - 2026-10-01

### Added

- Documented consumer chart naming (`<partOf>-<component>[-<subComponent>]`), the derived resource names and how to choose container keys in `docs/templates.md`.
- Documented mounts (`enabled`, `mountTo`, runtime-writable paths), file mounts with a SPA server config, routes, rendering behaviour, credential grouping, consumer schema guidance and the chart security posture in `docs/configuration.md`.
- Documented the chart description and `README.gotmpl`, the values replica rule, application values, comment rules for `jobs`, `cronjobs` and `persistence` leaves, empty `command`/`args`, several releases from one chart, probes, renames and ignore files in `docs/chart-standards.md`.

### Changed

- Extended the sensitive-data standard to every container, job, cronjob and overlay, and to `env` values and `args`.
- The `jobs:` example in `values.yaml` selects its task with `MODE` instead of `command`/`args`.

## [1.3.0] - 2026-09-25

### Added

- Added `tpl.container.image.repository` helper to dynamically compute `{global.partOf}/{component}/{subComponent}` when `image.repository` is empty or omitted.

### Changed

- Refined template invocation examples in `docs/templates.md` to prevent template delimiter collisions.
- Pinned repository CI reusable workflow callers to `github-ci-library` `@1.3.1`.

## [1.2.0] - 2026-09-23

### Changed

- Rename the mock consumer chart directory from `test/` to `tests/`, update CI and guide
  references, and select its nested unit-test suite explicitly.
- Split chart guidance into focused topic guides and a separately generated values reference.
- Keep the README as a task index and add deterministic documentation generation and drift checks.

## [1.1.0] - 2026-09-22

### Changed

- Pinned GitHub Actions reusable workflows to `github-ci-library` 1.0.0.
- Updated chart metadata, consumer documentation, and Helm package exclusions.

## [1.0.0] - 2026-09-19

### Added

- Initial public release.
