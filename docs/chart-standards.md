# Chart standards

## Chart Metadata Standard (`Chart.yaml`)

Always use the standard metadata structure in consumer charts:

```yaml
apiVersion: v2
name: example-backend
version: 1.0.0
description: Application purpose and responsibilities
type: application
dependencies:
  - name: tpl-library
    version: 1.4.0
    repository: oci://registry-1.docker.io/grootantech
appVersion: "1.0.0"
deprecated: false
```

## Chart description and README

`description` states the application's business purpose, runtime architecture and
responsibilities — what it runs and why — rather than repeating the repository name:

```yaml
description: Website CMS backend providing headless content management, PostgreSQL persistence and S3 media storage.
```

Take it from the project manifest (`package.json`, `pyproject.toml`, `pom.xml`) or the root
README when one exists and says more than "TODO". The same text opens the chart README, which
is generated from `README.gotmpl`:

````gotmpl
{{ template "chart.header" . }}

{{ template "chart.badgesSection" . }}

{{ template "chart.deprecationWarning" . }}

{{ template "chart.homepageLine" . }}

{{ template "chart.description" . }}

## Overview & Purpose

<One paragraph on what this chart runs and why.>

## Architecture & Template Library

This chart uses the shared template library `tpl-library`.

{{ template "chart.requirementsHeader" . }}

{{ template "chart.kubeVersionLine" . }}

{{ template "chart.requirementsTable" . }}

{{ template "chart.maintainersSection" . }}

{{ template "chart.sourcesSection" . }}

{{ template "chart.valuesSection" . }}

{{ template "helm-docs.versionFooter" . }}

## Usage

```console
helm-docs --template-files README.gotmpl --sort-values-order file --document-dependency-values
```
````

## A consumer `values.yaml` is a replica of the library's

Copy the library's `values.yaml` at the pinned version and override what this application
needs; never assemble one from memory. Every key the library declares stays — including the
optional, empty and unused ones — with its `# --`, `# Ref:`, `# @section --` and `### Example`
lines, at `{}` or `[]` where unused:

1. **An absent key is unreadable.** Present-and-empty says the chart does not use it; absent
   cannot be told apart from "the author did not know it existed".
2. **helm-docs documents what is in the file.** An omitted key has no README row.
3. **It survives a library upgrade.** A replica diffs cleanly against the new library file.

**Where the copy stops.** A key marked `# @default -- Check values.yaml` is one opaque value
rendered through `toYaml`: its sub-keys are the chart's to shape (`strategy:` with
`type: Recreate` and no `rollingUpdate:` is complete). `containers.main` is an example name;
the contract applies to whatever containers the chart declares.

