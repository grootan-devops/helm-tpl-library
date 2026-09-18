# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **BREAKING** — container names are now derived as `<component>[-<subComponent>]-<key>`
  instead of the bare map key, so the `container` label is self-describing in Loki and
  cAdvisor without a collector relabel rule. Init containers additionally carry an `init-`
  prefix. Jobs and CronJobs use the same scheme with no `-job`/`-cronjob` suffix. An
  explicit `name:` on a container still wins outright. The component prefix — never the
  key — is truncated to keep the result inside the 63-character DNS-1123 limit.
- **BREAKING** — the container key `main` is now reserved for the single application
  container under `containers:`. Using it as an init container key, or inside a `jobs:` or
  `cronjobs:` entry, fails the render with a pointed message.

### Added

- `tpl.container.name`: single helper deriving every container name, replacing the
  expression that was duplicated across `_container.tpl`, `_configmaps.tpl` and
  `_secret.tpl`. Validates the result against DNS-1123.

### Fixed

- `_deployment.tpl` now passes `_containerType` to `tpl.configmap.volume` /
  `tpl.secret.volume`, so a `mountTo` of `main` or `init` (a container *type*) matches in
  the object templates as it already did in `_container.tpl` and `_pod.tpl`. Previously the
  pod referenced volumes whose backing ConfigMap/Secret was never created, and would never
  start.

### Added

- `tpl.pvc`: optional entrypoint rendering PersistentVolumeClaims from a new `persistence`
  values section (`enabled`, `storageClass`, `size`, `accessModes`, `volumeMode`,
  `annotations`, `selector`, `existingClaim`). Not called by `tpl.deployment` — include it
  explicitly, like `tpl.job` and `tpl.cronjob`. Closes the gap where `mounts.pvc` mounted a
  claim nothing created, leaving the pod `Pending` while `helm install` reported success.

### Fixed

- `mounts.pvc.<key>.claimName` now honours its documented default. `_pod.tpl` called `tpl`
  on the value before defaulting, and `tpl` errors on nil, so the field was mandatory in
  practice and omitting it failed with `wrong type for value; expected string; got
  interface {}`. Unset now resolves to `<resource name>-<key>`, matching the claim
  `tpl.pvc` creates.

- KEDA Support
- Isito Destination Rule, Envoy Filter, Service Entry, Sidecar Support and Config, PeerAuthentication, RequestAuthentication, Authorization Policy and Telemetry
- Istio Sidecar Metrics PodMonitor

### Added

- Render test suite for the library: `test/` is now a mock consumer chart (`mock-app`)
  driven by helm-unittest, with a scenario matrix under `test/values/` and one suite per
  template under `test/tests/`. Adds a `Makefile` and the `Chart:UnitTest` GitLab job.

### Removed

- The old `test/` scaffolding (a `helm create` chart named `test-app` that depended on a
  nonexistent `tpl-library` v0.0.0 and exercised none of the `tpl.*` defines).

## [1.1.0] - 05-03-2026

### Changed

- Chart push repository path

## [1.0.2] - 05-03-2026

### Fixed

- mounts `mountTo` key is not rendering when templating is used

## [1.0.1] - 24-02-2026

### Fixed

- **Environment Variable Checksum Tracking**: Fixed an issue where `Deployment` rollouts were not triggered by changes in `additionalConfigmapEnvs` or `additionalSecretEnvs`. The checksum logic now accounts for both standard and additional environment maps.
- **Environment Override Priority**: Corrected `tpl.configmap.env` and `tpl.secret.env` to ensure that `additional` variables strictly override default values when keys collide.
- **Dynamic Template Evaluation**: Resolved a limitation where Helm template logic (such as `if`, `eq`, and `range` loops) within environment variable values was not being rendered. Both default and additional maps now support "Double-Pass" template evaluation via the `tpl` function.
- **Map Mutation Bug**: Fixed a potential template instability issue by using `deepCopy` during the `merge` process, preventing the destructive modification of the global `.Values` object during rendering.
- **Empty Value Filtering**: Improved the robustness of `Secret` and `ConfigMap` generation by filtering out empty string values that could lead to invalid Kubernetes manifests.

### Changed

- **Universal Context Passing**: Updated internal `tpl` calls to explicitly pass the global scope (`$`), allowing environment variables to access `$.Values.global` and other top-level attributes from within nested helper functions.
- **Standardized Secret Type**: Explicitly set the `Secret` resource type to `Opaque` to ensure broad compatibility with generic environment variable storage.

