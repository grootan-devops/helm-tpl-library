# Templates and naming

## Component & Sub-Component Naming Convention

`global.partOf` names the product; `component` and `subComponent` name the workload.

- **Component name** — `{component}-{subComponent}`, or `{component}` when `subComponent` is
  empty: `auth-gateway`, `payment-worker`, `cms`. Every resource name below is built from it.
- **Chart name** — `{partOf}-{component}`, or `{partOf}-{component}-{subComponent}` when
  several charts share a component: `myapp-auth`, `myapp-payment-worker`.
- **One chart, several releases** — when one chart runs several modes (an API and a worker),
  each release sets its own `subComponent`. Releases that share one render identical names.

## Resource names

`global.releaseNameLength` is the length of the product prefix in the release name: `5` for
the release `myapp-orders-worker`. With `P` = the first `releaseNameLength` characters of the
release name and `C` = the component name:

| Resource | Name |
| --- | --- |
| Deployment, default Service, ServiceAccount, HPA, PDB, NetworkPolicy, Ingress, HTTPRoute | `P-C` |
| Service under another `service.<k>` key | `P-C-k` |
| Env ConfigMap and Secret of container key `k` | `P-C-k-env` |
| Job `jobs.<j>` and CronJob `cronjobs.<j>` | `P-C-j` |
| PVC `persistence.<v>` | `P-C-v` |
| Sibling (`tpl.resource.siblingName`) | `P-<name>`, where `<name>` is the sibling's full component name |

With `component: orders`, `subComponent: worker` and `releaseNameLength: 5`, the release
`myapp-orders-worker` renders the Deployment `myapp-orders-worker` and the main container's
env ConfigMap `myapp-orders-worker-main-env`. Renaming `component` or `subComponent` renames
every one of them, PVC claims included.

## Container Naming & the reserved `main` key

Every container name is derived from its **map key**, not from a `name:` field:

| Declared at | Rendered name |
| --- | --- |
| `containers.<key>` | `{component}-{subComponent}-{key}` |
| `initContainers.<key>` | `init-{component}-{subComponent}-{key}` |
| `jobs.<job>.containers.<key>` | `{component}-{subComponent}-{key}` |
| `jobs.<job>.initContainers.<key>` | `init-{component}-{subComponent}-{key}` |
| `cronjobs.<cj>` | reuses the root `containers:`, so the same names as the workload |

With `subComponent` empty the prefix collapses to `{component}`. There is no `-job` or
`-cronjob` suffix: a job's containers live in their own pod, so there is nothing to
disambiguate, and the suffix would only eat into the 63-character DNS-1123 budget. A key
too long to fit that budget fails the render rather than producing a truncated name.

**`main` is reserved** for the single main workload container under `containers:`.
`tpl-library` fails the render if it is used as an init container key or as a
`jobs.<job>.containers` key. It does **not** apply to `cronjobs:`, which reuse the root
`containers:` and therefore run `main` in their pod by design.

### Choosing a container key

The prefix exists so the `container` label is self-describing in logs and metrics without a
relabel rule: `{container="order-backend-main"}` names the service, a fleet-wide
`container="main"` names nothing. `main` is the one application process; every other
container says what job it does. Derive the key rather than looking it up:

1. **What is its job in one phrase?** What it does, not what it is: "ships this pod's stdout
   to the log backend", "pools Postgres connections".
2. **Would the key survive replacing the image?** Swapping Alloy for Fluent Bit leaves the job
   unchanged, so the key must be too; a key that would change names the vendor.
3. **Does it read correctly after the component prefix?** `order-backend-connection-pool` is
   self-explanatory; `order-backend-pgb` and `order-backend-sidecar` are not.
4. **Is it distinguishable from its siblings?** `metrics-exporter` and
   `business-metrics-exporter`, not `metrics` and `metrics2`.

Use a lowercase, hyphenated `noun` or `verb-noun`, as short as still passes question 3.
Always rejected: `sidecar`, `helper`, `aux`, `agent` alone, `container2` and bare vendor or
product names.

| What it does | Key | Not, and why |
| --- | --- | --- |
| Ships pod logs to a log backend | `log-collector` | `alloy`, `fluentbit` (vendor), `logs` (too coarse) |
| Exposes app metrics for scraping | `metrics-exporter` | `prom` (vendor), `exporter` (of what?) |
| Terminates or routes mesh traffic | `proxy` | `envoy`, `istio-proxy` (vendor) |
| Fetches secrets into a shared volume | `secret-agent` | `vault` (vendor), `agent` (of what?) |
| Pools database connections | `connection-pool` | `pgbouncer` (vendor), `db` (too coarse) |
| Reloads config on a ConfigMap change | `config-reloader` | `reloader` (coarse) |
| Authenticates requests ahead of the app | `auth-proxy` | `oauth2-proxy` (vendor) |
| Streams OTLP traces to a collector | `trace-forwarder` | `otel-collector` (product) |
| Periodically snapshots a volume | `backup-agent` | `restic`, `velero` (vendor) |
| Serves a read-through local cache | `cache` | `redis`, `memcached` (vendor) |

**Init container keys** name a completed precondition: `db-migration`, `wait-for-db`,
`fetch-config`, `chown-data`, `seed-fixtures`. Init containers render and run in `sortAlpha`
order of their keys, not in declaration order, so prefix them numerically (`01-`, `02-`) only
when one depends on another. An explicit `name:` overrides the whole scheme, including the
`main` reservation; use it only when an external contract fixes the container name.

## Container Image Repository Auto-Resolution

