# NATS Streaming (STAN)

NATS Streaming is an extremely performant, lightweight reliable streaming platform built on [NATS](https://nats.io).

## TL;DR;

```console
helm repo add nats https://nats-io.github.io/k8s/helm/charts/
helm install my-nats nats/nats
helm install my-stan nats/stan --set stan.nats.url=nats://my-nats:4222

kubectl exec -n default -it my-nats-box -- /bin/sh -l
my-nats-box:~# stan-sub -c my-stan -s my-nats foo
Connected to my-nats clusterID: [my-stan] clientID: [stan-sub]
Listening on [foo], clientID=[stan-sub], qgroup=[] durable=[]
```

## Basic Configuration

### NATS URL

A NATS Streaming server **requires a connection to a NATS Server**, you
can set it as follows:

```
stan:
  nats:
    url: "nats://my-nats:4222"
```

### Server Image

```yaml
stan:
  image: nats-streaming:0.17.0
  pullPolicy: IfNotPresent
```

### Custom Cluster ID

By default the cluster ID will be the same as the release of the
NATS Streaming cluster, but you can set a custom one as follows:

```console
stan:
  clusterID: my-cluster-name
```

This means that in order to connect, 

### Logging

*NOTE*: It is recommended to not enable debug/trace logging in production.

```console
stan:
  logging:
    debug: true
    trace: true
```



## Storage Configuration

Storage can be set to be either "file", "sql" or "memory".  By
default "file" storage is used using a persistent volume.

### File storage

```yaml
store:
  type: file 
```

#### Fault Tolerance mode

In case of using a shared volume that supports a `readwritemany`,
you can enable fault tolerance as follows.

```yaml
store:
  type: file

  # 
  # Fault tolerance group
  # 
  ft:
    group: 

  # 
  # File storage settings.
  # 
  file:
    path: /data/stan/store
    storageSize: 1Gi
```

#### Clustered File Storage

In case of using file storage, this sets up a 3 node cluster,
each with its own backed persistence volume.

```yaml
store:
  cluster:
    enabled: true
    logPath: /data/stan/log
```

### SQL Storage

```yaml
store:
  sql:
    driver: postgres

    # For example:
    # 
    # source: "dbname=postgres user=postgres password=stan host=stan-db sslmode=disable"
    # 
    source: ""

    # Initialize the database
    initdb:
      enabled: true

      # Client to use to init the db.
      image: postgres:11

    dbName: postgres
    dbUser: postgres
    dbPassword: stan
    dbHost: ""
    dbPort: 5432
```

## Misc

### Prometheus Exporter sidecar 

You can toggle whether to start the sidecar that can be used to feed metrics to Prometheus:

```yaml
exporter:
  enabled: true
  image: synadia/prometheus-nats-exporter:0.5.0
  pullPolicy: IfNotPresent
```

### Pod Customizations

#### Security Context

Toggle whether to use setup a Pod Security Context:

https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

```yaml
securityContext:
  fsGroup: 1000
  runAsUser: 1000
  runAsNonRoot: true       
```

#### Affinity

<https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity>

Match expresstion must be configured according to your setup

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: node.kubernetes.io/purpose
              operator: In
              values:
                - stan
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app
              operator: In
              values:
                - nats
                - stan
        topologyKey: "kubernetes.io/hostname"
```
