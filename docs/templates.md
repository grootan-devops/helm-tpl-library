# Templates and naming

## Component & Sub-Component Naming Convention

Standardize chart naming as `{component}-{sub-component}`:

- If sub-component is present (e.g. Node.js frontend, Go gateway, worker): `xyz-frontend`, `auth-gateway`, `payment-worker`.
- If standalone service or single component: `cms`, `auth`.

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

## Container Image Repository Auto-Resolution

When `(._container).image.repository` is omitted or empty `""`, `tpl-library` auto-computes the repository path via `tpl.container.image.repository`:

- **Format with subcomponent**: `<partOf>/<component>/<subcomponent>`
- **Format without subcomponent**: `<partOf>/<component>`
- **When `partOf` is omitted**: `<component>/<subcomponent>` (or `<component>`)
- Resolves `partOf` from `.Values.partOf` or `.Values.global.partOf`. Supports both `.Values.subComponent` and `.Values.subcomponent`.
- Explicit `repository` values remain evaluated as templates: `(tpl (._container).image.repository $)`.

## Template Invocation Standards (`templates/manifest.yaml`)

By default, a stateless application chart needs only the core deployment umbrella in `templates/manifest.yaml`:

```gotmpl
{{/* Core workload umbrella: Deployment, Service, Routes, PDB, SA, HPA, NetworkPolicy */}}
{{- include "tpl.deployment" . }}
```

`tpl.deployment` renders the workload and everything the pod references (Service, routes, ServiceAccount, PDB, NetworkPolicy, HPA, ConfigMaps and Secrets).

### Optional Resource Invocations

Optional capabilities (`persistence`, `cronjobs`, `jobs`, `metrics`) should **not** be included in `values.yaml` or `manifest.yaml` by default. When an application workload requires them, append the corresponding block below:

#### Prometheus Metrics (`tpl.servicemonitor` / `tpl.podmonitor`)

When scraping endpoints are configured under `metrics:` and `global.metrics.enabled` is `true`:

```gotmpl
---
{{ include "tpl.servicemonitor" . }}
```

*(Or use `{{ include "tpl.podmonitor" . }}` if scraping pods directly instead of Services.)*

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
