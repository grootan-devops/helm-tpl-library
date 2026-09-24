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

## Template Invocation Standards (`templates/manifest.yaml`)

Use the below `tpl.*` template functions from `tpl-library` to generate Kubernetes resources:

```gotmpl
{{- include "tpl.servicemonitor" . }}
---
{{- include "tpl.deployment" . }}
---
{{- include "tpl.job" (merge (dict "_container" .Values.job "serviceSuffix" "job") .) }}
---
{{- include "tpl.cronjob" (merge (dict "_container" .Values.cronjob "serviceSuffix" "cronjob") .) }}
---
{{- include "tpl.pvc" . }}
```

`tpl.servicemonitor`, `tpl.job`, `tpl.cronjob` and `tpl.pvc` are **optional** — include
only the ones the chart needs. `tpl.deployment` is the one that renders the workload and
everything the pod references (Service, routes, ServiceAccount, PDB, NetworkPolicy, HPA,
ConfigMaps and Secrets).

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
