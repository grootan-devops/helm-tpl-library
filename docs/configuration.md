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

## Mounts

- **Every mount entry needs `enabled: true`.** An entry under `mounts.configmap`,
  `mounts.secret`, `mounts.emptyDir` or `mounts.pvc` without it renders nothing, and nothing
  reports the omission.
- **`mountTo` defaults to `both`**: the main containers and the init containers. Keep `both`
  for a volume an init container needs — one it prepares, or one a migration it runs writes —
  because `main` skips every init container. Set `mountTo: "main"` for a file only the
  application reads, typically a credential, so it does not reach an init container that runs
  as another identity. A job's containers count as `main`, its init containers as `init`.
- **Runtime-writable paths are mounts, not image changes.** The workload runs as UID 10001, so
  a process that writes a cache, a lock or a pid file into the image fails with
  *permission denied*. Scratch data needed only while the pod runs is an `emptyDir` mount;
  data that must survive a restart is a `persistence` block with `tpl.pvc` and the matching
  `mounts.pvc` entry. Point the application at the path through `configmapEnvs` when it reads
  the location from the environment.

```yaml
mounts:
  emptyDir:
    cache:
      enabled: true
      path: /app/.cache
```

## File mounts

**Any file the application reads at runtime is declared under `mounts:`** — not baked into the
image, which cannot vary per environment, and not a hand-written ConfigMap template, which
duplicates what the library generates and drifts from it.

The top-level key is the ConfigMap-or-Secret decision, made on the **content**, never the
filename:

| Use | When the file content |
| --- | --- |
| `mounts.configmap` | is safe in plaintext in git — routing rules, log format, feature flags, tuning |
| `mounts.secret` | contains or derives a credential, private key, certificate, token or a connection string with a password |

An `application.properties` with `spring.datasource.password` is a Secret; an `nginx.conf`
with only routing and headers is a ConfigMap, and the same file with a bearer token is a
Secret. Split a mixed file so the safe half stays reviewable. A Secret is base64, not
encrypted: a real credential still belongs in an external secret store.

Every `data` and `stringData` value is rendered through `tpl`, so derive values instead of
repeating them — the port, the host and sibling names already live in `values.yaml`. Use
`stringData` for plain text; `data` expects base64.

A single-page application's server config, mounted over the micro-nginx default:

```yaml
mounts:
  configmap:
    nginx-config:
      enabled: true
      mountTo: "main"
      path: /etc/nginx/conf.d
      data:
        default.conf: |
          server {
              listen 8080;
              server_name _;

              root /usr/share/nginx/html;
              index index.html index.htm;

              add_header X-Frame-Options "SAMEORIGIN" always;
              add_header X-Content-Type-Options "nosniff" always;
              add_header Referrer-Policy "strict-origin-when-cross-origin" always;

              gzip on;
              gzip_vary on;
              gzip_proxied any;
              gzip_comp_level 6;
              gzip_types text/plain text/css text/xml application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;

              location ~* \.(?:css|js|jpg|jpeg|gif|png|ico|svg|woff|woff2|ttf|eot)$ {
                  expires 1y;
                  add_header Cache-Control "public, no-transform, immutable";
              }

              location / {
                  try_files $uri $uri/ /index.html;
              }

              location /api/ {
                  proxy_pass http://{{ include "tpl.resource.siblingName" (merge (dict "name" "backend") $) }}:8080;
              }

              location /healthz {
                  access_log off;
                  return 200 "OK\n";
              }
          }
```

When onboarding, ask whether the application reads a configuration file; a missing one shows
up as a crash loop, not a failed build. Signals: `nginx.conf` or `default.conf` (SPA),
`application.properties`/`.yml` and `logback.xml` (Java), `appsettings.json` (.NET),
`gunicorn.conf.py`, `uwsgi.ini`, `logging.conf` (Python), `ecosystem.config.js` or
`config/*.json` (Node), and `*.pem`, `*.crt`, `*.key`, `my.cnf`, `redis.conf` anywhere. A
Dockerfile that `COPY`s such a file is the thing to migrate.

| Anti-pattern | Why it fails |
| --- | --- |
| `COPY nginx.conf` in the Dockerfile | cannot vary per environment; a config change needs a new image |
| A hand-written ConfigMap in `templates/` | duplicates what the library generates |
| A credential in `mounts.configmap` | readable by anyone with namespace read |
| A hard-coded port or sibling host in file content | disagrees with `values.yaml` once either changes |
| One file mixing routing and credentials | forces the whole file into a Secret |
| `data:` on a Secret with plain text | `data` expects base64; use `stringData` |

## Routes

- **Host.** `routes.<r>.hosts`, else `routes.<r>.host`, else
  `<component>.<global.routes.domain>`. The fallback ignores `subComponent`, so a second
  release that needs its own host — another mode of the same chart — sets `host` explicitly.
