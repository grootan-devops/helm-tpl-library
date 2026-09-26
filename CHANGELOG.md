# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
