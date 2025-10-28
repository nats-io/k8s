# nats-kafka

## TL;DR;

```
helm install -f my-values.yaml nats-s3 oci://ghcr.io/ashupednekar/charts/nats-s3
```

## ⚙️ Configuration Overview

The following example configurations can be set with `-f`.

**Basic**

```yaml
nameOverride: ""
fullnameOverride: ""
namespaceOverride: ""
replicaCount: 1

image:
  repository: ghcr.io/wpnpeiris/nats-s3
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: NodePort
  port: 5222
  targetPort: 5222
  nodePort: 30222  # Uncomment if using NodePort

nats:
  servers: "nats://nats:4222"

auth:
  # Enable authentication (disabled by default)
  enabled: true
  
  # Use existing secret (takes precedence if set)
  existingSecret: ""
  
  # Username/Password authentication
  username: "natsadmin"
  password: "natsadmin"
```

> Note: these username password values are subject to change in the future

The chart is designed to make NATS S3 easily configurable through `values.yaml`.  
Key configurable sections include:

#### **General**
- **`nameOverride` / `fullnameOverride` / `namespaceOverride`** — Customize resource names and namespaces.
- **`replicaCount`** — Number of NATS S3 pod replicas to deploy.

#### **Image**
- **`image.repository`** — Container image to use (default: `ghcr.io/wpnpeiris/nats-s3`).
- **`image.tag`** — Image tag (default: `latest`).
- **`image.pullPolicy`** — Kubernetes pull policy (`IfNotPresent`, `Always`, etc.).

#### **Service**
- **`service.type`** — Kubernetes service type (`ClusterIP`, `NodePort`, etc.).
- **`service.port` / `service.targetPort`** — Define the external and internal ports for NATS S3.
- **`service.nodePort`** — Optional NodePort override (used if type is `NodePort`).

#### **NATS Connection**
- **`nats.servers`** — Comma-separated list of NATS server URLs, e.g. `nats://nats:4222`.

#### **Authentication**
- **`auth.enabled`** — Enables username/password authentication.
- **`auth.username` / `auth.password`** — Basic credentials for S3 access (used if `auth.enabled` is true).
- **`auth.existingSecret`** — Optionally reference an existing Kubernetes Secret containing credentials.  
  When set, this overrides inline username/password values.

---

### 🚀 Example Usage

```bash
helm repo add nats https://nats-io.github.io/k8s/helm/charts/
helm install my-nats-s3 nats/nats-s3 -f my-values.yaml
```

Example `my-values.yaml`:

```yaml
nats:
  servers: "nats://nats:4222"

auth:
  enabled: true
  username: "natsadmin"
  password: "natsadmin"
```

---

### Usage


### Note
> The optional dependency for s3 in the nats chart is currently an oci dependency pointing to my ghcr artifact, can be changed to file once/if merged

Right now, we need to cd into the nats chart and build the dependencies to pull in the s3 chart

```bash
helm/charts/nats on  feat_s3 !? macbook
❯ helm dependency update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "nats" chart repository
Update Complete. ⎈Happy Helming!⎈
Error: could not retrieve list of tags for repository oci://ghcr.io/ashupe
dnekar/charts/nats-s3: GET "https://ghcr.io/v2/ashupednekar/charts/nats-s3
/nats-s3/tags/list": response status code 404: name unknown: repository na
me not known to registry
helm/charts/nats on  feat_s3 !? macbook
❯ helm dependency update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "nats" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 1 charts
Downloading nats-s3 from repo oci://ghcr.io/ashupednekar/charts
Pulled: ghcr.io/ashupednekar/charts/nats-s3:0.1.0
Digest: sha256:95b396a38241a050b20e589ecf87d6fb274bec0496d05fd9542e2af60a9
063b4
Deleting outdated charts
```

The chart can then be installed by enabling the `s3.enabled=true` value. 

```bash
❯ helm install nats . -f ~/Documents/nats.yaml --set s3.enabled=true
NAME: nats
LAST DEPLOYED: Tue Oct 28 11:03:37 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
helm/charts/nats on  feat_s3 !? macbook
❯ k get po   
NAME                        READY   STATUS    RESTARTS      AGE
nats-0                      1/1     Running   0             21s
nats-1                      1/1     Running   0             21s
nats-2                      1/1     Running   0             21s
nats-box-789cd4555d-9w2n2   1/1     Running   0             21s
nats-s3-84bb45c49b-x27gr    1/1     Running   2 (19s ago)   21s
pgo-85767cc986-d64p7        1/1     Running   1 (4d ago)    9d
helm/charts/nats on  feat_s3 !? macbook
❯ 
```
