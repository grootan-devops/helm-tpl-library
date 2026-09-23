# Chart standards

## Chart Metadata Standard (`Chart.yaml`)

Always use the standard metadata structure in consumer charts:

```yaml
apiVersion: v2
name: example-backend
version: 1.0.0
description: Application purpose and responsibilities
type: application
home: https://example.com
maintainers:
  - name: DevOps
    email: devops@contoso.com
dependencies:
  - name: tpl-library
    version: 1.2.0
    repository: oci://registry.contoso.com/helm
icon: https://example.com/logo.svg
appVersion: "1.0.0"
deprecated: false
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

[Documentation index](../README.md)
