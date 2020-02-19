# NATS Streaming Statefulset Deployment

NATS Streaming is an extremely performant, lightweight reliable streaming
platform built on NATS.

## TL;DR

```bash
$ helm install .
```

## Prerequisites

- Kubernetes 1.15+
- HELM 2
- Postgres 11 with ssl enabled(if sql store)

## Installing the Chart

To install the chart with the release name `my-release`:

```bash
$ helm install --name my-release .
```
> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
$ helm delete --purge my-release
```

## Configuration

The following table lists the configurable parameters of the NATS chart and
their default values.

| Parameter | Description | Default |

| `stan.enableClustering` | Switch to enable/disable clustering | `true` |
| `stan.clusteringPort` | Port user for clustering | `6222` |
| `stan.clusteringID` | Cluster ID | `stan` |
| `stan.clusterIP` | Cluster's internal IP | `None` |
| `stan.clientPort` | Client communication port | `4222` |
| `stan.serviceName` | Service name used within k8s | `stan` |
| `stan.ftGroup` | Nats Streaming fault tolerant group name | `stan-cluster` |
| `stan.image` | Nats Streaming image | `nats-streaming` |
| `stan.image` | Nats Streaming image tag/version | `0.16.2` |
| `stan.store` | Nats Streaming persistent store type file/sql | `file` |
| `stan.webuiPort` | Nats Streaming web interface port | `8222` |
| `stan.replicaCount` | Amounts of pods/clusters/replicas | `3` |
| `stan.storageSize` | Filestore size | `50Gi` |
| `stan.istioEnabled` | Add annotation for skipping Istio envoy proxying | `false` |
| `stan.authToken` |  Require authentication token if defined | `s3cr3t` |
| `prometheus.imageName` | Prometheus exporter image name | `synadia/prometheus-nats-exporter` |
| `prometheus.imageName` | Prometheus exporter image tag/release | `0.6.0` |
| `prometheus.metricsPort` | Prometheus exporter port | `7777` |
| `stan_sql.dbName` | PSQL store database name | `postgres` |
| `stan_sql.dbUser` | PSQL store database user | `postgres` |
| `stan_sql.dbPassword` | PSQL store database password | `password1234` |
| `stan_sql.dbHost` | PSQL store database host ip/fqdn | `nats-db-postgresql.postgres.svc.cluster.local` |
| `stan_sql.source` | PSQL database source string | `dbname=postgres user=postgres password=password1234 host=nats-db-postgresql.postgres.svc.cluster.local` |
| `stan_sql.dbPort` | PSQL store database port | `5432` |
