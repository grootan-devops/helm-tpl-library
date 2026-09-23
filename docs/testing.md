# Testing

`tpl-library` is a library chart, so it cannot be rendered on its own. `test` is a
mock consumer chart that depends on this library through `file://..` and calls every
`tpl.*` entrypoint; [helm-unittest](https://github.com/helm-unittest/helm-unittest) then
asserts the rendered output for both the default values and each override scenario.

```console
make test     # helm dependency update + helm unittest test
make lint     # strict Helm lint of the mock chart
make template # render the mock chart and check for errors
make verify   # documentation drift, lint, rendering and unit tests
helm template contoso test -f test/values/full.yaml # inspect a full render
```

- `test/values/` is the scenario matrix: `full.yaml` is a verbatim copy of
  `example.yaml`, and the rest are focused override layers (routes, mounts, env
  precedence, sibling references, autoscaling, job/cronjob, naming edges).
- `test/tests/` holds one suite per library template, each pairing a default
  case with an override case.
- `test/tests/e2e_full_test.yaml` snapshots the whole render for the defaults and for
  `example.yaml`, one snapshot per entrypoint template, committed under
  `test/tests/__snapshot__/`. After an intentional template change run `helm unittest --update-snapshot test` and
  review the snapshot diff.
- `test/tests/known_defects_test.yaml` pins behaviour that is currently wrong, with the fix
  noted inline. Those cases turn red on purpose once a bug is fixed — convert them into
  passing cases then.

Whenever `values.yaml` or `example.yaml` changes, refresh `test/values.yaml`
(the baseline copy of `values.yaml`) and `test/values/full.yaml` (the copy of
`example.yaml`) alongside it.

## Testing a consumer chart — what to cover, and what not to

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
| --- | --- |
| **Rendered names** for this chart's `component` / `subComponent` / `global.partOf` | The helper is tested here; whether *your* values produce `order-backend-main` is yours |
| **Token rendering** — a templated token inside a value resolves | `tpl` evaluation is the library's, but which values carry a token, and to what, is the chart's |
| **Auto defaults, and that an override overrides** | A default that silently wins over a set value is the failure this catches; the pairing is chart-specific |
| **Sibling references** resolve to the services this chart actually talks to | `tpl.resource.siblingName` is tested here; that your `cart.internalUrl` points at the cart service is not |
| **Schema** — `values.schema.json` rejects the mistakes this chart's values invite | The shape is the chart's own |

A useful shape is one scenario file per decision the chart makes, mirroring `test/values/`
above: defaults, then one override layer per behaviour, each asserting only the keys that
layer changes.

[Documentation index](../README.md)