**Optional features are the exception.** `persistence`, `jobs`, `cronjobs`, `metrics`,
`global.metrics` and `global.tracing` appear only when the chart uses the feature and includes
its entrypoint (see [Templates and naming](templates.md#optional-resource-invocations)); a block
with no entrypoint documents a feature the chart does not have.

## Application values

The library's `values.yaml` holds workload plumbing only; application configuration is the
chart's to add:

- **Top level, not wrapped.** `database:`, `smtp:`, `nextauth:` sit at the root — no `app:`,
  `config:` or `settings:` envelope, which only lengthens every reference
  (`.Values.app.nextauth.url`). The name must not collide with a library root key; `service`,
  `metrics`, `routes`, `persistence` and `pod` are library keys.
- **Placed after `strategy:` and before `restartPolicy:`**, so the section a deployer opens the
  file for comes first while the library's own key order is kept.
- **Every leaf is documented** with its own `# --` and `# @section --`. `# @default -- Check
  values.yaml` is for a genuinely free-form map; on fixed keys it collapses them into one
  README row.

```yaml
apps:
  operation:
    # -- Host of the Operation console, substituted into the bundle at container start.
    # @section -- Application Settings
    host: ""
```

## Values Key-Value Comments Law (Standard for Init and Update)

- **No Comments on Parent/Root Keys**: Root keys and container mapping keys (e.g., `containers:`, `containers.main:`, `global:`, `database:`, `storage:`) must **never** have `# --` comments because they contain children. Only leaf properties or objects rendered with `toYaml` in `tpl-library` receive comments.
- **Primitive Values (`string`, `int`, `bool`, scalar arrays)**:
  Must include `# -- Description` and `# @section -- Section Name`:

  ```yaml
  containers:
    main:
      # -- Override the container name. Defaults to the map key (e.g., 'main') or component name.
      # @section -- Container Settings
      name: ""
  ```

- **Complex Objects & `toYaml` Rendering (`# @default -- Check values.yaml`)**:
  For complex structures (`securityContext`, `resources`, `probes`, `strategy`) rendered via `toYaml` in `tpl-library`, annotate with `# @default -- Check values.yaml` to prevent ugly, multi-line table distortion in generated documentation:

  ```yaml
      # -- Security context for the container (Standard Non-Root).
      # Ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
      # @section -- Container Settings
      # @default -- Check values.yaml
      securityContext:
        runAsUser: 10001
        runAsGroup: 10001
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
        privileged: false
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: false
        capabilities:
          drop:
            - ALL
  ```

- **Spacing & Grouping**: Maintain 2-space indentation and 1 empty line between commented entries for clean visual grouping.
- **Every leaf under `jobs:`, `cronjobs:` and `persistence:`** carries its own `# --` and
  `# @section --` lines, so helm-docs gives it a row. A `# --` on a parent map collapses the
  whole object into one JSON row, unless that parent is rendered as one opaque value and is
  marked `# @default -- Check values.yaml`. A plain `#` line is a note, not a row:

  ```yaml
  jobs:
    migrate:
      # -- Run the migration job.
      # @section -- Job Settings
      enabled: true
      # -- Seconds after completion before the Job is deleted.
      # @section -- Job Settings
      ttlSecondsAfterFinished: 120
  ```

- **Other comments in a consumer chart are one line saying why** a value differs from the
  library default — in `values.yaml`, overlays and templates alike. No banners, and no comment
  restating what the key already says.
- **Standard Container Values Block**:

  ```yaml
  containers:
    main:
      # -- Override the container name. Defaults to the map key (e.g., 'main') or component name.
      # @section -- Container Settings
      name: ""

      # -- Override container entrypoint (command).
      # @section -- Container Settings
      command: []
      ### Example
      # command:
      #   - /bin/sh

      # -- Override container arguments.
      # @section -- Container Settings
      args: []
      ### Example
      # args:
      #   - "-c"
      #   - "echo hello world && sleep 3600"

      image:
        # -- Image repository.
        # @section -- Container Settings
        repository: ""
        # -- Tag defaults to Chart.appVersion if left empty.
        # @section -- Container Settings
        tag: ""

      # -- Direct environment variables. High precedence.
      # @section -- Container Settings
      env: []
      ### Example
      # env:
      #   - name: LOG_LEVEL
      #     value: "debug"
      #   - name: POD_IP
      #     valueFrom:
      #       fieldRef:
      #         fieldPath: status.podIP

      # -- Security context for the container (Standard Non-Root).
      # Ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
      # @section -- Container Settings
      # @default -- Check values.yaml
      securityContext:
        runAsUser: 10001
        runAsGroup: 10001
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
        privileged: false
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: false
        capabilities:
          drop:
            - ALL
  ```

- **`command` and `args` stay `[]` for the chart's own image** — in `containers`, in job
  containers and in every overlay. `command` replaces the image ENTRYPOINT, so its init no
  longer runs as PID 1, and `args` replaces its CMD. A job picks its task through the image,
  for example a `MODE` variable its start script reads, and a shell chain in chart values moves
  into an image script. An init container that runs a third-party image may still need them.

## Several releases from one chart

One chart may run several releases from the same image, such as an API and a queue worker.
Each release is an overlay next to `values.yaml`:

- Name it `values.<release>.yaml`, where release = overlay file = `subComponent` = mode.
  `component` stays the same across the releases of one service.
- `values.yaml` defaults to the primary mode. Each overlay sets its own `mode:` — passed to the
  image as `MODE` through `configmapEnvs` — and its own `subComponent`, so the releases render
  distinct names.
- A release that serves no HTTP sets `service: ~`, turns its routes off
  (`routes.default.enabled: false`, keeping the host only if it needs its own URL) and uses
  exec probes or none — never an `httpGet` probe against a port it does not serve.
- The schema enum for `mode` and `subComponent` lists every value the base file, the overlays
  and the environments use, with no empty entry. A new mode ships with a chart version bump,
  or an environment still on the old chart rejects the value.

## Probes

- The probe path must exist in the application — read its route table or health handler rather
  than assuming `/health/ready`. A wrong path makes someone disable probes downstream.
- Workers and schedulers without a port use exec probes, such as the queue tool's own health
  command.
- A slow start (migrations before the server, model loading) gets a `startup` probe rather than
  a long liveness delay.
- Probe fixes belong in the chart, never in an environment's values override.

## Renaming a component or chart

A rename moves everything derived from the name. Before renaming, list and confirm:

- stateful names — PVC claims, and anything the application derives from its host or component
  (a site name, a tenant key) — since a new name can mean a new, empty volume;
- GitOps application keys (with pruning, a renamed key deletes and recreates the application)
  and the environment overrides that reference the old names;
- sibling references in other charts;
- identity-provider clients, roles and redirect URIs; database, bucket and queue names; code
  quality project keys; the chart name inside telemetry service names;
- names hard-coded in application code, as follow-ups rather than chart edits.

## Repository ignore files

`.helmignore` is applied by the chart **loader**, not only by `helm package`, and an unanchored
pattern matches a basename at any depth. A bare `*.tgz` or a `charts` entry therefore hides the
dependency archives in `charts/`, and Helm reports a missing dependency and
`no template "tpl.deployment"` while the archive is present. Never ignore `charts`; anchor a
root-only archive as `/*.tgz`. Baseline:

```text
.DS_Store
.git/
.gitignore
.svn/
*.swp
*.bak
*.tmp
*.orig
*~
.project
.idea/
*.tmproj
.vscode/

Chart.lock
.helmignore
.gitlab-ci.yml
.yamllint.yml
README.gotmpl
.gitleaks.toml
CODEOWNERS
CONTRIBUTING.md
LICENSE.md
Makefile
SECURITY.md
VERSION

test/
```

To confirm a loader problem, untar `charts/<dependency>.tgz` in place and lint again: if the
extracted copy passes where the archive failed, `.helmignore` is hiding it.

The repository's `.gitignore` lists `charts` and `Chart.lock`: both are resolved build output,
and a committed `charts/` shadows what CI resolves.

## Automated Documentation Synchronization

- Keep the `tpl-library` dependency, README index and generated values reference up to date.
- Always follow the values comments law for every new or updated property.
- In this library, regenerate both outputs on every `values.yaml` change:

  ```console
  make docs
  make docs-check
  ```

Consumer charts that keep all generated content in their README can continue to use:

```console
helm-docs --template-files README.gotmpl --sort-values-order file --document-dependency-values
```

Run it inside the chart directory with exactly these flags; plain `helm-docs` renders a
different README. Never edit a generated `README.md` by hand.

[Documentation index](../README.md)
