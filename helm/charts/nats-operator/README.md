# NATS Operator Helm Chart

NATS is an open-source, cloud-native messaging system. Companies like Apcera,
Baidu, Siemens, VMware, HTC, and Ericsson rely on NATS for its highly performant
and resilient messaging capabilities.

## TL;DR

```bash
$ helm install .
```

## Introduction

NATS Operator manages [NATS](https://nats.io/) clusters atop
[Kubernetes](http://kubernetes.io), automating their creation and
administration. With the NATS Operator you can benefits from the flexibility
brought by the Kubernetes operator pattern. It means less juggling between
manifests and a few handy features like automatic configuration reload.

If you want to manage NATS entirely by yourself and have more control over your
NATS cluster, you can always use the original
[NATS](https://github.com/helm/charts/tree/master/stable/nats) Helm chart.

## Prerequisites

- Kubernetes 1.8+ (1.12 for some functionality)

## Installing the Chart

To install the chart with the release name `my-release`:

```bash
$ helm install --name my-release .
```

The command deploys NATS and the NATS Operator on the Kubernetes cluster in the
default configuration. The [configuration](#configuration) section lists the
parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

> **Tip**: If you want to RE-INSTALL the NATS Operator, please ensure you deleted `*.nats.io` custom resource definitions
> ```shell 
> $ kubectl delete crd/natsserviceroles.nats.io
> $ kubectl delete crd/natsclusters.nats.io   
> ```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
# Delete Helm release
$ helm delete my-release --purge

# Delete CRDs
$ kubectl delete crd/natsserviceroles.nats.io
$ kubectl delete crd/natsclusters.nats.io

```

The command removes all the Kubernetes components associated with the chart and
deletes the release.

## Configuration

The following table lists the configurable parameters of the NATS chart and
their default values.

| Parameter                            | Description                                                                                  | Default                                         |
| ------------------------------------ | -------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| `rbacEnabled`                                | Switch to enable/disable RBAC for this chart                                                 | `true`                                          |
| `clusterScoped`                              | Enable cluster scoped installation (read carefully the warnings)                             | `false`                                         |
| `image.registry`                             | NATS Operator image registry                                                                 | `docker.io`                                     |
| `image.repository`                           | NATS Operator image name                                                                     | `connecteverything/nats-operator`               |
| `image.tag`                                  | NATS Operator image tag                                                                      | `0.4.3-v1alpha2`                                |
| `image.pullPolicy`                           | Image pull policy                                                                            | `Always`                                        |
| `image.pullSecrets`                          | Specify image pull secrets                                                                   | `nil`                                           |
| `securityContext.enabled`                    | Enable security context                                                                      | `true`                                          |
| `securityContext.fsGroup`                    | Group ID for the container                                                                   | `1001`                                          |
| `securityContext.runAsUser`                  | User ID for the container                                                                    | `1001`                                          |
| `nodeSelector`                               | Node labels for pod assignment                                                               | `nil`                                           |
| `tolerations`                                | Toleration labels for pod assignment                                                         | `nil`                                           |
| `schedulerName`                              | Name of an alternate scheduler                                                               | `nil`                                           |
| `antiAffinity`                               | Anti-affinity for pod assignment (values: soft or hard)                                      | `soft`                                          |
| `podAnnotations`                             | Annotations to be added to pods                                                              | `{}`                                            |
| `podLabels`                                  | Additional labels to be added to pods                                                        | `{}`                                            |
| `updateStrategy`                             | Replicaset Update strategy                                                                   | `OnDelete`                                      |
| `rollingUpdatePartition`                     | Partition for Rolling Update strategy                                                        | `nil`                                           |
| `resources`                                  | CPU/Memory resource requests/limits                                                          | `{}`                                            |
| `livenessProbe.enabled`                      | Enable liveness probe                                                                        | `true`                                          |
| `livenessProbe.initialDelaySeconds`          | Delay before liveness probe is initiated                                                     | `30`                                            |
| `livenessProbe.periodSeconds`                | How often to perform the probe                                                               | `10`                                            |
| `livenessProbe.timeoutSeconds`               | When the probe times out                                                                     | `5`                                             |
| `livenessProbe.failureThreshold`             | Minimum consecutive failures for the probe to be considered failed after having succeeded.   | `6`                                             |
| `livenessProbe.successThreshold`             | Minimum consecutive successes for the probe to be considered successful after having failed. | `1`                                             |
| `readinessProbe.enabled`                     | Enable readiness probe                                                                       | `true`                                          |
| `readinessProbe.initialDelaySeconds`         | Delay before readiness probe is initiated                                                    | `5`                                             |
| `readinessProbe.periodSeconds`               | How often to perform the probe                                                               | `10`                                            |
| `readinessProbe.timeoutSeconds`              | When the probe times out                                                                     | `5`                                             |
| `readinessProbe.failureThreshold`            | Minimum consecutive failures for the probe to be considered failed after having succeeded.   | `6`                                             |
| `readinessProbe.successThreshold`            | Minimum consecutive successes for the probe to be considered successful after having failed. | `1`                                             |
| `cluster.create`                             | Create and deploy a NATS Cluster togheter with the operator                                  | `true`                                          |
| `cluster.name`                               | Name of NATS Cluster                                                                         | `nats-cluster`                                  |
| `cluster.namespace`                          | Namespace to deploy the NATS Cluster in, only possible if `clusterScoped` is set to `true`   | `nats-io`                                       |
| `cluster.version`                            | Version of NATS Cluster                                                                      | `1.4.1`                                         |
| `cluster.size`                               | Number of NATS Cluster nodes                                                                 | `3`                                             |
| `cluster.annotations`                        | Optional custom annotations to add to Pods in the cluster                                    | `{}`                                            |
| `cluster.resources`                          | Optional CPU/Memory resource requests/limits to set on Pods in the cluster                   | `{}`                                            |
| `cluster.auth.enabled`                       | Switch to enable/disable client authentication                                               | `true`                                          |
| `cluster.auth.enableServiceAccounts`         | Enable ServiceAccounts permissions                                                           | `false`                                         |
| `cluster.auth.username`                      | Client authentication username                                                               | `true`                                          |
| `cluster.auth.password`                      | Client authentication password                                                               | `true`                                          |
| `cluster.auth.users`                         | Allows multi-user authentication of 2 or more user                                           | `[]`                                            |
| `cluster.auth.defaultPermissions`            | Enable default permissions for users                                                         | `{}`                                            |
| `cluster.auth.defaultPermissions.publish`    | Default permission for publish requests                                                      | `nil`                                           |
| `cluster.auth.defaultPermissions.subscribe`  | Default permission for subscribe requests                                                    | `nil`                                           |
| `cluster.tls.enabled`                        | Enable TLS                                                                                   | `false`                                         |
| `cluster.tls.serverSecret`                   | Certificates to secure the NATS client connections (type: kubernetes.io/tls)                 | `nil`                                           |
| `cluster.tls.routesSecret`                   | Certificates to secure the routes. (type: kubernetes.io/tls)                                 | `nil`                                           |
| `cluster.configReload.enabled`               | Enable configuration reload                                                                  | `false`                                         |
| `cluster.configReload.registry`              | Reload configuration image registry                                                          | `docker.io`                                     |
| `cluster.configReload.repository`            | Reload configuration image name                                                              | `connecteverything/nats-server-config-reloader` |
| `cluster.configReload.tag`                   | Reload configuration image tag                                                               | `0.2.2-v1alpha2`                                |
| `cluster.configReload.pullPolicy`            | Reload configuration image pull policy                                                       | `IfNotPresent`                                  |
| `cluster.metrics.enabled`                    | Enable prometheus metrics exporter                                                           | `false`                                         |
| `cluster.metrics.registry`                   | Prometheus metrics exporter image registry                                                   | `docker.io`                                     |
| `cluster.metrics.repository`                 | Prometheus metrics exporter image name                                                       | `synadia/prometheus-nats-exporter`              |
| `cluster.metrics.tag`                        | Prometheus metrics exporter image tag                                                        | `0.1.0`                                         |
| `cluster.metrics.pullPolicy`                 | Prometheus metrics exporter image pull policy                                                | `IfNotPresent`                                  |

### Example

Here is an example of how to setup a NATS cluster with client authentication.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

```bash
$ helm install --name my-release --set cluster.auth.enabled=true,cluster.auth.username=my-user,cluster.auth.password=T0pS3cr3t .
```

You can also specify more than 1 user using this way:

```bash
$ helm install --name my-release --set cluster.auth.enabled=true,cluster.auth.users[0]=my-user,cluster.auth.users[0].password=T0pS3cr3t,cluster.auth.users[1]=my-user-2,cluster.auth.users[1].password=MyS3cr3tP4ssw0rd .
```
You can consider editing the default values.yaml as it is easier to manage:

```yaml
...
cluster:
  auth:
    enabled: true

    # username:
    # password:

    # values.yaml
    users:
      - username: "my-user"
        password: "T0pS3cr3t"
      - username: "my-user-2"
        password: "MyS3cr3tP4ssw0rd"
...
```

Alternatively, a YAML file that specifies the values for the parameters can be
provided while installing the chart. For example,

> **Tip**: You can use the default [values.yaml](values.yaml)

```bash
$ helm install --name my-release -f values.yaml .
```