When `(._container).image.repository` is omitted or empty `""`, `tpl-library` auto-computes the repository path via `tpl.container.image.repository`:

- **Format with subcomponent**: `<partOf>/<component>/<subcomponent>`
- **Format without subcomponent**: `<partOf>/<component>`
- **When `partOf` is omitted**: `<component>/<subcomponent>` (or `<component>`)
- **When `component` and `subComponent` are both empty**: the chart name.
- Resolves `partOf` from `.Values.partOf` or `.Values.global.partOf`. Supports both `.Values.subComponent` and `.Values.subcomponent`.
- Explicit `repository` values remain evaluated as templates: `(tpl (._container).image.repository $)`.

The registry and pull secret come from `global.image.registry` and `global.image.pullSecrets`.
Their defaults, `cr.io` and `cr-cred`, are placeholders: set both to the registry the CI
pipeline pushes to. Leave `repository` empty only when the derived path equals the path CI
pushes the image to; otherwise set it explicitly.

## Template Invocation Standards (`templates/manifest.yaml`)

By default, a stateless application chart needs only the core deployment umbrella in `templates/manifest.yaml`:

```gotmpl
{{/* Core workload umbrella: Deployment, Service, Routes, PDB, SA, HPA, NetworkPolicy */}}
{{- include "tpl.deployment" . }}
```

`tpl.deployment` renders the workload and everything the pod references (Service, routes, ServiceAccount, PDB, NetworkPolicy, HPA, ConfigMaps and Secrets).

### Optional Resource Invocations

Optional capabilities (`persistence`, `cronjobs`, `jobs`, `metrics`) should **not** be included in `values.yaml` or `manifest.yaml` by default. When an application workload requires them, append the corresponding block below. A block left out also leaves out its `values.schema.json` properties.

`global.tracing` is read by no template. It only carries the application's own OpenTelemetry
settings: keep it when the application reads them, passing the values in through
`configmapEnvs`, and omit it otherwise.

#### Prometheus Metrics (`tpl.servicemonitor` / `tpl.podmonitor`)

When scraping endpoints are configured under `metrics:` and `global.metrics.enabled` is `true`:

```gotmpl
---
{{ include "tpl.servicemonitor" . }}
```

*(Or use `{{ include "tpl.podmonitor" . }}` if scraping pods directly instead of Services.)*

`global.metrics` is read only by these two templates. A chart that includes neither omits
`global.metrics` together with `metrics:`; do not include a monitor for an application that
serves no metrics endpoint.

#### Persistent Storage (`tpl.pvc`)

`tpl.pvc` emits its own document separator `---` for each enabled claim. When persistent storage is required:

```gotmpl
{{ include "tpl.pvc" . }}
```

#### Batch Jobs (`tpl.job`)

When one-off or hook batch jobs are defined under `jobs:` in `values.yaml`:

```gotmpl
{{- range $name, $job := .Values.jobs }}
---
{{- include "tpl.job" (merge (dict "_container" $job "serviceSuffix" $name) $) }}
{{- end }}
```

#### Recurring CronJobs (`tpl.cronjob`)

When scheduled tasks are defined under `cronjobs:` in `values.yaml`:

```gotmpl
{{- range $name, $cj := .Values.cronjobs }}
---
{{- include "tpl.cronjob" (merge (dict "_container" $cj "name" $name) $) }}
{{- end }}
```

## Cross-Service Sibling Resource Naming (`tpl.resource.siblingName`)

In microservices architectures deployed under a shared product or release prefix (e.g. `myapp-order-backend`), services frequently need to reference sibling Kubernetes resources (e.g. `myapp-cart-backend`, `myapp-redis`, `myapp-auth-svc`).

- **Difference from `tpl.resource.name`**: Standard resource naming via `tpl.resource.name` automatically appends the current chart's component name (`<release>-<component>-<name>`). Using it to reference another service results in an invalid name like `myapp-order-backend-cart-backend`.
- **Purpose of `tpl.resource.siblingName`**: Generates a resource name scoped to the product/release prefix **without** the caller's component name:

  ```gotmpl
  {{- define "tpl.resource.siblingName" -}}
  {{- printf "%s-%s" (.Release.Name | trunc (.Values.global.releaseNameLength | int)) .name }}
  {{- end }}
  ```

- **Resolution Mechanics**:
  - Current Release: `myapp-order-backend`
  - `global.releaseNameLength`: `5` (length of product prefix `myapp`)
  - Sibling name parameter `.name`: `cart-backend`
  - Output Service Name: `myapp-cart-backend`

- **Example Usage in `values.yaml`**:

  ```yaml
  configmapEnvs: |
    # Auto-resolves sibling service DNS: myapp-cart-backend:8080
    CART_SERVICE_URL=http://{{ include "tpl.resource.siblingName" (merge (dict "name" "cart-backend") $) }}:8080

    # Auto-resolves sibling Redis service: myapp-redis-master:6379
    REDIS_HOST={{ include "tpl.resource.siblingName" (merge (dict "name" "redis-master") $) }}
  ```

- **Override-First Law**: Always provide an explicit override property so operators can redirect to external or cross-cluster endpoints:

  ```yaml
  cart:
    # -- Optional internal URL override for cart-backend service.
    # @section -- Cross-Service Settings
    internalUrl: ""

  configmapEnvs: |
    CART_SERVICE_URL: '{{ tpl .Values.cart.internalUrl $ | default (printf "http://%s:8080" (include "tpl.resource.siblingName" (merge (dict "name" "cart-backend") .))) }}'
  ```

[Documentation index](../README.md)