## [1.0.0] - 16-02-2026

### Added

- **Breaking Changes**: values structure changed. check examples and values for more info.

## [0.29.0] - 25-06-2025

### Added

- Added support to mount pvc to workload volume's.

## [0.28.1] - 07-05-2025

### Fixed

- Fixed secret template duplicating issue

## [0.28.0] - 19-03-2025

### Added

- Support for sidecar container

## [0.27.1] - 11-07-2024

### Fixed

- Fixed `clusterrole` and  `clusterrolebinding` naming convention by suffixing with the respective namespace.

## [0.27.0] - 22-05-2024

### Changed

- Updated job label to be `app_kubernetes_io_instance` by default.

## [0.26.1] - 02-05-2024

### Fixed

- `MountVolume.SetUp failed for volume` error when mounting configs into main or init alone
- ingress path not render helm values

## [0.26.0] - 18-03-2024

### Changed

- Changed `ingress.*.enabled` from bool to string

## [0.25.0] - 05-03-2024

### Changed

- Updated rbac template by including `clusterrole` and `clusterrolebinding` manifests

## [0.24.2] - 04-03-2024

### Fixed

- Fixed cronjob and job templating

## [0.24.1] - 01-02-2024

### Fixed

- Fixed additional configmap env templating

## [0.24.0] - 27-01-2024

### Removed

- Removed default backend ingress annotation. If required add it manually in ingress annotation section.

## [0.23.0] - 27-01-2024

### Fixed

- Resolved issue where the deployment checksum annotation for secrets and configmaps remained unchanged despite alterations in their values.

### Changed

- YAML structure for certificate creation.
  - Added `.Values.certificate.`

## [0.22.2] - 24-01-2024

### Fixed

- Additional secret env mounting rendering issue.

## [0.22.1] - 24-01-2024

### Fixed

- Deployment port render failure if duplicate port name exist

## [0.22.0] - 24-01-2024

### Changed

- Updated secret env to convert values to b64enc. No need to perform `b64enc`
- Updated configmap env can now accept int. single quote is no longer required for configmapenv too.

## [0.21.0] - 23-01-2024

### Changed

- Updated `revisionHistoryLimit` to `0` by default

## [0.20.8] - 23-01-2024

### Fixed

- servicemonitor and podmonitor is deployed for all deployments.

## [0.20.7] - 23-01-2024

### Fixed

- Podmonitor schema error

## [0.20.6] - 23-01-2024

### Fixed

- length of secret name generation for sa.

## [0.20.5] - 23-01-2024

### Fixed

- same secret name generation for sa token

## [0.20.4] - 23-01-2024

### Fixed

- configmap mount error for containers

## [0.20.3] - 23-01-2024

### Fixed

- missing `subPath` for configmap mount

## [0.20.2] - 22-01-2024

### Fixed

- ingress annotations templating issue
- mount volumes templating issue when `enabled` section is given as bool.

## [0.20.1] - 22-01-2024

### Fixed

- secret and configmap invalid data rendering

## [0.20.0] - 22-01-2024

### Added

- Support for configmap and secret env to get removed on templating when value is empty for respective key.

## [0.19.0] - 18-12-2023

### Changed

- **Breaking changes:** entire values schema is changed to simplify and reduce the chart development stage. Check values.yaml for more example and usage.

## [0.18.2] - 02-12-2023

### Fixed

- **Breaking change:** ingress path tpl function is hacing conflict with tpl name for param `.name`
  - `name` argument is changed to `svcPortNumber`
  - `port` argument is changed to `svcPortName`

## [0.18.1] - 25-11-2023

### Fixed

- resource name tpl function expecting `.name` arguments as mandatory field

## [0.18.0] - 15-11-2023

### Fixed

- Corrected rendering of RBAC service account and secret objects.
- Fixed issue with the creation of the ConfigMap resource, which was only getting created with the -env suffix.

### Added

- Introduced a new template function `tpl.resource.siblingName` to facilitate rendering of Kubernetes services across different Helm releases.

### Changed

- Removed the usage of .Values.component name in `tpl.resource.token.name` and `tpl.resource.name` template functions for better clarity and consistency.

## [0.17.1] - 13-11-2023

