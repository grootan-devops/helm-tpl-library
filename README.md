# Helm tpl Library

[Compatibility](https://github.com/grootan-devops/ai-skills/blob/main/COMPATIBILITY.md) · [Security](./SECURITY.md) · [Reporting policy](./CONTRIBUTING.md)

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![Type: library](https://img.shields.io/badge/Type-library-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

Helm tpl library for helm chart

## Usage:

```console
helm registry login oci-registry-endpoint --username registry-username --password registry-password
```

```yaml
dependencies:
  - name: tpl-library
    version: 1.0.0
    repository: oci://registry-endpoint/registry-name
```

**Note:** Check `values.yaml` and reference for more examples and usage of Kubernetes objects.

### Chart standards to follow

- **Chart Metadata Standard (`Chart.yaml`)**:
  Always use the standard metadata structure in consumer charts:

```yaml
apiVersion: v2
name: `chart-name`
version: `chart-version`
description: `chart-description`
type: application
home: `app-home-page-link`
maintainers:
  - name: DevOps
    email: devops@contoso.com
dependencies:
  - name: tpl-library
    version: 1.0.0
    repository: oci://registry.contoso.com/helm
icon: `app-logo`
appVersion: `app-version`
deprecated: false
```

- **Component & Sub-Component Naming Convention**:
  Standardize chart naming as `{component}-{sub-component}`:
  - If sub-component is present (e.g. Node.js frontend, Go gateway, worker): `xyz-frontend`, `auth-gateway`, `payment-worker`.
  - If standalone service or single component: `cms`, `auth`.

- **Container Naming & the reserved `main` key**:
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

- **Template Invocation Standards (`templates/manifest.yaml`)**:
  Use the below `tpl.*` template functions from `tpl-library` to generate Kubernetes resources:

```yaml
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

- **Persistent Storage (`tpl.pvc`)**:
  `mounts.pvc` mounts a claim; it does not create one. A mount with nothing behind it
  leaves the pod `Pending` while `helm install` reports success, so a chart that owns its
  storage declares `persistence` and includes `tpl.pvc`:

```yaml
persistence:
  data:
    enabled: true        # keep in step with mounts.pvc.data.enabled
    storageClass: "gp3"  # "" uses the cluster default
    size: 10Gi           # immutable once bound -- expand via allowVolumeExpansion
    accessModes:
      - ReadWriteOnce    # ReadWriteMany for more than one replica writing
    annotations:
      helm.sh/resource-policy: keep

mounts:
  pvc:
    data:
      enabled: true
      mountTo: "main"
      path: /var/lib/data
```

  Each claim is named `<resource name>-<key>`, which is exactly what `mounts.pvc.<key>`
  defaults `claimName` to — so the two sides pair up without writing the name twice. Set
  `claimName` explicitly only to bind a claim this chart does not own, and set
  `persistence.<key>.existingClaim` to skip rendering it.

- **Dynamic In-Values Template Evaluation (`tpl`)**:
  String values across routing (`routes.*.host`, `routes.*.hosts`), environment variables (`configmapEnvs`, `secretEnvs`, `containers.*.env`), volume mounts, and annotations are evaluated dynamically via Helm's `tpl` engine against the root scope (`$`).
  This eliminates hardcoded values and enables DRY configurations that reference other values within the chart:

  ```yaml
  routes:
    default:
      enabled: true
      # Dynamic in-values reference using $.Values.component and $.Values.global.routes.domain
      host: "{{ $.Values.component }}.{{ $.Values.global.routes.domain }}"
      hosts:
        - "{{ $.Values.component }}.{{ $.Values.global.routes.domain }}"
        - "{{ $.Values.component }}-internal.{{ $.Values.global.routes.domain }}"
  ```

  In `configmapEnvs` or `secretEnvs`:
  ```yaml
  configmapEnvs: |
    SERVICE_URL=https://{{ $.Values.component }}.{{ $.Values.global.routes.domain }}
    APP_NAME={{ $.Values.component }}
  ```

  > [!IMPORTANT]
  > Always enclose template expressions in quotes in `values.yaml` (e.g. `"{{ $.Values.component }}.{{ $.Values.global.routes.domain }}"`) so YAML parses them as valid strings. Root scope `$` provides access to top-level attributes including `.Values.global`, `.Values.component`, `.Release.Name`, and `.Release.Namespace`.

- **Cross-Service Sibling Resource Naming (`tpl.resource.siblingName`)**:
  In microservices architectures deployed under a shared product or release prefix (e.g. `myapp-order-backend`), services frequently need to reference sibling Kubernetes resources (e.g. `myapp-cart-backend`, `myapp-redis`, `myapp-auth-svc`).
  - **Difference from `tpl.resource.name`**: Standard resource naming via `tpl.resource.name` automatically appends the current chart's component name (`<release>-<component>-<name>`). Using it to reference another service results in an invalid name like `myapp-order-backend-cart-backend`.
  - **Purpose of `tpl.resource.siblingName`**: Generates a resource name scoped to the product/release prefix **without** the caller's component name:
    ```yaml
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

- **Values Key-Value Comments Law (Standard for Init and Update)**:
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

- **Sensitive Data Handling & Segregation Standard**:
  - **Direct `env`**: High precedence. Used for runtime pod metadata (`fieldRef`), downward API, or direct references (`secretKeyRef`, `configMapKeyRef`).
  - **`configmapEnvs`**: Multi-line key-value string for **non-sensitive** configuration only (`NODE_ENV`, `PORT`, `DATABASE_HOST`, `S3_BUCKET`). Rendered into a Kubernetes ConfigMap with automated rolling hashes (`checksum/configmap`).
  - **`secretEnvs`**: Multi-line key-value string for **sensitive credentials** (`DATABASE_PASSWORD`, `S3_SECRET_KEY`, `APP_SECRET`) templating `.Values.secrets` or database credentials. Rendered into a Kubernetes Secret with automated rolling hashes (`checksum/secret`).
  - **Zero Cleartext Credentials**: Passwords, private keys, and salts must **never** be placed in `configmapEnvs`.
  - **Domain Grouping in `values.yaml`**:
    - **Database**: All database connection parameters must be grouped under `.Values.database` (e.g., `database.postgresql.host`, `port`, `database`, `ssl`, `auth.username`, `auth.password`).
    - **Storage**: All Object Storage / S3 configurations must be grouped under `.Values.storage` (e.g., `storage.bucketName`, `region`, `endpoint`, `baseUrl`, `rootPath`, `accessKey`, `secretKey`).
    - **Secrets**: Application secrets must be declared under `.Values.secrets` (e.g., `appSecret`, `jwtSecret`, `apiTokenSalt`).

- **Modular JSON Schema Architecture (`values.schema.json`)**:
  - `tpl-library` ships its own `values.schema.json` describing the shape above, with reusable
    `$defs` (`containerMap`, `container`, `workloadMap`, `persistenceMap`, `mounts`,
    `toggleable`, `autoscaling`). Consumer charts model theirs on it.
  - It carries **no top-level `required`**, deliberately. A consumer configures `tpl-library` at
    the root of its own values, so the subchart's values section is validated empty — any
    required key there would fail every consumer's render.
  - Types and enums only: `replicas` must be an integer, `restartPolicy` one of
    `Always`/`OnFailure`/`Never`, `autoscaling.minReplicas` at least 1. Unknown keys are
    allowed, so the schema catches typos and wrong types without blocking a valid config.

- **RBAC & Security Policies**:
  - `Role` and `RoleBinding` require dedicated configuration beyond basic template inclusion. Verify permissions carefully.

- **Automated Documentation Synchronization**:
  - Keep the `tpl-library` dependency and `README.md` up to date.
  - Always follow the values comments law for every new or updated property.
  - Regenerate `README.md` using `helm-docs` on every `values.yaml` change:
    ```console
    helm-docs --template-files README.gotmpl --sort-values-order file --document-dependency-values
    ```

## Testing

`tpl-library` is a library chart, so it cannot be rendered on its own. `test` is a
mock consumer chart that depends on this library through `file://..` and calls every
`tpl.*` entrypoint; [helm-unittest](https://github.com/helm-unittest/helm-unittest) then
asserts the rendered output for both the default values and each override scenario.

```console
make plugin   # install helm-unittest (once per machine)
make test     # helm dependency update + helm unittest test
make lint     # helm lint the mock chart + yamllint the plain-YAML files
make render   # print the example.yaml render while debugging a template
```

- `test/values/` is the scenario matrix: `full.yaml` is a verbatim copy of
  `example.yaml`, and the rest are focused override layers (routes, mounts, env
  precedence, sibling references, autoscaling, job/cronjob, naming edges).
- `test/tests/` holds one suite per library template, each pairing a default
  case with an override case.
- `tests/e2e_full_test.yaml` snapshots the whole render for the defaults and for
  `example.yaml`, one snapshot per entrypoint template, committed under
  `tests/__snapshot__/`. After an intentional template change run `make test-update` and
  review the snapshot diff.
- `tests/known_defects_test.yaml` pins behaviour that is currently wrong, with the fix
  noted inline. Those cases turn red on purpose once a bug is fixed — convert them into
  passing cases then.

Whenever `values.yaml` or `example.yaml` changes, refresh `test/values.yaml`
(the baseline copy of `values.yaml`) and `test/values/full.yaml` (the copy of
`example.yaml`) alongside it.

## Requirements

- Helm: `>=3.2.0`
- Kubernetes: `>=1.27`

| Repository | Name | Version |
|------------|------|---------|

## Values

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.releaseNameLength | int | `6` | Length of the release name to form cross-service resource names. WARNING: Changing this on an existing release may break resource binding. |
| global.image.registry | string | `"cr.io"` | Global Docker image registry (e.g., docker.io, quay.io). |
| global.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. Defaults to IfNotPresent. Ref: https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy |
| global.image.pullSecrets | list | `["cr-cred"]` | List of image pull secrets for private registries. Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |
| global.routes.domain | string | `""` | Base routing domain name (e.g., contoso.com). |
| global.routes.ingressClass | string | `""` | Ingress class name for Ingress resources (e.g., nginx, apisix). |
| global.routes.tlsSecretName | string | `""` | Ingress TLS secret name. |
| global.routes.gateway.name | string | `"default-gateway"` | Target Gateway name for HTTPRoute parentRefs. |
| global.routes.gateway.namespace | string | `"gateway-system"` | Target Gateway namespace for HTTPRoute parentRefs. |
| global.routes.gateway.class | string | `"gateway"` | Gateway class name (e.g., gateway, apisix). |
| global.metrics.enabled | bool | `false` | Prometheus ServiceMonitor/PodMonitor. |
| global.metrics.additionalLabels | object | `{}` | Additional labels to attach to the generated ServiceMonitor/PodMonitor. |
| global.additionalLabels | object | `{}` | Additional labels to be applied to all resources. |
| global.partOf | string | `""` | Shared name segment, often used for labeling (e.g., app.kubernetes.io/part-of). |

### Observability Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.tracing.enabled | bool | `false` | Enable or disable distributed tracing. Ref: https://opentelemetry.io/docs/concepts/observability-primer/#tracing |
| global.tracing.insecure | bool | `true` | If true, disables TLS/SSL verification for the tracing endpoint. Use only for local development or internal networks. |
| global.tracing.endpoint | string | `"http://localhost:4317"` | The OTLP endpoint URL to send traces to (e.g., Jaeger, Tempo, Otel Collector). |
| global.tracing.sampler.ratio | float | `1` | The sampling probability (0.0 to 1.0). 1.0 samples every trace; 0.0 samples nothing. Ref: https://opentelemetry.io/docs/concepts/sampling/ |
| global.tracing.sampler.type | string | `"parentbased_always_on"` | The sampling strategy to use. Common values: parentbased_always_on, parentbased_traceidratio, always_on, always_off, traceidratio. |
| global.tracing.auth.username | string | `""` | Username for Basic Auth (if required by the collector). |
| global.tracing.auth.password | string | `""` | Password for Basic Auth (if required by the collector). |

### Common Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| component | string | `""` | Overrides the name of the component. Used in labels and resource naming. |
| subComponent | string | `""` | Sub-component name override. |

### Workload Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicas | int | `1` | Number of desired pods. |
| revisionHistoryLimit | int | `0` | Revision history limit for the Deployment (keeps X old ReplicaSets). |
| strategy | object | Check values.yaml | Strategy for replacing old pods with new ones. Ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy |
| restartPolicy | string | `"Always"` | Restart policy for all containers in the pod. Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy |
| serviceAccount.create | bool | `false` | Create ServiceAccount resource. Ref: https://kubernetes.io/docs/concepts/security/service-accounts/ |
| serviceAccount.annotations | object | `{}` | ServiceAccount annotations. |
| hostAliases | list | `[]` | HostAliases to inject into /etc/hosts. Ref: https://kubernetes.io/docs/tasks/network/customize-hosts-file-for-pods/ |
| pod.annotations | object | `{}` | Annotations to add to the Pod metadata. |
| pod.securityContext | object | Check values.yaml | Pod-level Security Context (applied to all containers). Ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |

### Container Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| initContainers | object | `{}` | Init Container configuration. |
| containers.main.name | string | `""` | Override the container name. Defaults to the map key (e.g., 'main') or component name. |
| containers.main.command | list | `[]` | Override container entrypoint (command). |
| containers.main.args | list | `[]` | Override container arguments. |
| containers.main.image.repository | string | `""` | Image repository. |
| containers.main.image.tag | string | `""` | Tag defaults to Chart.appVersion if left empty. |
| containers.main.env | list | `[]` | Direct environment variables. High precedence. |
| containers.main.securityContext | object | Check values.yaml | Security context for the container (Standard Non-Root). Ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| containers.main.resources | object | `{}` | CPU/Memory resource requests and limits. Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ |
| containers.main.resizePolicy | list | `[]` | Resize policy for CPU/Memory. Ref: https://kubernetes.io/docs/tasks/configure-pod-container/resize-container-resources/ |
| containers.main.configmapEnvs | object | `{}` | ConfigMap-based environment variables. Templated string (Key: Value). |
| containers.main.secretEnvs | object | `{}` | Secret-based environment variables. Templated string (Key: Value). |
| containers.main.additionalConfigmapEnvs | object | `{}` | Extra mappings for ConfigMaps that need custom handling. |
| containers.main.additionalSecretEnvs | object | `{}` | Extra mappings for Secrets that need custom handling. |
| containers.main.extraConfigmapMounts | list | `[]` | List of existing ConfigMaps to inject as environment variables (envFrom). |
| containers.main.extraSecretMounts | list | `[]` | List of existing Secrets to inject as environment variables (envFrom). |
| containers.main.probes.enabled | bool | `true` | Enable probes. Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| containers.main.probes.readiness | object | `{}` | Readiness probe configuration. Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| containers.main.probes.liveness | object | `{}` | Liveness probe configuration. Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| containers.main.probes.startup | object | `{}` | Startup probe configuration. Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |

### Scheduling Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| scheduling.topologySpreadConstraints | list | `[]` | Spread pods across failure domains (zones, nodes). Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/ |
| scheduling.nodeSelector | object | `{}` | Simple node selection constraints (Key: Value). Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| scheduling.tolerations | list | `[]` | Allow pods to schedule on tainted nodes. Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| scheduling.affinity | object | `{}` | Complex node/pod affinity rules. Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |

### Networking Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| service.default.annotations | object | `{}` | Service annotations. |
| service.default.spec | object | `{"ports":[],"type":"ClusterIP"}` | Kubernetes Service specification. Ref: https://kubernetes.io/docs/concepts/services-networking/service/ |
| routes.default.enabled | bool | `true` | Master switch to enable routing for this route definition. |
| routes.default.ingress | bool | `true` | Render Kubernetes Ingress (networking.k8s.io/v1). |
| routes.default.httpRoute | bool | `true` | Render Kubernetes Gateway API HTTPRoute (gateway.networking.k8s.io/v1). |
| routes.default.host | string | `"{{ $.Values.component }}.{{ $.Values.global.routes.domain }}"` | Host header domain. Evaluated via tpl. |
| routes.default.hosts | list | `[]` | Optional list of hostnames. Overrides host if specified. |
| routes.default.ingressClass | string | `""` | Ingress class name for Ingress spec.ingressClassName. Defaults to global.routes.ingressClass. |
| routes.default.tlsSecretName | string | `""` | Secret name for Ingress TLS termination. Defaults to global.routes.tlsSecretName. |
| routes.default.gateway.name | string | `""` | Target Gateway name for HTTPRoute parentRefs. Defaults to global.routes.gateway.name. |
| routes.default.gateway.namespace | string | `""` | Target Gateway namespace for HTTPRoute parentRefs. Defaults to global.routes.gateway.namespace. |
| routes.default.gateway.class | string | `""` | Gateway class name. Defaults to global.routes.gateway.class. |
| routes.default.parentRefs | list | `[]` | Custom parentRefs override for HTTPRoute. |
| routes.default.annotations | object | `{}` | Annotations applied to both Ingress and HTTPRoute. |
| routes.default.paths | list | `[]` | Path routing rules (compatible with both Ingress and HTTPRoute). Ref: https://gateway-api.sigs.k8s.io/reference/api-spec/main/spec/#httprouterule |
| networkPolicy.enabled | bool | `false` | Enable NetworkPolicy. Ref: https://kubernetes.io/docs/concepts/services-networking/network-policies/ |
| networkPolicy.ingressRule | list | `[]` | Ingress network rules. |
| networkPolicy.egressRule | list | `[]` | Egress network rules. |

### Storage Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| mounts.secret | object | `{}` | Secret volume mounts. |
| mounts.configmap | object | `{}` | ConfigMap volume mounts. |
| mounts.emptyDir | object | `{}` | EmptyDir volume mounts. |
| mounts.pvc | object | `{}` | PersistentVolumeClaim mounts. |

### Operations Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| pdb.enabled | bool | `false` | Enable PodDisruptionBudget. Ref: https://kubernetes.io/docs/tasks/run-application/configure-pdb/ |
| pdb.minAvailable | string | `""` | Minimum available pods. |
| pdb.maxUnavailable | int | `2` | Maximum unavailable pods. |
| autoscaling.enabled | bool | `false` | Enable HPA. Ref: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/ |
| autoscaling.minReplicas | int | `1` | Minimum pod replicas. |
| autoscaling.maxReplicas | int | `3` | Maximum pod replicas. |
| autoscaling.metrics | list | `[]` | Resource metrics targets. |
| autoscaling.scaleUp | object | `{}` | Scale up behavior policy. |
| autoscaling.scaleDown | object | `{}` | Scale down behavior policy. |
| metrics.jobLabel | string | `"app_kubernetes_io_instance"` | Job label for ServiceMonitor metrics. Ref: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/getting-started.md |
| metrics.endpoints | list | `[]` | List of scrape endpoints. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| jobs | object | `{}` |  |
| cronjobs | object | `{}` |  |
| service.default | object | `{"annotations":{},"spec":{"ports":[],"type":"ClusterIP"}}` | Default service definition. |
| persistence | object | `{}` |  |

### Testing a consumer chart — what to cover, and what not to

A consumer chart may enable `helm unittest` in CI (`chart.yml` `run-unittest: true` on
GitHub, the chart test job on GitLab). The question is what those tests should assert.

**Not the Kubernetes rendering.** The suites above already cover it, against this library,
at this version: resource naming, pod and container spec, Service, Ingress and HTTPRoute,
mounts and PVC pairing, RBAC, HPA, PDB, NetworkPolicy, labels, metrics, env precedence, and
the job and cronjob workloads. A consumer chart that re-asserts a rendered `spec:` is
testing `tpl-library`, not itself — it duplicates work, and it breaks on a library upgrade that
was correct.

**Cover what only this chart knows**: the values it declares, and what the library does with
them.

| Assert | Why it is the consumer's |
|---|---|
| **Rendered names** for this chart's `component` / `subComponent` / `global.partOf` | The helper is tested here; whether *your* values produce `order-backend-main` is yours |
| **Token rendering** — a templated token inside a value resolves | `tpl` evaluation is the library's, but which values carry a token, and to what, is the chart's |
| **Auto defaults, and that an override overrides** | A default that silently wins over a set value is the failure this catches; the pairing is chart-specific |
| **Sibling references** resolve to the services this chart actually talks to | `tpl.resource.siblingName` is tested here; that your `cart.internalUrl` points at the cart service is not |
| **Schema** — `values.schema.json` rejects the mistakes this chart's values invite | The shape is the chart's own |

A useful shape is one scenario file per decision the chart makes, mirroring `test/values/`
above: defaults, then one override layer per behaviour, each asserting only the keys that
layer changes.

## License

Copyright 2026 Grootan Technologies Pvt Ltd.

Licensed under the [GNU Affero General Public License v3.0](./LICENSE.md)
(`AGPL-3.0-only`). External contributions are not accepted; see
[CONTRIBUTING.md](./CONTRIBUTING.md) for bug and security reporting.

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)

## Usage

```console
helm-docs --template-files README.gotmpl --sort-values-order file --document-dependency-values
```
