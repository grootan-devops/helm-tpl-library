# mock-app

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.4.2](https://img.shields.io/badge/AppVersion-1.4.2-informational?style=flat-square)

Mock consumer chart used to render and assert the tpllib library templates.

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://.. | tpllib | 1.0.0 |

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
| component | string | `"shop"` | Overrides the name of the component. Used in labels and resource naming. |
| subComponent | string | `"api"` | Sub-component name override. |
| tpllib.component | string | `""` | Overrides the name of the component. Used in labels and resource naming. |
| tpllib.subComponent | string | `""` | Sub-component name override. |

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
| tpllib.replicas | int | `1` | Number of desired pods. |
| tpllib.revisionHistoryLimit | int | `0` | Revision history limit for the Deployment (keeps X old ReplicaSets). |
| tpllib.strategy | object | Check values.yaml | Strategy for replacing old pods with new ones. Ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy |
| tpllib.restartPolicy | string | `"Always"` | Restart policy for all containers in the pod. Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy |
| tpllib.serviceAccount.create | bool | `false` | Create ServiceAccount resource. Ref: https://kubernetes.io/docs/concepts/security/service-accounts/ |
| tpllib.serviceAccount.annotations | object | `{}` | ServiceAccount annotations. |
| tpllib.hostAliases | list | `[]` | HostAliases to inject into /etc/hosts. Ref: https://kubernetes.io/docs/tasks/network/customize-hosts-file-for-pods/ |
| tpllib.pod.annotations | object | `{}` | Annotations to add to the Pod metadata. |
| tpllib.pod.securityContext | object | Check values.yaml | Pod-level Security Context (applied to all containers). Ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |

### Container Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| initContainers | object | `{}` | Init Container configuration. |
| containers.main.name | string | `""` | Override the container name. Defaults to the map key (e.g., 'main') or component name. |
| containers.main.command | list | `[]` | Override container entrypoint (command). |
| containers.main.args | list | `[]` | Override container arguments. |
| containers.main.image.repository | string | `"acme/shop-api"` | Image repository. |
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
| tpllib.initContainers | object | `{}` | Init Container configuration. |
| tpllib.containers.main.name | string | `""` | Override the container name. Defaults to the map key (e.g., 'main') or component name. |
| tpllib.containers.main.command | list | `[]` | Override container entrypoint (command). |
| tpllib.containers.main.args | list | `[]` | Override container arguments. |
| tpllib.containers.main.image.repository | string | `""` | Image repository. |
| tpllib.containers.main.image.tag | string | `""` | Tag defaults to Chart.appVersion if left empty. |
| tpllib.containers.main.env | list | `[]` | Direct environment variables. High precedence. |
| tpllib.containers.main.securityContext | object | Check values.yaml | Security context for the container (Standard Non-Root). Ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| tpllib.containers.main.resources | object | `{}` | CPU/Memory resource requests and limits. Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ |
| tpllib.containers.main.resizePolicy | list | `[]` | Resize policy for CPU/Memory. Ref: https://kubernetes.io/docs/tasks/configure-pod-container/resize-container-resources/ |
| tpllib.containers.main.configmapEnvs | object | `{}` | ConfigMap-based environment variables. Templated string (Key: Value). |
| tpllib.containers.main.secretEnvs | object | `{}` | Secret-based environment variables. Templated string (Key: Value). |
| tpllib.containers.main.additionalConfigmapEnvs | object | `{}` | Extra mappings for ConfigMaps that need custom handling. |
| tpllib.containers.main.additionalSecretEnvs | object | `{}` | Extra mappings for Secrets that need custom handling. |
| tpllib.containers.main.extraConfigmapMounts | list | `[]` | List of existing ConfigMaps to inject as environment variables (envFrom). |
| tpllib.containers.main.extraSecretMounts | list | `[]` | List of existing Secrets to inject as environment variables (envFrom). |
| tpllib.containers.main.probes.enabled | bool | `true` | Enable probes. Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| tpllib.containers.main.probes.readiness | object | `{}` | Readiness probe configuration. Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| tpllib.containers.main.probes.liveness | object | `{}` | Liveness probe configuration. Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| tpllib.containers.main.probes.startup | object | `{}` | Startup probe configuration. Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |

### Scheduling Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| scheduling.topologySpreadConstraints | list | `[]` | Spread pods across failure domains (zones, nodes). Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/ |
| scheduling.nodeSelector | object | `{}` | Simple node selection constraints (Key: Value). Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| scheduling.tolerations | list | `[]` | Allow pods to schedule on tainted nodes. Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| scheduling.affinity | object | `{}` | Complex node/pod affinity rules. Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| tpllib.scheduling.topologySpreadConstraints | list | `[]` | Spread pods across failure domains (zones, nodes). Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/ |
| tpllib.scheduling.nodeSelector | object | `{}` | Simple node selection constraints (Key: Value). Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| tpllib.scheduling.tolerations | list | `[]` | Allow pods to schedule on tainted nodes. Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| tpllib.scheduling.affinity | object | `{}` | Complex node/pod affinity rules. Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |

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
| tpllib.service.default.annotations | object | `{}` | Service annotations. |
| tpllib.service.default.spec | object | `{"ports":[],"type":"ClusterIP"}` | Kubernetes Service specification. Ref: https://kubernetes.io/docs/concepts/services-networking/service/ |
| tpllib.routes.default.enabled | bool | `true` | Master switch to enable routing for this route definition. |
| tpllib.routes.default.ingress | bool | `true` | Render Kubernetes Ingress (networking.k8s.io/v1). |
| tpllib.routes.default.httpRoute | bool | `true` | Render Kubernetes Gateway API HTTPRoute (gateway.networking.k8s.io/v1). |
| tpllib.routes.default.host | string | `"{{ $.Values.component }}.{{ $.Values.global.routes.domain }}"` | Host header domain. Evaluated via tpl. |
| tpllib.routes.default.hosts | list | `[]` | Optional list of hostnames. Overrides host if specified. |
| tpllib.routes.default.ingressClass | string | `""` | Ingress class name for Ingress spec.ingressClassName. Defaults to global.routes.ingressClass. |
| tpllib.routes.default.tlsSecretName | string | `""` | Secret name for Ingress TLS termination. Defaults to global.routes.tlsSecretName. |
| tpllib.routes.default.gateway.name | string | `""` | Target Gateway name for HTTPRoute parentRefs. Defaults to global.routes.gateway.name. |
| tpllib.routes.default.gateway.namespace | string | `""` | Target Gateway namespace for HTTPRoute parentRefs. Defaults to global.routes.gateway.namespace. |
| tpllib.routes.default.gateway.class | string | `""` | Gateway class name. Defaults to global.routes.gateway.class. |
| tpllib.routes.default.parentRefs | list | `[]` | Custom parentRefs override for HTTPRoute. |
| tpllib.routes.default.annotations | object | `{}` | Annotations applied to both Ingress and HTTPRoute. |
| tpllib.routes.default.paths | list | `[]` | Path routing rules (compatible with both Ingress and HTTPRoute). Ref: https://gateway-api.sigs.k8s.io/reference/api-spec/main/spec/#httprouterule |
| tpllib.networkPolicy.enabled | bool | `false` | Enable NetworkPolicy. Ref: https://kubernetes.io/docs/concepts/services-networking/network-policies/ |
| tpllib.networkPolicy.ingressRule | list | `[]` | Ingress network rules. |
| tpllib.networkPolicy.egressRule | list | `[]` | Egress network rules. |

### Storage Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| mounts.secret | object | `{}` | Secret volume mounts. |
| mounts.configmap | object | `{}` | ConfigMap volume mounts. |
| mounts.emptyDir | object | `{}` | EmptyDir volume mounts. |
| mounts.pvc | object | `{}` | PersistentVolumeClaim mounts. |
| tpllib.mounts.secret | object | `{}` | Secret volume mounts. |
| tpllib.mounts.configmap | object | `{}` | ConfigMap volume mounts. |
| tpllib.mounts.emptyDir | object | `{}` | EmptyDir volume mounts. |
| tpllib.mounts.pvc | object | `{}` | PersistentVolumeClaim mounts. |

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
| tpllib.pdb.enabled | bool | `false` | Enable PodDisruptionBudget. Ref: https://kubernetes.io/docs/tasks/run-application/configure-pdb/ |
| tpllib.pdb.minAvailable | string | `""` | Minimum available pods. |
| tpllib.pdb.maxUnavailable | int | `2` | Maximum unavailable pods. |
| tpllib.autoscaling.enabled | bool | `false` | Enable HPA. Ref: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/ |
| tpllib.autoscaling.minReplicas | int | `1` | Minimum pod replicas. |
| tpllib.autoscaling.maxReplicas | int | `3` | Maximum pod replicas. |
| tpllib.autoscaling.metrics | list | `[]` | Resource metrics targets. |
| tpllib.autoscaling.scaleUp | object | `{}` | Scale up behavior policy. |
| tpllib.autoscaling.scaleDown | object | `{}` | Scale down behavior policy. |
| tpllib.metrics.jobLabel | string | `"app_kubernetes_io_instance"` | Job label for ServiceMonitor metrics. Ref: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/getting-started.md |
| tpllib.metrics.endpoints | list | `[]` | List of scrape endpoints. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| service.default | object | `{"annotations":{},"spec":{"ports":[],"type":"ClusterIP"}}` | Default service definition. |
| persistence | object | `{}` |  |
| testFixtures | object | `{"cronjob":false,"job":false,"monitors":false,"naming":false,"pvc":false,"rbac":false}` | Gates for the entrypoint templates so each suite renders only what it asserts. |
| jobs | object | `{}` | Job definitions consumed by templates/job.yaml. |
| cronjobs | object | `{}` | CronJob definitions consumed by templates/cronjob.yaml. |
| tpllib.service.default | object | `{"annotations":{},"spec":{"ports":[],"type":"ClusterIP"}}` | Default service definition. |
| tpllib.persistence | object | `{}` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
