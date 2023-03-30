# nats-next

Experimental composable Helm chart for NATS.

The chart has very few explicit values defined.  Everything in the NATS Config or Kubernetes Resources can be overridden by merging or patching.

- Merges are performed using the Helm `mergeOverwrite` function
- Patches are performed using [JSON Patch](https://jsonpatch.com/)

Additionally, anything in `values.yaml` can be templated:

- maps matching the following syntax will be templated and parsed as YAML:
  ```yaml
  tplYaml: |
    yaml template
  ```
- maps matching the follow syntax will be templated, parsed as YAML, and spread into the parent map/slice
  ```yaml
  tplYamlSpread: |
    yaml template
  ```

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

**Template** - add cluster authorization

```yaml
statefulSet:
  replicas: 3

config:
  merge:
    cluster:
      authorization:
        user: foo
        password:
          tplYaml: >
            {{ printf "bar" | bcrypt }}
      routes:
      - tplYamlSpread: |
          {{ $name := include "nats.fullname" . }}
          {{- range $i, $_ := until ($.Values.statefulSet.replicas | int) }}
          - {{ printf "nats://foo:bar@%s-%d.%s-headless:6222" $name $i $name }}
          {{- end }}
```

templates to the `nats.conf`:

```json
{
  "cluster": {
    "authorization": {
      "password": "$2a$10$hC7z.u7LyEeBVcBsuZjmDege8Cf448JaNWHQGbpgrHv8WOSksQ8qy",
      "user": "foo"
    },
    "routes": [
      "nats://foo:bar@nats-0.nats-headless:6222",
      "nats://foo:bar@nats-1.nats-headless:6222",
      "nats://foo:bar@nats-2.nats-headless:6222"
    ]
  }
}
```

## NATS Container

**Merge** - increase resources

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

## PodTemplate

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
