# Usage

```console
helm registry login registry-1.docker.io --username registry-username --password-stdin
```

On Docker Hub, the push target is the Grootan namespace root. Helm appends the
chart name, so `tpl-library` is published at
`oci://registry-1.docker.io/grootantech/tpl-library`; candidate and release
versions use the same repository.

```yaml
dependencies:
  - name: tpl-library
    version: 1.2.0
    repository: oci://registry-1.docker.io/grootantech
```

Check [values.yaml](../values.yaml), the [values reference](values/README.md) and
[template entrypoints](templates.md) for examples and usage of Kubernetes objects.

[Documentation index](../README.md)
