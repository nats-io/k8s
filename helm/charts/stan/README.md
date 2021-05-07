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

### Connecting to NATS Server

A NATS Streaming server **requires a connection to a NATS Server**.
There are few ways to configure connection to NATS:

#### Without credentials

```yaml
stan:
  nats:
    url: "nats://my-nats:4222"
```

#### Authenticate using NatsServiceRole

When using NATS Operator you can configure NATS Service Roles to
generate credentials for your clients in NATS config.
https://github.com/nats-io/nats-operator#using-serviceaccounts
This will create ServiceAccount and NatsServiceRole and enable
authentication using "bound-token":

```yaml
stan:
  nats:
    url: "my-nats.nats-namespace:4222" # Do not pass here `nats://` prefix
    serviceRoleAuth:
      enabled: "true"
      natsClusterName: my-nats # Name of NATS cluster created by NATS Operator
```

#### Authenticate with a 'credentials' file

In case of a secured NATS server the NATS Streaming server will need to
connect to the server using user credentials. These user credentials are
managed using the ```nsc``` tool and can be passed to the NATS Streaming
server using "credentials"

```yaml
stan:
  credentials:
    secret:
      name: nats-sys-creds
      key: sys.creds
```

#### With TLS

This will cause STAN  to connect to NATS using TLS, given a
secret containing the ca.crt, tls.crt, and tls.key.

```yaml
  tls:
    enabled: true
    # the secret containing the client ca.crt, tls.crt, and tls.key for STAN
    secretName: "stan-client-tls"
    # Reference
    # https://docs.nats.io/nats-streaming-server/configuring/cfgfile#tls-configuration
    settings:
      client_cert: "/etc/nats/certs/tls.crt"
      client_key: "/etc/nats/certs/tls.key"
      client_ca: "/etc/nats/certs/ca.crt"
      timeout: 3
```

If you're using the [NATS Operator and cert-manager](https://github.com/nats-io/nats-operator#cert-manager), you
can provision a certificate for STAN like this:

```yaml
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: stan-client-tls
spec:
  secretName: stan-client-tls
  duration: 2160h # 90 days
  renewBefore: 240h # 10 days
  usages:
  - signing
  - key encipherment
  - server auth
  issuerRef:
    name: nats-ca
    kind: Issuer
  organization:
  - Your organization
  commonName: stan.default.svc.cluster.local
  dnsNames:
  - stan.default.svc
```

### Number of replicas

In case of using fault tolerance mode, you can set the number of replicas
to be used in the FT group.

```yaml
stan:
  replicas: 2
```

Note: in case of using clustering, you must set the number of replicas to 3 or more.

```yaml
stan:
  replicas: 3
store:
  cluster:
    enabled: true
```

### Server Image

```yaml
stan:
  image: nats-streaming:0.18.0
  pullPolicy: IfNotPresent
```

For the alpine image:

```yaml
stan:
  image: nats-streaming:alpine
```

### Custom Cluster ID

By default the cluster ID will be the same as the release of the
NATS Streaming cluster, but you can set a custom one as follows:

```yaml
stan:
  clusterID: my-cluster-name
