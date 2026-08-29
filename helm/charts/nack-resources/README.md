# Helm chart - NATS JetStream Controller (NACK) Resources

Helm chart for managing NATS JetStream resources (Streams, Consumers, KeyValues, ObjectStores) managed by the NACK controllers.

You must install the [NACK controllers](https://github.com/nats-io/nack) first to let this chart renders the custom resources (CRs). 

### Install

Provide connection settings and one or more resources:

```
helm install my-resources ./helm/charts/nack-resources \
  --namespace default \
  -f values.yaml
```

Upgrade:

```
helm upgrade my-resources ./helm/charts/nack-resources -f values.yaml
```

Uninstall:

```
helm uninstall my-resources
```

### Values overview

- `nats`: shared connectivity used by all resources unless overridden per-item (`connection`).
  - `servers`, `jsDomain`, `account`, `creds`, `nkey`, `tls{}`
- `preflight.crdChecks.enabled`: fail early if required CRDs are missing (default: `true`).
- `streams[]`: list of Stream specs. Minimal fields: `name`, `subjects`.
- `consumers[]`: list of Consumer specs. Minimal fields: `streamName`, `durableName`.
- `objectStores[]`: list of Object Store specs. Minimal field: `bucket`.
- `keyValues[]`: list of Key/Value Store specs. Minimal field: `bucket`.

See `values.yaml` for all available fields and descriptions (mirrors the NACK CRD schemas).

### Quick examples

Minimal Stream:

```
streams:
  - name: orders
    subjects: ["orders.*"]
```

Pull Consumer for the stream above:

```
consumers:
  - streamName: orders
    durableName: orders-pull
    ackPolicy: explicit
```

Key/Value bucket:

```
keyValues:
  - bucket: app-config
    history: 5
    storage: memory
```

Object Store bucket:

```
objectStores:
  - bucket: media
    storage: file
    replicas: 1
```