### Added

- few files to ignore list at `.helmignore`

## [0.17.0] - 13-11-2023

### Added

- Container `lifecycle` support

### Changed

- **Breaking changes:**
  - `additionalConfigmapMount` is renamed to `envFromConfigmap`
  - `additionalSecretMount` is renamed to `envFromSecret`
  - Resource name now have component name as suffix and if `.name` is used it will be appended in the end of resource name

## [0.16.0] - 12-09-2023

### Added

- Support for templating `image.repository`

## [0.15.0] - 11-09-2023

### Changed

- Improvised chart `README.md`

## [0.14.0] - 24-08-2023

### Changed

- Updated `README.md`

## [0.13.0] - 24-08-2023

### Changed

- Updated comments and generated readme using `readme-generator-for-helm`

## [0.12.0] - 07-08-2023

### Added

- Support for additional secrets and configmap mount

## [0.11.1] - 14-07-2023

### Fixed

- Missing key `partOf` under global section

## [0.11.0] - 22-03-2023

### Changed

- **Breaking Change** image pull policy key from global section to respective chart image section

## [0.10.0] - 08-03-2023

### Added

- Support for service name in ingress tpl function

## [0.9.0] - 16-12-2022

### Added

- Support for multiple prefix path for ingress tpl

## [0.8.0] - 06-12-2022

### Added

- Support for k8s 1.24 where service account secret is no longer created

## [0.7.0] - 26-11-2022

### Changed

- Service annotation to be a mandatory field

## [0.6.3] - 23-11-2022

### Fixed

- certificate rendering in argocd

## [0.6.2] - 15-11-2022

### Fixed

- service monitoring rendering issue.

## [0.6.1] - 26-10-2022

### Fixed

- additonal secret env varible rendering issue

## [0.6.0] - 26-10-2022

### Added

- Support for changing command and args of container
- `startingDeadlineSeconds` and `concurrencyPolicy` will pick from values.yaml for cronjob

### Changed

- serviceaccount as a mandatory field in values.yaml
- InitContianer to be mandatory for all charts

## [0.5.0] - 21-10-2022

### Added

- Added templates for cert-manager certificate
- podAnnotations to deployment
- New tpl function domain.noSubDomain & tpl.ingress.spec.noSubDomain

## [0.4.0] - 19-10-2022

### Changed

- Nginx annotation will now render values of values.

## [0.3.1] - 19-10-2022

### Fixed

- Deployment returning empty annotation when `checksumsecret` and `checksumconfigmap is empty`
- ServiceAnnotation getting rendered always

### Changed

## [0.3.0] - 18-10-2022

### Changed

- Selector label now takes chart name as default if not passed. No longer a mandatory field
- tpl.deployment.template tpl function to access bool for secretChecksum & configmapChecksum key instead of bool string.

### Added

- Added tpl function `tpl.domain` and `tpl.domain.hostLabel` to render host URL with and without hostlabel

### Fixed

- tls hostname not rendering properly if subdomain is not present

### Added

- Added tpl function `tpl.domain` and `tpl.domain.hostLabel` to render host URL with and without hostlabel

### Fixed

- tls hostname not rendering properly if subdomain is not present

## [0.2.3] - 18-10-2022

### Added

- New selector label service

## [0.2.2] - 16-10-2022

### Changed

- Additonal env from list to map in values.yaml

### Fixed

- Invalid servicemonitor rendered
- Invalid HPA scaleup and scaledown policy rendered
- Invalid PDB rendered when both minAvailable and maxUnavailable is set. If both minAvailable and maxUnavailable is set then minAvailable takes precedence

## [0.2.1] - 15-10-2022

### Fixed

- Selector label bug for workloads. which was causing deployment failure due to immutable selector labels.

## [0.2.0] - 14-10-2022

### Changed

- `tpl.ingress.common.annotation` to not render `nginx.ingress.kubernetes.io/default-backend` annotation when `defaultBackendSvcName` is not passed
- values.yaml to look generic

### Removed

- Init Container template. If required use `initContainers: {{- toYaml .Values.initContainers | nindent 8 }}` below `{{- include "tpl.pod.template.spec" (merge (dict "name" "test" "sa" false ) .) | indent 6 }}`. Since Init Container can be dynamic and not required for all charts.

## [0.1.0] - 13-10-2022

- Initial Release
