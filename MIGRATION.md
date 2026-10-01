# Migration Guide

This document records required consumer actions when upgrading between releases.
Breaking changes must include an entry before release.

To upgrade, apply every section after your pinned version up to the target, oldest first.
Newer sections are split into **Required** (the upgrade breaks or misbehaves without it),
**Recommended** (aligns an existing chart with the current standards) and **Verify**.

## 1.4.0

### Required

No migration required. The templates and the values contract are unchanged; only the
commented `jobs:` example in `values.yaml` changed, and this release documents the chart
standards in full.

### Recommended

Align an existing consumer chart with the documented standards:

- `command` and `args` stay `[]` for the chart's own image, in every container, job and overlay;
  a job selects its task through the image, for example a `MODE` variable.
- Every entry under `mounts.configmap`, `mounts.secret`, `mounts.emptyDir` and `mounts.pvc`
  states `enabled: true`; an entry without it renders nothing.
- A file the application reads at runtime is a file mount under `mounts:`, not a file built
  into the image or a hand-written ConfigMap template.
- Credentials sit under an `auth:` sub-map of their group and reach the container only through
  `secretEnvs`, never `configmapEnvs`, `env` values or `args`.
- The consumer schema lists every `mode` and `subComponent` value with no empty entry, and puts
  no `minLength` on a key whose default is `""`.

### Verify

- `helm lint --strict` and `helm template` pass on `values.yaml` and on each overlay.

## 1.3.0

No breaking changes. Workloads may now leave `.Values.containers.<name>.image.repository` empty to automatically derive the standard `{global.partOf}/{component}/{subComponent}` image repository path. Explicit repository values remain fully supported.

## 1.2.0

No consumer configuration changes are required. Start at the README index and follow its
task-specific documentation links; update any bookmarks to moved sections. Existing chart templates remain compatible.

## 1.1.0

No migration is required. Existing consumers can continue to use the chart
templates with the new chart version.

## 1.0.0

No migration is required for the initial release.
