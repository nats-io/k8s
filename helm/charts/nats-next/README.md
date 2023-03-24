# nats-next

Experimental composable Helm chart for NATS.

The chart has very few explicit values defined.  Everything in the NATS Config or Kubernetes Resources can be overridden by merging or patching.

- Merges are performed using the Helm `mergeOverwrite` function
- Patches are performed using [JSON Patch](https://jsonpatch.com/)

## NATS Config

**Merge** - add accounts

```yaml
config:
  merge:
    accounts:
      A:
        users:
        - {user: a, password: a}
      B: 
        users:
        - {user: b, password: b}
```

**Patch** - remove http monitoring

```yaml
config:
  patch:
  - op: remove
    path: /http
```


## NATS Container

**Merge** - add resources

```yaml
nats:
  merge:
    resources:
      requests:
        memory: 8Gi
        cpu: "2"
      limits:
        memory: 16Gi
        cpu: "4"
```

**Patch** - add a wss port

```yaml
nats:
  patch:
  - op: add
    path: /ports/-
    value:
      containerPort: 443
      name: wss
```

# PodTemplate

**Merge** - add an annotation and a security context

```yaml
podTemplate:
  merge:
    metadata:
      annotations:
        nats/is: awesome
    spec:
      securityContext:
        runAsUser: 1000
```

**Patch** - add a volume

```yaml
podTemplate:
  patch:
  - op: add
    path: /spec/volumes/-
    value:
      name: tls
      secret:
        secretName: my-tls-cert
```