```

This means that in order to connect,

### Logging

*NOTE*: It is recommended to not enable debug/trace logging in production.

```yaml
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
you can enable fault tolerance as follows.  More info on how to
set this up can be found [here](https://docs.nats.io/nats-on-kubernetes/stan-ft-k8s-aws)

```yaml
stan:
  replicas: 2 # One replica will be active, other one in standby.
  nats:
    url: "nats://nats:4222"

store:
  type: file

  #
  # Fault tolerance group
  #
  ft:
    group: my-group

  #
  # File storage settings.
  #
  file:
    path: /data/stan/store

  # Volume for EFS
  volume:
    enabled: true

    # Mount path for the volume.
    mount: /data/stan

    # FT mode requires a single shared ReadWriteMany PVC volume.
    persistentVolumeClaim:
      claimName: stan-efs
```

Where the persistent volume claim is something like the following for example (using `ReadWriteMany`):

```yaml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: stan-efs
  annotations:
    volume.beta.kubernetes.io/storage-class: "aws-efs"
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Mi
```

#### Partitioning

You can enable partitioning as follows:

```
store:
  type: file

  partitioning:
    enabled: true
```

For example to have two partitions under the same NATS/NATS Streaming
cluster named `stan` with two Fault Tolerant groups managing different
channels under the same shared filesystem.

```yaml
# 
stan:
  image: nats-streaming:alpine
  replicas: 2
  clusterID: stan

store:
  type: file
  ft:
    group: A
  file:
    path: /data/stan/store/A

  partitioning:
    enabled: true

  limits:
    channels:
      foo.>:

  volume:
    enabled: true

    # Mount path for the volume.
    mount: /data/stan

    # FT mode requires a single shared ReadWriteMany PVC volume.
    persistentVolumeClaim:
      claimName: stan-efs
```

```yaml
stan:
  image: nats-streaming:alpine
  replicas: 2
  clusterID: stan

store:
  type: file
  ft:
    group: B
  file:
    path: /data/stan/store/B

  partitioning:
    enabled: true

  limits:
    channels:
      bar.>:

  volume:
    enabled: true

    # Mount path for the volume.
    mount: /data/stan

    # FT mode requires a single shared ReadWriteMany PVC volume.
    persistentVolumeClaim:
      claimName: stan-efs
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

Example that will use a volume claim for each pod:

```yaml
stan:
  image: nats-streaming:alpine
  replicas: 3 # At least 3 required.
  nats:
    url: "nats://nats:4222"

store:
  type: file

  cluster:
    enabled: true

  #
  # File storage settings.
  #
  file:
    path: /data/stan/store

  # Volume for each pod.
  volume:
    enabled: true

    # Mount path for the volume.
    mount: /data/stan
```

Example that will back up the file store when operating in clustered mode:

```yaml
stan:
  image: nats-streaming:0.18.0-alpine
store:
  limits:
    max_msgs: 5

  file:
    options:
      slice_max_msgs: 0

  backup:
    enabled: true
    s3Path: s3://example-bucket/stan-backups

    # Create a secret called `aws-creds` with the 3 keys:
    # awsAccessKeyId
    # awsSecretKeyId
    # awsDefaultRegion
    credentialsSecretName: aws-creds
```

Alternatively, instead of creating a secret, you can provide an instance profile instead:

```yaml
podAnnotations:
  # Configures a role with this name to be assumed by the pods.
  iam.amazonaws.com/role: "stan-backups"
```

##### Example of a STAN cluster with file storage with embedded NATS

This will create a 3-node STAN cluster that is also a NATS cluster,
so no extra NATS Server deployment is required:

```yaml
stan:
  image: nats-streaming:alpine
  replicas: 3

store:
  type: file

  cluster:
    enabled: true

  #
  # File storage settings.
  #
  file:
    path: /data/stan/store

  # Volume for each pod.
  volume:
    enabled: true

    # Mount path for the volume.
    mount: /data/stan
```

```sh
$ kubectl get pods
NAME             READY   STATUS    RESTARTS   AGE
stan-cluster-0   3/3     Running   0          52m
stan-cluster-1   3/3     Running   0          52m
stan-cluster-2   3/3     Running   0          53m

$ kubectl run -i --rm --tty nats-box --image=synadia/nats-box --restart=Never

nats-box:~# stan-pub -c stan-cluster -s stan-cluster foo hello
Published [foo] : 'hello'

nats-box:~# stan-sub -c stan-cluster -s stan-cluster -all foo
Connected to stan-cluster clusterID: [stan-cluster] clientID: [stan-sub]
Listening on [foo], clientID=[stan-sub], qgroup=[] durable=[]
[#1] Received: sequence:1 subject:"foo" data:"bar" timestamp:1602316504474885089 
```

#### Readiness Probe for clustering

In case of using an nats-streaming alpine image, the `clusterReadinessProbe` can be enabled to try to ensure that during server upgrades the pods in the statefulsets in the pod are restarted one by one until there is consensus in the quorum.

```yaml
clusterReadinessProbe:
  enabled: true
  # probe: <-- can add custom readinessProbe parameters here.

stan:
  image: nats-streaming:alpine
  replicas: 3
  nats:
    url: "nats://my-nats:4222"

store:
  type: file

  cluster:
    enabled: true

  #
  # File storage settings.
  #
  file:
    path: /data/stan/store

  # Volume for each pod.
  volume:
    enabled: true

    # Mount path for the volume.
    mount: /data/stan
```

### SQL Storage

```yaml
store:
  sql:
    driver: postgres

    # "source" is used at runtime by NATS Streaming. For example:
    #
    # source: "dbname=postgres user=postgres password=stan host=stan-db sslmode=disable"
    #
    source: ""

    # Initialize the database. Only Postgres is supported.
    initdb:
      enabled: true

      # Client to use to init the db.
      image: postgres:11

    # SQL connection parameters used to run the initdb script:
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

### Prometheus operator ServiceMonitor support

You can enable prometheus operator ServiceMonitor:

```yaml
exporter:
  # You have to enable exporter first
  enabled: true
  serviceMonitor:
    enabled: true
    ## Specify the namespace where Prometheus Operator is running
    # namespace: monitoring
    # ...
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

`matchExpressions` must be configured according to your setup

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

### Name Overides

Can change the name of the resources as needed with:

```yaml
nameOverride: "my-stan"
```

### Authorization example

```yaml
cluster:
  enabled: false

store:
  cluster:
    enabled: false
  file:
    options:
      sync: true

stan:
  logging:
    debug: true
    trace: true
   
  auth:
    enabled: true
    username: stan
    password: stan

nats:
  logging:
    debug: true
    trace: true

auth:
  enabled: true
  systemAccount: SYS

  basic:
    accounts: 
      STAN:
        imports: []
        exports: []
        users:
        - user: stan
          pass: stan
      ACME:
        imports: []
        exports: []
        users:
        - user: acme
          pass: acme
      SYS:
        imports: []
        exports: []
        users:
        - user: sys
          pass: sys
```