- **The domain key is `global.routes.domain`.** A misspelled key such as `global.route.domain`
  renders an empty host without an error.
- **Paths.** One path entry with a named `port` renders an Ingress `Prefix` path and an HTTPRoute
  `PathPrefix` match. Components that share a host split it by path.
- **Gateway.** The HTTPRoute `parentRefs` default to `global.routes.gateway`
  (`default-gateway` in `gateway-system`), a placeholder; name the cluster's gateway.

```yaml
routes:
  default:
    host: "{{ .Values.component }}.{{ .Values.global.routes.domain }}"
    paths:
      - name: api
        matches:
          - path:
              type: PathPrefix
              value: /
        port: http
```

## Rendering behaviour

- **Container ports come from `service.*.spec.ports`**; the library default `ports: []` leaves
  routes and named-port probes pointing at nothing. Every port a route or probe names must be
  declared there.
- **`service: ~` removes every Service** and the derived container ports — right for a worker.
  Turn its routes off as well: they still render, pointing at a Service that no longer exists.
- **`configmapEnvs` entries with an empty value are dropped**, so an application reading one
  must default it (`${VAR:-}`). The block and each value are rendered through `tpl`, so a
  templated URL in a value renders.
- **`terminationGracePeriodSeconds` is not rendered**; pods get the Kubernetes default of 30 s.

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
- **Everywhere a credential appears**: the rule holds for every container, init container, job
  and cronjob, in `values.yaml` and in every overlay. A credential never goes in an `env`
  value or in `args` either — both are visible in the pod spec. A templated reference is still
  a secret; this is a password in a ConfigMap and belongs in `secretEnvs`:

  ```yaml
  configmapEnvs: |
    REDIS_URL: redis://{{ .Values.redis.auth.username }}:{{ .Values.redis.auth.password }}@redis:6379
  ```

- **Domain Grouping in `values.yaml`**:
  - **Database**: All database connection parameters must be grouped under `.Values.database` (e.g., `database.postgresql.host`, `port`, `database`, `ssl`, `auth.username`, `auth.password`).
  - **Storage**: All Object Storage / S3 configurations must be grouped under `.Values.storage` (e.g., `storage.bucketName`, `region`, `endpoint`, `baseUrl`, `rootPath`, `accessKey`, `secretKey`).
  - **Secrets**: Application secrets must be declared under `.Values.secrets` (e.g., `appSecret`, `jwtSecret`, `apiTokenSalt`).
- **Credentials sit under an `auth:` sub-map** of their domain group (`database.postgresql.auth`,
  `smtp.auth`), so everything under `auth:` is a `secretEnvs` candidate and everything beside
  it is not. The authenticating account is not the display value: `smtp.auth.username` is the
  mailbox that logs in, `smtp.from` the envelope sender — deriving one from the other breaks as
  soon as a relay account differs from the sender.
- **Classify by value, not by key name.** A URL that carries `user:password@` before its host
  is a credential whatever its key; long random-looking strings are keys even in a field called
  `id`; `changeme` or `admin` shipped to an environment is a credential, not a placeholder; a
  genuinely public value in the Secret only obscures which values matter.

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

A consumer schema keeps the library's definitions for the workload keys and states the
decisions only the chart makes:

- Workload keys point at the library `$defs`, so a library upgrade carries over.
- The chart's own choices are explicit: an enum for `mode` and `subComponent` listing every
  value `values.yaml`, the overlays and the environments use, with no empty entry; `required`
  for application blocks that must be set.
- An optional feature's properties exist only when the chart uses the feature.
- Never put `minLength` on a key whose `values.yaml` default is `""`: `helm lint --strict`
  runs on the defaults, so every pipeline fails. That includes an `image.repository` left
  empty for the library to derive.

## Security posture

What the rendered manifest grants, reviewed for its blast radius:

- **`hostPath` mounts** are suspect; `/`, `/var/run/docker.sock`, `/etc` or `/proc` is a
  container escape.
- **`privileged: true`, `hostNetwork`, `hostPID`, `hostIPC`** only for demonstrable
  infrastructure (a CNI agent, a node exporter), with the reason written down.
- **Added capabilities** — `NET_ADMIN`, `SYS_ADMIN` (effectively root), `SYS_PTRACE` — are
  justified or dropped.
- **`allowPrivilegeEscalation`** unset or true, or no `readOnlyRootFilesystem`, on a workload
  that never writes to its own filesystem.
- **`pod.securityContext` is never empty**: chart scanners reject an empty one.
- **ServiceAccount scope**: no `*` verbs on `*` resources, and no cluster-wide binding where a
  namespaced Role does. `Role` and `RoleBinding` need configuration beyond including a template.
- **Resource limits** are set; one unlimited pod can starve a shared node.
- **Routes** expose only what is meant to be public; a worker or internal API with a public
  host is usually a mistake.

[Documentation index](../README.md)
