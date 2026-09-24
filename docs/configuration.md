# Configuration and storage

## Persistent Storage (`tpl.pvc`)

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

## Dynamic In-Values Template Evaluation (`tpl`)

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

## Sensitive Data Handling & Segregation Standard

- **Direct `env`**: High precedence. Used for runtime pod metadata (`fieldRef`), downward API, or direct references (`secretKeyRef`, `configMapKeyRef`).
- **`configmapEnvs`**: Multi-line key-value string for **non-sensitive** configuration only (`NODE_ENV`, `PORT`, `DATABASE_HOST`, `S3_BUCKET`). Rendered into a Kubernetes ConfigMap with automated rolling hashes (`checksum/configmap`).
- **`secretEnvs`**: Multi-line key-value string for **sensitive credentials** (`DATABASE_PASSWORD`, `S3_SECRET_KEY`, `APP_SECRET`) templating `.Values.secrets` or database credentials. Rendered into a Kubernetes Secret with automated rolling hashes (`checksum/secret`).
- **Zero Cleartext Credentials**: Passwords, private keys, and salts must **never** be placed in `configmapEnvs`.
- **Domain Grouping in `values.yaml`**:
  - **Database**: All database connection parameters must be grouped under `.Values.database` (e.g., `database.postgresql.host`, `port`, `database`, `ssl`, `auth.username`, `auth.password`).
  - **Storage**: All Object Storage / S3 configurations must be grouped under `.Values.storage` (e.g., `storage.bucketName`, `region`, `endpoint`, `baseUrl`, `rootPath`, `accessKey`, `secretKey`).
  - **Secrets**: Application secrets must be declared under `.Values.secrets` (e.g., `appSecret`, `jwtSecret`, `apiTokenSalt`).

## Modular JSON Schema Architecture (`values.schema.json`)

- `tpl-library` ships its own `values.schema.json` describing the shape above, with reusable
  `$defs` (`containerMap`, `container`, `workloadMap`, `persistenceMap`, `mounts`,
  `toggleable`, `autoscaling`). Consumer charts model theirs on it.
- It carries **no top-level `required`**, deliberately. A consumer configures `tpl-library` at
  the root of its own values, so the subchart's values section is validated empty — any
  required key there would fail every consumer's render.
- Types and enums only: `replicas` must be an integer, `restartPolicy` one of
  `Always`/`OnFailure`/`Never`, `autoscaling.minReplicas` at least 1. Unknown keys are
  allowed, so the schema catches typos and wrong types without blocking a valid config.

## RBAC & Security Policies

- `Role` and `RoleBinding` require dedicated configuration beyond basic template inclusion. Verify permissions carefully.

[Documentation index](../README.md)
